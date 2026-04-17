---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: {{ .Date }}
draft: true
author: "Hugo Miranda"
description: ""
mitre_technique: ""
mitre_tactic: ""
technique_name: ""
severity: "medium"
status: "experimental"
logsource: ""
sigma: |
  title: 
  id: 
  status: experimental
  description: 
  references:
    - 
  author: Hugo Miranda
  date: {{ now.Format "2006-01-02" }}
  tags:
    - attack.
  logsource:
    product: windows
    category: process_creation
  detection:
    selection:
    condition: selection
  falsepositives:
    - 
  level: medium
converted_queries:
  - platform: "QRadar AQL"
    language: "sql"
    query: |
      SELECT LOGSOURCENAME(logsourceid) AS source,
        username, "sourceip", "Image", "CommandLine", starttime
      FROM events
      WHERE logsourcetypename(devicetype) = 'Microsoft Sysmon'
        AND -- detection logic here
      ORDER BY starttime DESC
      LAST 24 HOURS
  - platform: "Microsoft Sentinel (KQL)"
    language: "kql"
    query: |
      DeviceProcessEvents
      | where // detection logic here
      | project Timestamp, DeviceName, AccountName,
                FileName, ProcessCommandLine,
                InitiatingProcessFileName
      | order by Timestamp desc
  - platform: "Splunk SPL"
    language: "splunk"
    query: |
      index=windows (EventCode=4688 OR EventCode=1)
      // detection logic here
      | table _time, host, user, process, CommandLine
      | sort -_time
---

## Testing Notes

Describe validation methodology — lab environment, tools used, Atomic Red Team test IDs, or sample event data.

## False Positives

- 

## References

- 
