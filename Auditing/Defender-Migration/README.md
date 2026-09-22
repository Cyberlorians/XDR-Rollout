# Defender Migration Reporting

Ten standalone, read-only queries for Defender Advanced Hunting. Rebuilt from a review of 35 reporting blocks and compared with this repository's existing AV-mode and Intune ASR tools. Customer source files and tenant results are not included.

**Validated in GCC High on September 22, 2026:** all ten queries executed successfully. Inventory and assessment reports returned live data; ASR/USB event reports returned zero live rows and were additionally exercised with synthetic KQL fixtures. See [validation evidence](VALIDATION.md) and the [replacement map](COMPARISON.md).

## Run

Open a query in Defender Advanced Hunting, select the entire query, and run it. Each file is independent; no functions, saved queries, Graph connection, or deployment are required. Table access, endpoint onboarding, licensing, and appropriate hunting permissions are prerequisites. TVM tables are Defender hunting sources, not standard Sentinel connector tables.

| Report | Purpose |
| --- | --- |
| [Device readiness](Device-Readiness.kql) | Latest observed onboarding, sensor health, reported AV mode, and independent source timestamps |
| [Readiness summary](Readiness-Summary.kql) | Device counts by observed state and freshness, without invented migration phases |
| [Combined device evidence](Device-Evidence-Summary.kql) | AV/inventory evidence alongside applicable, nonapplicable, unknown, and stale ASR assessment counts |
| [ASR assessment detail](ASR-Assessments.kql) | Latest assessment per device/configuration, including inventory devices without ASR assessments |
| [ASR assessment summary](ASR-Assessment-Summary.kql) | Rule-level compliance evidence; reporting population is assessment devices, not the inventory denominator |
| [ASR event detail](ASR-Events.kql) | Filterable drilldowns with 19 canonical GUID labels, raw action fallback, account/process/file context, and event identity |
| [Daily ASR activity](ASR-Daily-Activity.kql) | Recorded event counts, approximate device counts, and capped file/process samples |
| [USB correlation](USB-Correlation.kql) | Every USB ASR event with nearest qualifying mount candidates, including tied candidates and unmatched events |
| [Configuration discovery](Configuration-Discovery.kql) | Actual configuration ID meanings, applicability, and assessment coverage |
| [Weekly observations](Weekly-Observations.kql) | Last inventory observation within each week plus independently observed ASR activity |

Default lookback is 30 days. USB uses 29 days of ASR events plus a 24-hour mount lookback, fitting a 30-day retention window. The seven-day freshness threshold is a reporting choice, not a product SLA. Adjust parameters to your retention and reporting requirements.

### ASR drilldowns

In the event-detail query, leave both filters empty for all ASR events. Set `ActionFilter` to a prefix below or a full action name for a narrower view; `RuleFilter` accepts a GUID when present in event telemetry. Both filters apply when both are populated.

| Activity | ActionFilter |
| --- | --- |
| Copied/impersonated system tools | `AsrAbusedSystemTool` |
| Email/webmail executable content | `AsrExecutableEmailContent` |
| Office executable content | `AsrExecutableOfficeContent` |
| JavaScript/VBScript downloaded executables | `AsrScriptExecutableDownload` |
| LSASS access | `AsrLsassCredentialTheft` |
| Obfuscated scripts | `AsrObfuscatedScript` |
| Office communication child processes | `AsrOfficeCommAppChildProcess` |
| Office process injection | `AsrOfficeProcessInjection` |
| PSExec/WMI process creation | `AsrPsexecWmiChildProcess` |
| Ransomware ASR | `AsrRansomware` |
| Prevalence/age/trust rule | `AsrUntrustedExecutable` |
| USB execution | `AsrUntrustedUsbProcess` |
| Vulnerable signed drivers | `AsrVulnerableSignedDriver` |

For block-only reporting, use the full `...Blocked` action name. Prefixes retain audit, block, and any other matching actions. `ObservedAction` describes the event, not effective policy. Ransomware ASR is not Controlled Folder Access reporting; vulnerable-driver ASR is not proof of every driver-load prevention.

