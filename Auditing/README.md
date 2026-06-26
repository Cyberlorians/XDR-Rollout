# XDR Change Auditing — KQL Pack

KQL to audit **configuration changes** across the Microsoft security stack (Defender XDR, MDE/MDO/MDA/MDI,
Entra ID, Intune, Purview, Exchange, Sentinel). Each query answers **WHO** changed **WHAT**, **WHERE**.

- One query per `.kql` file — runnable / deployable as-is. This page is the index.
- Default lookback `30d`. Time column is **`TimeGenerated`** (Sentinel) / **`Timestamp`** (Advanced Hunting).

## Coverage Tracker

Every query was validated against the live workspace on **2026-06-26** and confirmed to run correctly.

| Audit activity | Description | Query | Status |
|---|---|---|---|
| **Master — all products** | Single normalized timeline of every change across all workloads | [`Master-AllProducts.kql`](Master-AllProducts.kql) | ✅ |
| **Defender XDR — Unified RBAC** | Role & assignment changes (URBAC + legacy S&C RBAC) | [`DefenderXDR-URBAC.kql`](DefenderXDR-URBAC.kql) | ✅ |
| **Defender XDR — Custom detections** | Custom detection rules + portal settings | [`DefenderXDR-CustomDetections.kql`](DefenderXDR-CustomDetections.kql) | ✅ |
| **Defender XDR — Advanced features (all)** | Alert on any `SetAdvancedFeatures` toggle | [`AdvancedFeatureModificationAlert.kql`](AdvancedFeatureModificationAlert.kql) | ✅ |
| **Defender XDR — EDR block mode** | Alert when EDR-in-block-mode is toggled | [`EDRBlockMode.kql`](EDRBlockMode.kql) | ✅ |
| **MDE — EDR/AV/ASR policies** | Endpoint security policy create/edit/assign (Intune-authored) | [`MDE-EndpointPolicies.kql`](MDE-EndpointPolicies.kql) | ✅ |
| **MDE — Live Response** | Live Response sessions/API + manual response actions | [`LiveResponse.kql`](LiveResponse.kql) | ✅ |
| **MDO — threat policies** | Anti-phish / spam / Safe Links / Safe Attachments cmdlets | [`MDO-ThreatPolicies.kql`](MDO-ThreatPolicies.kql) | ✅ |
| **MDA — policies & governance** | Cloud-app policies + risky OAuth consents/grants | [`MDA-Policies.kql`](MDA-Policies.kql) | ✅ |
| **MDI — sensor & config** | Defender for Identity workload changes | [`MDI-Config.kql`](MDI-Config.kql) | ✅ |
| **Purview — DLP/Labels/Retention** | DLP, sensitivity labels, retention/audit policies | [`Purview-DLP-Labels-Retention.kql`](Purview-DLP-Labels-Retention.kql) | ✅ |
| **Entra ID — directory changes** | CA policies, app regs, roles, consents, cross-tenant | [`EntraID-Directory.kql`](EntraID-Directory.kql) | ✅ |
| **Intune — device config & compliance** | All Endpoint Manager changes | [`Intune-DeviceConfig.kql`](Intune-DeviceConfig.kql) | ✅ |
| **Exchange Online — admin config** | Transport, mailbox, org config (CA mirror excluded) | [`ExchangeOnline.kql`](ExchangeOnline.kql) | ✅ |
| **Sentinel — analytics & workspace** | Sentinel changes in the unified audit slice | [`Sentinel-Config.kql`](Sentinel-Config.kql) | ✅ |
| **Daily digest** | Roll-up of changes by product & actor (1d) | [`DailyDigest.kql`](DailyDigest.kql) | ✅ |

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
