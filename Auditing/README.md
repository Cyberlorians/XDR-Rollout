# Security Auditing and Device Reports

All 27 standalone reports, the ASR query generator, guides, validation image, and synthetic test data live directly in this single folder, with no subfolders. Filenames use `Product-Subject-ReportType.kql`: **Changes** means audit history, **Inventory/Health/Evidence** means observed device state, and **Summary** means aggregated results.

**Run location:** AH = Defender Advanced Hunting (`Timestamp`); Sentinel = Log Analytics/Sentinel (`TimeGenerated`). Labels describe each query as written. Table availability, connectors, licenses, retention, and permissions still apply. None of these reports is a complete Azure resource-ID/Arc inventory.

## Device Inventory and Health

| Query | What it shows | Run in |
| --- | --- | --- |
| [DefenderEndpoint-Device-Onboarding-and-AV-Health.kql](DefenderEndpoint-Device-Onboarding-and-AV-Health.kql) | Latest onboarding, sensor health, AV mode, and independent source freshness per device | AH |
| [DefenderEndpoint-Onboarding-and-AV-Health-Summary.kql](DefenderEndpoint-Onboarding-and-AV-Health-Summary.kql) | Device counts grouped by onboarding, sensor health, mode, and freshness | AH |
| [DefenderEndpoint-Device-AV-and-ASR-Evidence.kql](DefenderEndpoint-Device-AV-and-ASR-Evidence.kql) | Device health and AV mode alongside ASR assessment counts, unknowns, and missing evidence | AH |
| [DefenderEndpoint-AV-Mode-Inventory.kql](DefenderEndpoint-AV-Mode-Inventory.kql) | Lightweight seven-day TVM AV-mode inventory; different population from the 30-day inventory-led reports | AH |
| [DefenderEndpoint-Security-Configuration-Catalog.kql](DefenderEndpoint-Security-Configuration-Catalog.kql) | Configuration ID meanings and latest assessment coverage across devices | AH |

## ASR Assessments and Activity

| Query | What it shows | Run in |
| --- | --- | --- |
| [DefenderEndpoint-ASR-Assessments-by-Device.kql](DefenderEndpoint-ASR-Assessments-by-Device.kql) | Latest assessment per device/rule, applicability, compliance, recency, and absent assessments | AH |
| [DefenderEndpoint-ASR-Assessments-by-Rule.kql](DefenderEndpoint-ASR-Assessments-by-Rule.kql) | Rule-level counts of compliant, noncompliant, nonapplicable, unknown, and stale assessments | AH |
| [DefenderEndpoint-ASR-Event-Details.kql](DefenderEndpoint-ASR-Event-Details.kql) | Filterable recorded events with GUID labels and process, file, account, and event identity fields | AH |
| [DefenderEndpoint-ASR-Events-Daily-Summary.kql](DefenderEndpoint-ASR-Events-Daily-Summary.kql) | Recorded events and approximate device counts by day, GUID, and action | AH |
| [DefenderEndpoint-ASR-USB-Mount-Correlation.kql](DefenderEndpoint-ASR-USB-Mount-Correlation.kql) | USB ASR events with candidate mounts; preserves unmatched events and nearest ties | AH |
| [DefenderEndpoint-Onboarding-and-ASR-Weekly-Observations.kql](DefenderEndpoint-Onboarding-and-ASR-Weekly-Observations.kql) | Last inventory observation within each week and separate, overlapping ASR activity populations | AH |

ASR events, assessments, configured policy, and effective device policy are different evidence. No events does not mean Off; a compliant assessment does not establish Block mode. AV mode uses an undocumented TVM hunting property and needs known-device verification. See the [reporting guide and parameters](Defender-Migration-Reporting-Guide.md).

## Configuration Changes and Response Actions

