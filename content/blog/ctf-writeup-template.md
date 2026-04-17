---
title: "Investigation Writeup: Suspected Credential Theft via LSASS Access"
date: 2025-04-10
draft: true
author: "Hugo Miranda"
summary: "A QRadar investigation into a suspected credential dumping attempt following an anomalous LSASS access alert on a finance workstation. Covers triage methodology, pivot technique, and resulting detection gaps closed."
tags: ["qradar", "sysmon", "credential-access", "windows", "investigation"]
categories: ["Incident Response"]
mitre_techniques: ["T1003.001", "T1078", "T1021.002"]
---

## Scenario

An analyst escalated a medium-severity QRadar offense titled *"Suspicious process access to lsass.exe"* on a finance department workstation (`WKST-FIN-047`). The offense correlated two Sysmon Event ID 10 (ProcessAccess) events within a 10-minute window, both with a `GrantedAccess` mask of `0x1010` — consistent with LSASS read operations used by credential dumping tools.

**Environment:**
- SIEM: IBM QRadar (Sysmon + WEF log pipeline)
- Endpoint: Windows 11, joined to `CORP` domain
- User: Finance analyst, standard privileges
- Time of alert: `2025-04-09T14:32:11Z`

---

## Initial Triage

**Offense summary from QRadar:**

```
Offense ID   : 00492
Magnitude    : 6
Source IP    : 10.20.5.47 (WKST-FIN-047)
Event count  : 2
Rule trigger : BB:CategoryDefinition-28 + Custom: LSASS Access High-Risk Mask
```

**First questions to answer:**

1. Which process accessed LSASS — is it a known tool or a renamed binary?
2. Was this access successful, or blocked by Credential Guard?
3. Is there any outbound network activity from this host in the same timeframe?
4. Are there other hosts with the same pattern in the last 24 hours?

**Initial AQL query to pull the raw events:**

```sql
SELECT
  LOGSOURCENAME(logsourceid) AS source,
  username,
  "sourceip",
  QIDNAME(qid) AS event_name,
  "SourceImage",
  "TargetImage",
  "GrantedAccess",
  "CallTrace",
  starttime
FROM events
WHERE
  logsourcetypename(devicetype) = 'Microsoft Sysmon'
  AND "TargetImage" ILIKE '%lsass.exe'
  AND starttime BETWEEN '2025-04-09 14:20:00' AND '2025-04-09 15:00:00'
ORDER BY starttime ASC
LAST 60 MINUTES
```

---

## Investigation

### Step 1 — Identify the accessing process

| Field | Value |
|---|---|
| SourceImage | `C:\Windows\Temp\svchost32.exe` |
| TargetImage | `C:\Windows\System32\lsass.exe` |
| GrantedAccess | `0x1010` |
| CallTrace | `C:\Windows\SYSTEM32\ntdll.dll+...` |

`svchost32.exe` in `C:\Windows\Temp` is immediately suspicious — legitimate svchost processes run from `System32` and are spawned by the SCM, not from Temp.

### Step 2 — Process lineage

Pull Sysmon Event ID 1 (ProcessCreate) for the suspicious binary:

```sql
SELECT "ParentImage", "ParentCommandLine", "Image", "CommandLine", "User", "Hashes"
FROM events
WHERE "Image" ILIKE '%svchost32.exe'
  AND LOGSOURCENAME(logsourceid) LIKE '%WKST-FIN-047%'
LAST 2 HOURS
```

**Result:** Parent process was `winword.exe` — the analyst had opened a macro-enabled spreadsheet ~8 minutes before the LSASS access.

### Step 3 — Lateral movement indicators

Query for SMB/RDP connections **from** the host in the same window:

```sql
SELECT destinationip, destinationport, "sourceip", username, starttime
FROM events
WHERE "sourceip" = '10.20.5.47'
  AND destinationport IN (445, 3389, 135, 5985)
  AND starttime > '2025-04-09T14:00:00Z'
LAST 4 HOURS
```

Two connections to `10.20.5.12` (DC01) on port 445 — 4 minutes after the LSASS access.

---

## Findings

| Finding | Severity | Detail |
|---|---|---|
| Renamed process mimicking svchost | High | `svchost32.exe` executed from `C:\Windows\Temp` |
| LSASS credential access | High | GrantedAccess `0x1010` consistent with Mimikatz/Pypykatz |
| Macro execution via Word | High | Parent-child chain: `winword.exe` → `svchost32.exe` |
| Lateral movement attempt | Medium | SMB connections to DC01 following credential access |
| No Credential Guard on this host | Informational | Access was not blocked |

**Verdict:** Confirmed post-exploitation activity. Incident escalated to P1.

---

## Detection Opportunities

Three gaps identified and addressed post-investigation:

**1. Process execution from Temp with svchost-like names**

Sysmon EID 1 rule — flag any process where `Image` contains `svchost` but does not originate from `%SystemRoot%\System32\`.

**2. Word spawning unusual child processes**

Existing Office child process detection did not cover renamed binaries. Updated rule to flag any `winword.exe` child where the child image is not on a known-good allowlist.

**3. LSASS access from non-system processes**

Added a tuned QRadar custom rule:
- Trigger: Sysmon EID 10, TargetImage = `*lsass.exe`, GrantedAccess in `{0x1010, 0x1410, 0x143a}`
- Exception: SourceImage in allowlist (AV, EDR, backup agents)

---

## Lessons Learned

- **Allowlists matter**: The original LSASS rule fired but was historically noise-heavy; the lack of tuning meant it had low analyst confidence. Prioritise false positive reduction before a real incident tests your process.
- **Process lineage is the fastest pivot**: Jumping straight to the parent chain saved ~20 minutes vs correlating by IP alone.
- **Credential Guard gap**: This workstation was not enrolled in Credential Guard policy. Post-incident remediation included pushing the policy to all finance workstations.
- **Detection template created**: Sigma rule for the renamed-svchost pattern has been committed to the detection repo and converted for QRadar, Elastic, and Sentinel.
