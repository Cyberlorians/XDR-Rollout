# XDR Change Auditing — KQL Pack

A reusable KQL pack for auditing **every configuration change** across the Microsoft security stack:
Defender XDR, Defender for Endpoint / Office 365 / Identity / Cloud Apps, Entra ID, Intune, Purview,
and Microsoft Sentinel.

Each query normalizes the answer to three questions:

> **WHO** — actor + actor kind (human / service / app) · **WHERE** — product + workload · **WHAT** —
> operation, affected target, result, and the change detail / parameters.

- **Default lookback:** `30d` — change `ago(30d)` in any file to suit.
- **Run from:** Microsoft Sentinel **or** Defender XDR Advanced Hunting (mind the time-column note below).
- **Layout:** one query per `.kql` file (runnable / deployable as-is); this README is the index +
  coverage tracker. Edit the `.kql` files — not copies in prose — to avoid drift.

> [!IMPORTANT]
> - **Sentinel** uses **`TimeGenerated`**; **Advanced Hunting** uses **`Timestamp`**. Swap the time
>   column to match where you run the query.
> - KQL `has` / `!has` match **whole tokens**. Single-token ActionTypes like `CreateCustomDetection`
>   are *not* matched by `has "Create"` — use `contains` / `matches regex` for substrings.

---

## Data sources at a glance

| Table | What it carries | Actor field | Target field | Change detail |
|---|---|---|---|---|
| `CloudAppEvents` | Unified O365 mgmt activity (Exchange, SCC/Purview, Entra, MDE, MDI, MDA, URBAC, Defender XDR) | `RawEventData.UserId` | `RawEventData.ObjectId` | `Parameters` / `NonPIIParameters` / `ModifiedProperties` |
| `AuditLogs` | Entra ID directory changes (CA policies, app regs, role assignments, consents) | `InitiatedBy.user/app` | `TargetResources[].displayName` | `TargetResources[].modifiedProperties` |
| `IntuneAuditLogs` | Intune / Endpoint Manager (EDR, AV, ASR, compliance, config policies) | `Identity` | `Properties.TargetDisplayNames[0]` | `Properties` |

> [!NOTE]
> **Why a change can appear twice.** Conditional Access edits are authoritative in `AuditLogs`
> ("Update conditional access policy") but are also **mirrored** into `CloudAppEvents` as
> `Set-ConditionalAccessPolicy` written by `NT SERVICE\MSExchangeServiceHostNetCore` (system
> replication, high volume). The master query **excludes that mirror** and trusts `AuditLogs` for CA.

---

## Coverage Tracker

Legend: ✅ query present & validated · 🚧 partial / needs validation · ⬜ not yet covered (backlog).

| # | Product / activity | Source | Status | Query file |
|---|---|---|---|---|
| 0 | **Master** — single pane of glass (all products) | `CloudAppEvents` | ✅ | [`Master-AllProducts.kql`](Master-AllProducts.kql) |
| 1 | Defender XDR — Unified RBAC (roles & assignments) | `CloudAppEvents` | ✅ | [`DefenderXDR-URBAC.kql`](DefenderXDR-URBAC.kql) |
| 2 | Defender XDR — Custom detections & portal settings | `CloudAppEvents` | ✅ | [`DefenderXDR-CustomDetections.kql`](DefenderXDR-CustomDetections.kql) |
| 3 | Defender XDR — Advanced features toggles (all) | `CloudAppEvents` | ✅ | [`AdvancedFeatureModificationAlert.kql`](AdvancedFeatureModificationAlert.kql) |
| 3a | Defender XDR — EDR in block mode toggle | `CloudAppEvents` | ✅ | [`EDRBlockMode.kql`](EDRBlockMode.kql) |
| 4 | MDE — EDR / AV / ASR policies | `IntuneAuditLogs` | ✅ | [`MDE-EndpointPolicies.kql`](MDE-EndpointPolicies.kql) |
| 5 | MDE — Live Response & manual response actions | `CloudAppEvents` | 🚧 | [`LiveResponse.kql`](LiveResponse.kql) |
| 6 | MDE — custom indicators (IOCs) add/remove | `CloudAppEvents` | ⬜ | _backlog_ |
| 7 | MDO — anti-phish / spam / Safe Links / Safe Attachments | `CloudAppEvents` | 🚧 | [`MDO-ThreatPolicies.kql`](MDO-ThreatPolicies.kql) |
| 8 | MDO — quarantine release / admin remediation | `CloudAppEvents` | ⬜ | _backlog_ |
| 9 | MDA — policies & app governance | `CloudAppEvents` | ✅ | [`MDA-Policies.kql`](MDA-Policies.kql) |
| 10 | MDI — sensor & config changes | `CloudAppEvents` | 🚧 | [`MDI-Config.kql`](MDI-Config.kql) |
| 11 | Purview — DLP, sensitivity labels, retention | `CloudAppEvents` | ✅ | [`Purview-DLP-Labels-Retention.kql`](Purview-DLP-Labels-Retention.kql) |
| 12 | Entra ID — CA, app regs, roles, consents | `AuditLogs` | ✅ | [`EntraID-Directory.kql`](EntraID-Directory.kql) |
| 13 | Entra ID — PIM role activations (dedicated view) | `AuditLogs` | ⬜ | _backlog_ |
| 14 | Intune / Endpoint Manager — all device config & compliance | `IntuneAuditLogs` | ✅ | [`Intune-DeviceConfig.kql`](Intune-DeviceConfig.kql) |
| 15 | Exchange Online — transport, mailbox, org config | `CloudAppEvents` | ✅ | [`ExchangeOnline.kql`](ExchangeOnline.kql) |
| 16 | Microsoft Sentinel — analytics rules & workspace config | `CloudAppEvents` | 🚧 | [`Sentinel-Config.kql`](Sentinel-Config.kql) |
| 17 | Sentinel — automation rules / playbooks (Logic Apps) | `AzureActivity` | ⬜ | _backlog_ |
| 18 | Defender for Cloud (Azure workloads) — policy/recommendations | `AzureActivity` | ⬜ | _backlog_ |
| 19 | Secure Score control changes | `CloudAppEvents` | ⬜ | _backlog_ |
| 20 | Daily digest (roll-up by product & actor) | `CloudAppEvents` | ✅ | [`DailyDigest.kql`](DailyDigest.kql) |