| Query | What it shows | Run in |
| --- | --- | --- |
| [CrossProduct-Configuration-Changes-Timeline.kql](CrossProduct-Configuration-Changes-Timeline.kql) | Filtered CloudAppEvents change timeline with actor, workload, target, and details; not every Azure or directory change | Sentinel |
| [CrossProduct-Configuration-Changes-Daily-Summary.kql](CrossProduct-Configuration-Changes-Daily-Summary.kql) | One-day rollup of filtered CloudAppEvents changes by workload and actor | Sentinel |
| [DefenderXDR-Role-and-Permission-Changes.kql](DefenderXDR-Role-and-Permission-Changes.kql) | Unified and legacy security RBAC role/assignment events | Sentinel |
| [DefenderXDR-Detection-and-Portal-Changes.kql](DefenderXDR-Detection-and-Portal-Changes.kql) | Defender XDR configuration events with detection-rule fields when present | Sentinel |
| [DefenderXDR-Advanced-Feature-Changes.kql](DefenderXDR-Advanced-Feature-Changes.kql) | Advanced-feature setting changes and new toggle values | AH |
| [DefenderEndpoint-EDR-Block-Mode-Setting-Changes.kql](DefenderEndpoint-EDR-Block-Mode-Setting-Changes.kql) | Changes to the tenant EDR-in-block-mode setting, not per-device AV mode | AH |
| [DefenderEndpoint-Security-Policy-Changes.kql](DefenderEndpoint-Security-Policy-Changes.kql) | Filtered Intune endpoint-security policy audit and Defender workload events | Sentinel |
| [DefenderEndpoint-Live-Response-and-Device-Actions.kql](DefenderEndpoint-Live-Response-and-Device-Actions.kql) | Live Response sessions/API activity and selected manual device-response actions | Sentinel |
| [DefenderCloudApps-Policy-and-App-Consent-Events.kql](DefenderCloudApps-Policy-and-App-Consent-Events.kql) | Cloud Apps workload events plus selected app-consent/permission events | Sentinel |
| [DefenderIdentity-Configuration-Audit-Events.kql](DefenderIdentity-Configuration-Audit-Events.kql) | Defender for Identity workload audit events; coverage depends on available telemetry | Sentinel |
| [DefenderOffice365-Threat-Policy-Changes.kql](DefenderOffice365-Threat-Policy-Changes.kql) | Anti-phish, anti-spam, Safe Links, Safe Attachments, and related policy cmdlets | Sentinel |
| [EntraID-Directory-Changes.kql](EntraID-Directory-Changes.kql) | Selected directory changes from AuditLogs, including policies, applications, roles, and consent | Sentinel |
| [Intune-Device-Management-Changes.kql](Intune-Device-Management-Changes.kql) | Intune management changes with actor, target, target ID, and result | Sentinel |
| [ExchangeOnline-Admin-Configuration-Changes.kql](ExchangeOnline-Admin-Configuration-Changes.kql) | Exchange admin configuration changes, excluding the Conditional Access mirror | Sentinel |
| [Purview-DLP-Label-and-Retention-Changes.kql](Purview-DLP-Label-and-Retention-Changes.kql) | Filtered DLP, information-protection, and retention audit events | Sentinel |
| [Sentinel-Unified-Audit-Events.kql](Sentinel-Unified-Audit-Events.kql) | Sentinel workload slice in CloudAppEvents, not comprehensive ARM/automation auditing | Sentinel |

## Guides and Validation

- [Migration reporting guide](Defender-Migration-Reporting-Guide.md): parameters, assumptions, and interpretation for the ten rebuilt reports, now stored in this folder.
- [Original-to-replacement comparison](Defender-Migration-Query-Comparison.md): coverage of all 35 submitted blocks.
- [September 22, 2026 validation](Defender-Migration-Validation.md): GCC High live execution plus synthetic checks; ASR/USB positive-path coverage was synthetic because the lab returned no live events.
- [Intune ASR policy/event generator](Intune-ASR-Policy-Event-Correlation-Guide.md): optional configured-policy context, with its own permissions and validation notes.
- [Export-IntuneAsrHuntingQuery.ps1](Export-IntuneAsrHuntingQuery.ps1): generates tenant-specific KQL in your current directory; generated policy and assignment data is not checked in.
- [Synthetic test data](DefenderEndpoint-Synthetic-Test-Data.kql): test-only table bindings, not a live report.
- [Filename migration map](QUERY-RENAMES.md): old paths and replacements for existing bookmarks and scripts.

The original change-audit queries retain their earlier validation notes, including MDI low-volume and MDO zero-row caveats. This naming cleanup did not change query contents or revalidate older queries. Do not assume every hunt is ready to deploy as a custom detection; required identifiers and supported sources must be checked.

## Handling and Coverage

- Default lookback is usually 30 days, but the lightweight AV inventory uses seven days, the daily digest one day, and USB events 29 days. Advanced-feature and EDR-setting queries rely on the hunting time selector.
- Treat account names, command lines, policy settings, raw event data, and exports as potentially sensitive. Some reports include Parameters when NonPIIParameters is unavailable.
- `has` matches whole terms; existing filters are not a guarantee of exhaustive coverage. This organization-only update preserves their behavior.
- No report alone proves migration completion, third-party AV removal, or full effective-policy deployment.

## Backlog

- MDE custom indicators and MDO manual remediation actions.
- Dedicated Entra PIM activation reporting.
- Sentinel automation/playbook and Defender for Cloud change reporting from AzureActivity.
- Secure Score control changes.
