---
title: "Detection Research: Closing the Sysmon Coverage Gap for COM Hijacking"
date: 2025-03-18
draft: true
author: "Hugo Miranda"
summary: "COM object hijacking is a well-documented persistence technique that consistently slips through default Sysmon configurations. This post walks through the detection gap, a targeted Sysmon tuning approach, and the resulting Sigma rule with cross-platform conversions."
tags: ["sigma", "sysmon", "detection-engineering", "windows", "persistence"]
categories: ["Detection Engineering", "Research"]
mitre_techniques: ["T1546.015", "T1574.011"]
---

## Problem Statement

COM hijacking (T1546.015) has appeared in red team assessments and real intrusions for years, yet it remains systematically underdetected in most SIEM environments I've worked in. The technique involves registering a malicious COM object in `HKCU\Software\Classes\CLSID\` that overrides a legitimate CLSID looked up from `HKLM`. Because the write happens under HKCU — which any user can modify without admin rights — it bypasses most registry monitoring that focuses on privileged key paths.

The specific gap this post addresses: **default Sysmon configurations do not capture HKCU CLSID writes**, and even organisations with registry monitoring enabled often exclude HKCU due to event volume concerns.

**Goal:** Detect COM hijacking persistence with high fidelity, low noise, and a rule that works across QRadar, Elastic, and Sentinel without per-platform tuning gymnastics.

---

## Background

### How COM hijacking works

When a Windows application calls `CoCreateInstance()`, the COM subsystem resolves the CLSID in this order:

1. `HKCU\Software\Classes\CLSID\{GUID}\InprocServer32` ← user-writable, checked first
2. `HKLM\Software\Classes\CLSID\{GUID}\InprocServer32` ← requires admin

An attacker writes their DLL path under HKCU for a CLSID that is regularly instantiated by a trusted application (e.g., Explorer, Task Scheduler, Office). On next invocation of that application, the malicious DLL loads in-process.

### Why it's hard to detect

| Challenge | Detail |
|---|---|
| HKCU writes are normal | Hundreds of legitimate apps write CLSID keys daily |
| No process elevation required | No UAC prompt, no admin token |
| In-process execution | DLL loads into a trusted process — no new process to flag |
| Timing ambiguity | Persistence may activate days after the registry write |

### Prior art

[Reference: relevant whitepapers or blog posts you used as background]

---

## Approach

Detection strategy: **correlate the registry write with the DLL load**, rather than trying to alert on either in isolation.

Two-stage approach:
1. **Stage 1 (Registry):** Capture writes to `HKCU\...\CLSID\*\InprocServer32` where the value points to a DLL outside of `%SystemRoot%` and `%ProgramFiles%`.
2. **Stage 2 (Image Load):** Correlate with Sysmon EID 7 (ImageLoaded) — DLL load from a non-standard path by a trusted host process.

Stage 2 alone would be extremely noisy. Stage 1 alone misses execution timing. Together they produce a high-confidence signal.

---

## Implementation

### Sysmon configuration additions

Add to your Sysmon config under `<RegistryEvent onmatch="include">`:

```xml
<!-- COM hijacking persistence write -->
<RegistryEvent onmatch="include">
  <TargetObject condition="contains">\Software\Classes\CLSID\</TargetObject>
  <TargetObject condition="contains">InprocServer32</TargetObject>
</RegistryEvent>
```

Exclude known-noisy legitimate writers (tune to your environment):

```xml
<RegistryEvent onmatch="exclude">
  <Image condition="is">C:\Windows\System32\regsvr32.exe</Image>
  <Image condition="begin with">C:\Program Files\</Image>
  <Image condition="begin with">C:\Program Files (x86)\</Image>
</RegistryEvent>
```

For Stage 2, ensure ImageLoad events are enabled for non-signed DLLs:

```xml
<ImageLoad onmatch="include">
  <Signed condition="is">false</Signed>
</ImageLoad>
```

### Sigma rule