---

## Query catalog

<details open>
<summary><h3>0 · Master — single pane of glass (all products)</h3></summary>

Normalizes every change-type event from `CloudAppEvents` into one timeline. Maps each workload to a
**Product** pillar, classifies the **actor kind**, and surfaces the affected **target** + change
**details**. Excludes browse/read telemetry and the Exchange CA-policy mirror noise.

▶ [`Master-AllProducts.kql`](Master-AllProducts.kql)

> **Tip:** the query keeps `NonPIIParameters` first for safe sharing; move `Parameters` first when
> you need literal values.

</details>

<details>
<summary><h3>1 · Defender XDR — Unified RBAC (roles & assignments)</h3></summary>

Creation/editing of Defender XDR **Unified RBAC** roles & assignments (`URBAC`) plus legacy
Security & Compliance RBAC grants. Shows who changed which role and the permissions added.

▶ [`DefenderXDR-URBAC.kql`](DefenderXDR-URBAC.kql)

</details>

<details>
<summary><h3>2 · Defender XDR — Custom detections & portal settings</h3></summary>

Custom detection rules (create/edit/enable/disable) and other `Microsoft365Defender` portal config.
Surfaces rule name, severity, MITRE techniques, and the KQL query body.

▶ [`DefenderXDR-CustomDetections.kql`](DefenderXDR-CustomDetections.kql)

</details>

<details>
<summary><h3>3 · Defender XDR — Advanced features toggles</h3></summary>

Advanced-feature switches (EDR in block mode, tamper protection, automated investigation, allow/block
toggles) emitted as `ActionType == "SetAdvancedFeatures"`. Two custom-detection-rule (CDR) files:

- ▶ [`AdvancedFeatureModificationAlert.kql`](AdvancedFeatureModificationAlert.kql) — alert on **any** advanced-feature toggle change.
- ▶ [`EDRBlockMode.kql`](EDRBlockMode.kql) — alert specifically when **EDR in block mode** is switched on/off.

> When deploying as a custom detection rule in Advanced Hunting, use `Timestamp` (not `TimeGenerated`)
> and project a `ReportId`.

</details>

<details>
<summary><h3>4 · Defender for Endpoint (MDE) — EDR / AV / ASR policies</h3></summary>

MDE security policies are authored through **Intune endpoint security**, so `IntuneAuditLogs` is the
source of truth. Catches AV, EDR, ASR, firewall, and ASR policy create/edit/delete + assignment, and
folds in the small `MicrosoftDefenderForEndpoint` `CloudAppEvents`.

▶ [`MDE-EndpointPolicies.kql`](MDE-EndpointPolicies.kql)

> Validated example rows: *"MDE - Windows Security UI - Hide Virus & Threat Protection"* and
> *"MDE - AV Auto Remediation - No User Actions"*.

</details>

<details>
<summary><h3>5 · Defender for Endpoint (MDE) — Live Response 🚧</h3></summary>

Live Response session start/commands and manual response actions (isolate / AV scan / collect package /
restrict execution / stop-and-quarantine). **Starter query — validate `ActionType` strings against
your tenant** before promoting to a detection rule. (`LiveResponse.kql` in this repo was a placeholder.)

▶ [`LiveResponse.kql`](LiveResponse.kql)

</details>

<details>
<summary><h3>7 · Defender for Office 365 (MDO) — threat policies 🚧</h3></summary>

