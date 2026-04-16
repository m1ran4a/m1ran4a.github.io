---
title: "Detection Lab"
description: "A catalog of Sigma detection rules — researched, tested, and converted for QRadar, Sentinel, and Splunk."
---

Sigma is a generic, open signature format for SIEM detections. Rules written in Sigma can be converted to any supported platform — QRadar AQL, Microsoft Sentinel KQL, Splunk SPL, Elastic EQL — using the `sigma-cli` toolchain.

This section is a working catalog of rules I've researched, written, or significantly tuned. Each entry includes the raw Sigma YAML, platform-specific query conversions, validation notes, and known false positives. Rules are mapped to MITRE ATT&CK techniques and tagged by tactic for navigation.