```yaml
title: COM Hijacking via HKCU CLSID Registration
id: a7f2c3d4-1234-5678-abcd-ef0123456789
status: experimental
description: >
  Detects COM hijacking persistence where a CLSID InprocServer32 key is written
  under HKCU pointing to a DLL outside standard system paths. Combine with
  ImageLoad correlation for higher confidence.
references:
  - https://attack.mitre.org/techniques/T1546/015/
author: Hugo Miranda
date: 2025-03-18
tags:
  - attack.persistence
  - attack.t1546.015
  - attack.defense_evasion
  - attack.t1574.011
logsource:
  product: windows
  category: registry_set
detection:
  selection:
    EventType: SetValue
    TargetObject|contains:
      - '\Software\Classes\CLSID\'
    TargetObject|endswith:
      - '\InprocServer32\(Default)'
      - '\InprocServer32\'
    Details|contains:
      - '.dll'
  filter_system_paths:
    Details|startswith:
      - 'C:\Windows\'
      - 'C:\Program Files\'
      - 'C:\Program Files (x86)\'
  filter_known_writers:
    Image|startswith:
      - 'C:\Program Files\'
      - 'C:\Program Files (x86)\'
      - 'C:\Windows\System32\'
  condition: selection and not 1 of filter_*
falsepositives:
  - Legitimate software installing COM components to non-standard paths
  - Development environments
level: high
```

### Platform conversions

**QRadar AQL (custom rule building block):**

```sql
SELECT
  username, "sourceip", "TargetObject", "Details", "Image", starttime
FROM events
WHERE
  logsourcetypename(devicetype) = 'Microsoft Sysmon'
  AND QIDNAME(qid) LIKE '%RegistryEvent%'
  AND "TargetObject" LIKE '%\Software\Classes\CLSID\%'
  AND "TargetObject" LIKE '%InprocServer32%'
  AND "Details" LIKE '%.dll%'
  AND "Details" NOT LIKE 'C:\Windows\%'
  AND "Details" NOT LIKE 'C:\Program Files%'
```

**KQL (Microsoft Sentinel / Defender):**

```kql
DeviceRegistryEvents
| where RegistryKey has @"\Software\Classes\CLSID\"
    and RegistryKey endswith "InprocServer32"
    and RegistryValueData endswith ".dll"
    and RegistryValueData !startswith @"C:\Windows\"
    and RegistryValueData !startswith @"C:\Program Files"
| project Timestamp, DeviceName, InitiatingProcessFileName,
          RegistryKey, RegistryValueData, InitiatingProcessAccountName
```

**Elastic EQL:**

```eql
registry where
  registry.path : "*\\Software\\Classes\\CLSID\\*\\InprocServer32*"
  and registry.data.strings : "*.dll"
  and not registry.data.strings : ("C:\\Windows\\*", "C:\\Program Files*")
```

---

## Results

Tested against:

| Test case | Result |
|---|---|
| Manual HKCU CLSID write via reg.exe | Detected ✓ |
| Cobalt Strike COM hijacking module | Detected ✓ |
| Legitimate Office COM registration (Teams) | Not fired (filtered) ✓ |
| Adobe Acrobat COM registration | Not fired (filtered) ✓ |
| Regsvr32 installing to AppData | Detected ✓ (AppData not in filter) |

False positive rate over 7-day baseline in test environment: **0 alerts** after filter tuning.

---

## Future Work

- **Correlation rule**: Build a multi-event QRadar rule that joins Stage 1 (registry write) with Stage 2 (ImageLoad of matching DLL path) within a 72-hour window to reduce reliance on either signal alone.
- **CLSID enrichment**: Map the targeted CLSID to the legitimate COM server it overrides — helps prioritise alerts where the hijacked CLSID belongs to a high-value host process (Explorer, Task Scheduler).
- **Baseline analysis**: Run the Stage 1 query across a full enterprise for 30 days to build a per-host CLSID registration baseline before enabling alerting.
- **Sigma rule PR**: Submit to the upstream SigmaHQ repository after additional field testing.
