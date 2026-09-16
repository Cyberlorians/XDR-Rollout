# Intune ASR Policy to MDE Event Correlation

Generates a ready-to-run Microsoft Defender Advanced Hunting query from the live Intune Attack Surface Reduction policy configuration.

The PowerShell script reads deployed Endpoint Security **Attack Surface Reduction Rules** policies through Microsoft Graph and writes a `.kql` file containing:

- Intune policy name and ID
- Assignment names
- Canonical ASR rule name and GUID
- Configured mode (`Off`, `Block`, `Audit`, or `Warn`)
- MDE event and device counts
- First and last observed event
- Observed MDE `ActionType` values and device names
- Configured rules with zero observed events

## Requirements

- PowerShell 7 or Windows PowerShell 5.1
- `Microsoft.Graph.Authentication` PowerShell module
- Delegated Microsoft Graph permissions:
  - `DeviceManagementConfiguration.Read.All`
  - `Group.Read.All`
- Access to Microsoft Defender Advanced Hunting to run the generated query

Install the authentication module when needed:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
```

## Commercial

```powershell
.\Export-IntuneAsrHuntingQuery.ps1 `
  -Environment Global `
  -TenantId '<tenant-id>' `
  -UseDeviceCode `
  -LookbackDays 30 `
  -OutputPath '.\Intune-ASR-Tracking.kql'
```

Paste the generated query into Microsoft Defender Advanced Hunting at `https://security.microsoft.com/v2/advanced-hunting`.

## GCC High

```powershell
.\Export-IntuneAsrHuntingQuery.ps1 `
  -Environment USGov `
  -TenantId '<gcc-high-tenant-id>' `
  -UseDeviceCode `
  -LookbackDays 30 `
  -OutputPath '.\Intune-ASR-Tracking.kql'
```

`USGov` selects the Microsoft Graph US Government environment and `https://graph.microsoft.us`. Paste the generated query into Advanced Hunting in the GCC High Defender portal.

## What the correlation means

MDE ASR events contain the canonical ASR rule GUID in `AdditionalFields.RuleId`, but they do not contain the originating Intune policy ID. The generated query therefore correlates observed events to every discovered Intune policy that configures the same rule GUID and displays that policy's assignments.

A zero event count means no matching ASR behavior was observed during the selected lookback. It does not prove that the rule was not deployed. Use Intune device and per-setting status for deployment confirmation.

If multiple policies or another management authority configure the same rule, compare `ConfiguredMode` with `ObservedActions`. For example, a policy configured for Audit alongside a `Blocked` event indicates another effective configuration source or overlapping policy should be investigated.
