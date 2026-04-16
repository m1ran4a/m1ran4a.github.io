---
title: "Local Account Creation via Net.exe"
date: 2025-04-10
draft: false
author: "Hugo Miranda"
description: "Detects local user account creation using net.exe or net1.exe. Adversaries create local accounts for persistence, to maintain access following credential rotation, or to establish a backdoor that survives reimaging."
mitre_technique: "T1136.001"
mitre_tactic: "Persistence"
technique_name: "Create Account: Local Account"
severity: "high"
status: "stable"
logsource: "Windows — Process Creation (Sysmon EID 1 / Security EID 4688)"
sigma: |
  title: Local Account Created via Net.exe
  id: d5a35200-ac00-11ea-b3a6-6c9466d1c0a8
  status: stable
  description: >
    Detects local user account creation using net.exe or net1.exe commands.
    Adversaries create local accounts for persistence, to maintain access after
    credential rotation, or to establish a backdoor surviving reimaging.
    The filter excludes /domain operations to reduce noise on domain controllers.
  references:
    - https://attack.mitre.org/techniques/T1136/001/
    - https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/net-user
  author: Hugo Miranda
  date: 2025-04-10
  tags:
    - attack.persistence
    - attack.t1136.001
  logsource:
    product: windows
    category: process_creation
  detection:
    selection_img:
      Image|endswith:
        - '\net.exe'
        - '\net1.exe'
    selection_user:
      CommandLine|contains: ' user '
    selection_add:
      CommandLine|contains:
        - ' /add'
        - ' add '
    filter_domain:
      CommandLine|contains: ' /domain'
    condition: all of selection_* and not filter_domain
  falsepositives:
    - Legitimate administrator account provisioning
    - Automated provisioning scripts (allowlist by parent process or initiating account)
  level: high
converted_queries:
  - platform: "QRadar AQL"
    language: "sql"
    query: |
      SELECT
        LOGSOURCENAME(logsourceid) AS log_source,
        username,
        "sourceip",
        "Image",
        "CommandLine",
        "ParentImage",
        "ParentCommandLine",
        starttime
      FROM events
      WHERE
        logsourcetypename(devicetype) IN (
          'Microsoft Windows Security Event Log',
          'Microsoft Sysmon'
        )
        AND (
          "Image" ILIKE '%\net.exe'
          OR "Image" ILIKE '%\net1.exe'
        )
        AND "CommandLine" ILIKE '% user %'
        AND (
          "CommandLine" ILIKE '% /add%'
          OR "CommandLine" ILIKE '% add %'
        )
        AND "CommandLine" NOT ILIKE '% /domain%'
      ORDER BY starttime DESC
      LAST 24 HOURS
  - platform: "Microsoft Sentinel (KQL)"
    language: "kql"
    query: |
      DeviceProcessEvents
      | where FileName in~ ("net.exe", "net1.exe")
      | where ProcessCommandLine has " user "
      | where ProcessCommandLine has_any ("/add", " add ")
      | where ProcessCommandLine !has "/domain"
      | project
          Timestamp,
          DeviceName,
          AccountName,
          FileName,
          ProcessCommandLine,
          InitiatingProcessFileName,
          InitiatingProcessCommandLine
      | order by Timestamp desc
  - platform: "Splunk SPL"
    language: "splunk"
    query: |
      index=windows
        (source="WinEventLog:Security" EventCode=4688
         OR source="WinEventLog:Microsoft-Windows-Sysmon/Operational" EventCode=1)
        (process_name IN ("net.exe", "net1.exe")
         OR NewProcessName IN ("*\\net.exe", "*\\net1.exe"))
        (CommandLine="* user *" OR process="* user *")
        (CommandLine="* /add*" OR process="* /add*")
        NOT (CommandLine="* /domain*" OR process="* /domain*")
      | table _time, host, user, process, CommandLine, parent_process
      | sort -_time
---

## Testing Notes

Validated using [Atomic Red Team T1136.001](https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1136.001/T1136.001.md) test cases in an isolated Windows 11 VM with Sysmon 14 deployed.

**Test commands used:**

```cmd
net user backdoor P@ssw0rd123! /add
net1 user testaccount P@ssw0rd! /add
```

Both fired as expected. The `/domain` filter was verified by running `net user domaintest /add /domain` — this produced no alert, as intended.

**Sysmon config requirements:** EID 1 (ProcessCreate) must be enabled. The default Sysmon configuration from [SwiftOnSecurity/sysmon-config](https://github.com/SwiftOnSecurity/sysmon-config) captures this.

**QRadar note:** If using Windows Security Event Log (EID 4688) rather than Sysmon, ensure `Process Command Line` auditing is enabled in Group Policy (`Computer Configuration > Windows Settings > Security Settings > Advanced Audit Policy > Detailed Tracking`). Without it, the CommandLine field will be empty.

## False Positives

- Administrator provisioning new local service accounts (allowlist by initiating user — e.g., known admin accounts or provisioning service accounts)
- Configuration management tools (Ansible, Chef, Puppet) running net.exe via scripted modules — allowlist by parent process name
- IT onboarding scripts — consider allowlisting by hostname prefix (e.g., build servers, imaging hosts)

## References

- [MITRE ATT&CK T1136.001 — Create Account: Local Account](https://attack.mitre.org/techniques/T1136/001/)
- [Microsoft: net user command](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/net-user)
- [Atomic Red Team T1136.001 test cases](https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1136.001/T1136.001.md)
- [SwiftOnSecurity Sysmon config](https://github.com/SwiftOnSecurity/sysmon-config)