Anti-phish / anti-spam / Safe Links / Safe Attachments cmdlets logged under `Exchange` /
`SecurityComplianceCenter`. Syntactically valid but **0 rows in the test window** — validate against a
tenant with recent MDO edits.

▶ [`MDO-ThreatPolicies.kql`](MDO-ThreatPolicies.kql)

</details>

<details>
<summary><h3>9 · Defender for Cloud Apps (MDA) — policies & governance</h3></summary>

App-governance / cloud-app policy changes (`MicrosoftCloudAppSecurity`) plus OAuth app consent &
permission-grant events that MDA flags as risky.

▶ [`MDA-Policies.kql`](MDA-Policies.kql)

</details>

<details>
<summary><h3>10 · Defender for Identity (MDI) — sensor & config 🚧</h3></summary>

`MicrosoftDefenderForIdentity` workload changes. Low event volume — validate in a tenant with active
MDI sensors.

▶ [`MDI-Config.kql`](MDI-Config.kql)

</details>

<details>
<summary><h3>11 · Purview — DLP, Labels, Retention</h3></summary>

DLP policies/rules, sensitive-info-type rule packages, sensitivity-label (MIP) changes, and
retention / audit-retention policies under SCC + Purview workloads.

▶ [`Purview-DLP-Labels-Retention.kql`](Purview-DLP-Labels-Retention.kql)

</details>

<details>
<summary><h3>12 · Entra ID — CA policies, app regs, roles, consents</h3></summary>

Authoritative directory-change audit from `AuditLogs`: CA policy add/update, app registrations &
secrets, service-principal changes, directory-role assignments, OAuth consents, cross-tenant access,
auth-method policy. Filters out read-only `*_Get` chatter.

▶ [`EntraID-Directory.kql`](EntraID-Directory.kql)

> For **Conditional Access only**, add `| where OperationName has "conditional access policy"`.

</details>

<details>
<summary><h3>14 · Intune / Endpoint Manager — device config & compliance</h3></summary>

Broad Intune change audit (config profiles, compliance, app deployments, scripts, enrollment, RBAC).
Use when you want *every* endpoint-management change, not just MDE.

▶ [`Intune-DeviceConfig.kql`](Intune-DeviceConfig.kql)

</details>

<details>
<summary><h3>15 · Exchange Online — transport, mailbox, org config</h3></summary>

Exchange admin changes (transport config, mailbox settings, permissions, org config). Excludes the
CA-policy mirror and high-volume mailbox-item telemetry.

▶ [`ExchangeOnline.kql`](ExchangeOnline.kql)

</details>

<details>
<summary><h3>16 · Microsoft Sentinel — analytics rules & workspace config 🚧</h3></summary>

`CloudAppEvents` captures only the slice of Sentinel activity in the unified audit. **Automation rules,
playbooks (Logic Apps), and data-connector changes live in `AzureActivity`** — see backlog.

▶ [`Sentinel-Config.kql`](Sentinel-Config.kql)

</details>

<details>
<summary><h3>20 · Daily digest (roll-up by product & actor)</h3></summary>

Compact "what changed today" summary across `CloudAppEvents` — drop into a scheduled query / workbook.

▶ [`DailyDigest.kql`](DailyDigest.kql)

</details>

---

## Notes, gotchas & tuning

- **Actor kinds** — derived from O365 `UserType` (`4`=System, `5`=Application, `6`=ServicePrincipal)
  plus heuristics: `NT SERVICE\…` / `S-1-5-…` = service, `@` = user, `…actas…` / `<user w/o sid>` =
  delegated app context.
- **Noise excluded** — Exchange `Set-ConditionalAccessPolicy` (system mirror of Entra CA),
  `MoveToDeletedItems`, file/preview/content-explorer telemetry, and `*_Get` read operations.
- **PII** — cmdlet events expose both `Parameters` (literal, may contain PII) and `NonPIIParameters`
  (redacted). Queries prefer `NonPIIParameters` for safe sharing.
- **Token vs substring** — `has`/`!has` match whole tokens; use `contains` / `matches regex` for
  single-token ActionTypes (e.g. `CreateCustomDetection`).
- **Time column** — `TimeGenerated` in Sentinel, `Timestamp` in Advanced Hunting.

---

## Contributing / backlog

Items marked ⬜ in the [Coverage Tracker](#coverage-tracker) still need a query or validation:

- [ ] MDE custom indicators (IOCs) add/remove
- [ ] MDO quarantine release / admin remediation actions
- [ ] Entra PIM role activations (dedicated view)
- [ ] Sentinel automation rules / playbooks (Logic Apps) via `AzureActivity`
- [ ] Defender for Cloud (Azure workloads) policy & recommendation changes via `AzureActivity`
- [ ] Secure Score control changes
- [ ] Validate 🚧 files (`LiveResponse`, `MDO-ThreatPolicies`, `MDI-Config`, `Sentinel-Config`)
      against tenants with recent activity