### USB options

`NearestOnly = true` keeps the latest qualifying mount timestamp; exact ties remain visible. Set it to `false` for every qualifying mount. `CandidateCount` counts all qualifying mounts, even in nearest-only mode. Multiple rows are expected for ties or all-candidate output; count distinct device/name/timestamp/report identities when reconciling events.

Correlation requires the same device and a nonempty normalized drive, with the mount at or before the event and at most 24 hours earlier. This is candidate enrichment, not causal attribution. Copied files, missing mount/dismount telemetry, drive reuse, and retention boundaries can prevent attribution.

## Interpretation

- Inventory is the observed 30-day population, not a CMDB or all licensed devices. Merged-away inventory records are excluded. Entirely absent devices need an external expected-device list.
- AV mode reuses [the existing inventory approach](../Defender-AV-Mode-Inventory.kql): `DeviceTvmInfoGathering.AdditionalFields.AvMode`. This property is not documented in the public hunting schema. Lab execution is verified; compare known devices with AV health reporting before operational decisions. Codes outside 0-5 remain explicit.
- Source timestamps show when the respective service recorded data, not necessarily a new endpoint heartbeat. Recent TVM data does not override stale inventory or an inactive sensor. AV mode is not inferred from configuration compliance, and Passive does not identify the primary third-party product.
- ASR assessments describe recommendations and applicability. They do not prove configured Block/Audit/Warn/Off mode. Missing assessment counts remain null in the combined report. No-event and no-assessment cases are not policy-disabled states.
- Rule-level summary includes devices with assessments even if absent from current inventory; detail and combined reports are inventory-led. Their populations can differ deliberately. Neither invents an expected-rule baseline or treats discovered rules as the required baseline.
- Event counts are recorded telemetry, subject to ASR throttling. `dcount` is approximate; sample lists are capped at 20. Raw command lines and account/file details may be sensitive. Export with proper CSV serialization and handle spreadsheet formulas safely.
- Weekly observations are not migration transitions or complete end-of-week snapshots. Populations overlap; do not stack them as an estate total. `PartialWeek` identifies truncated boundary weeks. Snapshot-only sources cannot recreate historical policy state.
- No report declares migration complete, third-party AV removed, or an ASR baseline fully deployed. Those require an agreed acceptance baseline and additional effective-policy/deployment evidence.

## Existing Tools Reused

- [AV-mode inventory](../Defender-AV-Mode-Inventory.kql): the reported-mode source used by the three inventory-led reports, extended here with explicit missing data and separate recency.
- [Intune ASR policy/event correlation](../ASR-Policy-Event-Correlation/): optional configured-policy context. It uses Graph beta and supported Endpoint Security templates; GUID event correlation is not effective per-device policy or proof of the originating policy. Overlapping policies repeat counts. Review assignment exclusions/filters independently, especially if group lookup fails. Do not publish generated policy/assignment data.
- [Endpoint policy auditing](../MDE-EndpointPolicies.kql): optional change history requiring its Sentinel sources. Not a replacement for applied-device policy and not revalidated as part of this pack.

## Grounding

- [ASR rule reference and event names](https://learn.microsoft.com/defender-endpoint/attack-surface-reduction-rules-reference)
- [ASR monitoring and throttling](https://learn.microsoft.com/defender-endpoint/attack-surface-reduction-rules-monitor)
- [Device event schema and event identity](https://learn.microsoft.com/defender-xdr/advanced-hunting-deviceevents-table)
- [Secure configuration assessments](https://learn.microsoft.com/defender-xdr/advanced-hunting-devicetvmsecureconfigurationassessment-table)
- [Configuration knowledge base](https://learn.microsoft.com/defender-xdr/advanced-hunting-devicetvmsecureconfigurationassessmentkb-table)
- [Documented AV health API mode codes](https://learn.microsoft.com/defender-endpoint/api/device-health-api-methods-properties)

The AV health API contract is not a guarantee for undocumented hunting properties. The validation note separates runtime evidence from remaining acceptance checks.