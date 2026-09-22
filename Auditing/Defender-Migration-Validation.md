# Validation Record

Date: September 22, 2026. Environment: Microsoft Defender Advanced Hunting, GCC High lab. Scope: read-only queries; no endpoint policy changes, induced blocks, or custom detections. This is lab validation, not validation against the submitting organization's endpoints.

## Live Execution

Each entire standalone query was submitted through the hunting editor. The captured query-executor response was checked for success and the submitted query text compared with the local source, ignoring whitespace. Counts below are aggregate evidence only; no device-level results are published.

| Query | HTTP | Live rows | Synthetic rows |
| --- | --- | --- | --- |
| [Device readiness](DefenderEndpoint-Device-Onboarding-and-AV-Health.kql) | 200 | 8 | 9 |
| [Readiness summary](DefenderEndpoint-Onboarding-and-AV-Health-Summary.kql) | 200 | 3 | 9 |
| [Combined evidence](DefenderEndpoint-Device-AV-and-ASR-Evidence.kql) | 200 | 8 | 9 |
| [Assessment detail](DefenderEndpoint-ASR-Assessments-by-Device.kql) | 200 | 144 | 10 |
| [Assessment summary](DefenderEndpoint-ASR-Assessments-by-Rule.kql) | 200 | 18 | 2 |
| [ASR events](DefenderEndpoint-ASR-Event-Details.kql) | 200 | 0 | 14 |
| [Daily activity](DefenderEndpoint-ASR-Events-Daily-Summary.kql) | 200 | 0 | 8 |
| [USB correlation](DefenderEndpoint-ASR-USB-Mount-Correlation.kql) | 200 | 0 | 11 nearest / 14 all candidates |
| [Configuration discovery](DefenderEndpoint-Security-Configuration-Catalog.kql) | 200 | 175 | 2 |
| [Weekly observations](DefenderEndpoint-Onboarding-and-ASR-Weekly-Observations.kql) | 200 | 5 | 6 on validation date |

All ten also executed successfully against synthetic table bindings. Weekly row counts can change with the weekday because fixtures use relative timestamps; daily grouping can change around midnight.

The 35 original blocks were separately submitted unchanged: 34 executed successfully, and G05 failed with `Failed to resolve ... ConfigurationName`. The ASR collection returned no live events. Compilation alone did not validate the original inferred modes or policy-state semantics. See the [comparison](Defender-Migration-Query-Comparison.md) for reproduced before/after differences.

## Repeat the Synthetic Tests

1. Open [the fixtures](DefenderEndpoint-Synthetic-Test-Data.kql). Its five `let` bindings shadow the hunting tables with synthetic data; they do not ingest data or alter the tenant.
2. Replace only the final `print Fixture = ...` statement with the complete contents of one production query. Keep the production query's default parameters initially.
3. Select and run the complete combined text in Advanced Hunting. Check the expectations below, not just successful compilation.
4. Repeat USB with `NearestOnly = false`. Test real table availability separately by running the production query without fixtures.

All 16 checks below passed against the captured synthetic result objects:

| Check | Expected result |
| --- | --- |
| USB identity preservation | Ten unique `(DeviceId, DeviceName, Timestamp, ReportId)` event identities in both modes despite repeated ReportId 7 |
| USB ties | The newer `ties` event has `tie-one` and `tie-two` as equally nearest mounts; its earlier event retains `earlier-event` |
| USB unmatched | `none`, `wrong`, `future`, `old`, and `blank` remain present with CandidateCount 0 |
| USB precision/boundaries | Nearest `close` serial is `one-second`, not `two-seconds`; `boundary-mount` is retained; exact 24-hour match remains eligible |
| USB all candidates | 14 rows rather than 11 nearest rows; both contain ten event identities |
| Inventory identity | Nine unique IDs; merged-away device excluded; older rename does not add a device |
| Mode mappings | Codes 0-5 map to Active, Passive, Disabled, Other, EDR Blocked, Passive Audit; missing stays Not reported; 99 stays Unknown (99) |
| Recency/hostname | Ten-day mode is Stale; two different device IDs sharing `shared-name` remain separate |
| Canonical ASR names | Uppercase script GUID resolves to JavaScript/VBScript; Office-child GUID resolves to Office child processes |
| Warn/fallback | Warn bypass retained; unknown GUID falls back to raw `AsrFutureRuleBlocked` |
| Daily reconciliation | Sum of RecordedEvents is 14, equal to event-detail rows |
| Applicability first | `active` / `fixture-1` is Not applicable despite IsCompliant=true |
| Latest/missing assessment | `active` / `fixture-2` uses latest noncompliant record; missing device has explicit no-assessment status |
| Null assessment flags | Null compliance is Compliance unknown; null applicability is Applicability unknown |
| Combined evidence | Missing ReportedAssessments is null; active device has one applicable noncompliant and one nonapplicable assessment |
| Organization summaries | Every rule's four assessment categories sum to ReportingDevices; readiness summary Devices sum to nine |

Configuration discovery and weekly observations additionally passed execution/shape checks; the 16 assertions above are not a claim of exhaustive branch coverage. Fixtures exercise synthetic shapes, not real endpoint emission, all OS versions, or scale/performance limits.

## Remaining Acceptance Checks

- Compare known devices with the AV health report/API or endpoint state. No independent endpoint comparison was performed here; the TVM AvMode property remains an undocumented hunting field.
- Validate real ASR audit/block/warn and USB mount samples in an authorized environment with those events. Zero live event rows establish schema/execution compatibility, not real event coverage.
- Confirm the expected device population, required ASR rules, effective assignment/deployment, third-party AV removal, and migration-complete criteria separately.
- Test retention, export handling, and performance at the deployment's scale. Recorded event counts can be throttled; sample lists and approximate counts have documented limits.

The original tested source is commit `d6478b0`. The September 22 filename cleanup moved these reports directly into Auditing and renamed the synthetic fixture; all 28 renamed KQL files across Auditing were verified byte-identical to their pre-move contents using SHA-256. This does not extend the live validation to older change-audit queries. See the [filename map](QUERY-RENAMES.md). Subsequent query-content edits require rerunning the corresponding live and synthetic checks.