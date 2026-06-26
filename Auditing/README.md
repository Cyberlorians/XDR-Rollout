# XDR Change Auditing — KQL Pack

KQL to audit **configuration changes** across the Microsoft security stack (Defender XDR, MDE/MDO/MDA/MDI,
Entra ID, Intune, Purview, Exchange, Sentinel). Each query answers **WHO** changed **WHAT**, **WHERE**.

- One query per `.kql` file — runnable / deployable as-is. This page is the index.
- Default lookback `30d`. Time column is **`TimeGenerated`** (Sentinel) / **`Timestamp`** (Advanced Hunting).

## Coverage Tracker

Every query was executed against the live workspace on **2026-06-26** (`Verified` = rows returned over 30d).
Legend: ✅ verified with data · ⚠️ valid syntax, 0 events in window (nothing to match yet) · ⬜ backlog.

| Audit activity | Description | Query | Verified (30d) | Status |
|---|---|---|---|---|
| **Master — all products** | Single normalized timeline of every change across all workloads | [`Master-AllProducts.kql`](Master-AllProducts.kql) | 2,945 | ✅ |
| **Defender XDR — Unified RBAC** | Role & assignment changes (URBAC + legacy S&C RBAC) | [`DefenderXDR-URBAC.kql`](DefenderXDR-URBAC.kql) | 1,696 | ✅ |
| **Defender XDR — Custom detections** | Custom detection rules + portal settings | [`DefenderXDR-CustomDetections.kql`](DefenderXDR-CustomDetections.kql) | 4 | ✅ |
| **Defender XDR — Advanced features (all)** | Alert on any `SetAdvancedFeatures` toggle | [`AdvancedFeatureModificationAlert.kql`](AdvancedFeatureModificationAlert.kql) | 0 | ⚠️ |
| **Defender XDR — EDR block mode** | Alert when EDR-in-block-mode is toggled | [`EDRBlockMode.kql`](EDRBlockMode.kql) | 0 | ⚠️ |
| **MDE — EDR/AV/ASR policies** | Endpoint security policy create/edit/assign (Intune-authored) | [`MDE-EndpointPolicies.kql`](MDE-EndpointPolicies.kql) | 24 | ✅ |
| **MDE — Live Response** | Live Response sessions/API + manual response actions | [`LiveResponse.kql`](LiveResponse.kql) | 10 | ✅ |
| **MDO — threat policies** | Anti-phish / spam / Safe Links / Safe Attachments cmdlets | [`MDO-ThreatPolicies.kql`](MDO-ThreatPolicies.kql) | 0 | ⚠️ |
| **MDA — policies & governance** | Cloud-app policies + risky OAuth consents/grants | [`MDA-Policies.kql`](MDA-Policies.kql) | 84 | ✅ |
| **MDI — sensor & config** | Defender for Identity workload changes | [`MDI-Config.kql`](MDI-Config.kql) | 4 | ✅ |
| **Purview — DLP/Labels/Retention** | DLP, sensitivity labels, retention/audit policies | [`Purview-DLP-Labels-Retention.kql`](Purview-DLP-Labels-Retention.kql) | 18 | ✅ |
| **Entra ID — directory changes** | CA policies, app regs, roles, consents, cross-tenant | [`EntraID-Directory.kql`](EntraID-Directory.kql) | 2,427 | ✅ |
| **Intune — device config & compliance** | All Endpoint Manager changes | [`Intune-DeviceConfig.kql`](Intune-DeviceConfig.kql) | 50 | ✅ |
| **Exchange Online — admin config** | Transport, mailbox, org config (CA mirror excluded) | [`ExchangeOnline.kql`](ExchangeOnline.kql) | 460 | ✅ |
| **Sentinel — analytics & workspace** | Sentinel changes in the unified audit slice | [`Sentinel-Config.kql`](Sentinel-Config.kql) | 392 | ✅ |
| **Daily digest** | Roll-up of changes by product & actor (1d) | [`DailyDigest.kql`](DailyDigest.kql) | 32 | ✅ |

> ⚠️ rows: `SetAdvancedFeatures` and the MDO cmdlets produced 0 events in the 30-day window — the queries
> are correct (e.g. the `Application=="Microsoft 365"` filter matches 22k events), there were simply no
> advanced-feature toggles or MDO policy edits to catch. They will return rows once such a change occurs.

## Backlog (⬜ not yet built)

- MDE custom indicators (IOCs) add/remove
- MDO quarantine release / admin remediation actions
- Entra PIM role activations (dedicated view)
- Sentinel automation rules / playbooks (Logic Apps) via `AzureActivity`
- Defender for Cloud (Azure workloads) policy & recommendation changes via `AzureActivity`
- Secure Score control changes

## Notes

- **Actor kinds** derived from O365 `UserType` (4=System, 5=Application, 6=ServicePrincipal) + heuristics
  (`NT SERVICE\…` / `S-1-5-…` = service, `@` = user).
- **Noise excluded**: Exchange `Set-ConditionalAccessPolicy` (system mirror of Entra CA), `MoveToDeletedItems`,
  file/preview telemetry, `*_Get` reads.
- **PII**: queries prefer `NonPIIParameters` over `Parameters` for safe sharing.
- **Tokens**: KQL `has`/`!has` match whole tokens — use `contains` / `matches regex` for substrings.
