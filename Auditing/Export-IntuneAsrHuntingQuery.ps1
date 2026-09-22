[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 365)]
    [int]$LookbackDays = 30,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PWD 'Intune-ASR-Tracking.kql'),

    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [ValidateSet('Global', 'USGov')]
    [string]$Environment = 'Global',

    [Parameter()]
    [switch]$UseDeviceCode
)

$ErrorActionPreference = 'Stop'

$asrRules = [ordered]@{
    'blockabuseofexploitedvulnerablesigneddrivers' = @('Block abuse of exploited vulnerable signed drivers', '56a863a9-875e-4185-98a7-b882c64b5ce5')
    'blockadobereaderfromcreatingchildprocesses' = @('Block Adobe Reader from creating child processes', '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c')
    'blockallofficeapplicationsfromcreatingchildprocesses' = @('Block all Office applications from creating child processes', 'd4f940ab-401b-4efc-aadc-ad5f3c50688a')
    'blockcredentialstealingfromwindowslocalsecurityauthoritysubsystem' = @('Block credential stealing from the Windows local security authority subsystem (lsass.exe)', '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2')
    'blockexecutablecontentfromemailclientandwebmail' = @('Block executable content from email client and webmail', 'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550')
    'blockexecutablefilesrunningunlesstheymeetprevalenceagetrustedlistcriterion' = @('Block executable files from running unless they meet prevalence, age, or trusted list criteria', '01443614-cd74-433a-b99e-2ecdc07bfc25')
    'blockexecutionofpotentiallyobfuscatedscripts' = @('Block execution of potentially obfuscated scripts', '5beb7efe-fd9a-4556-801d-275e5ffc04cc')
    'blockjavascriptorvbscriptfromlaunchingdownloadedexecutablecontent' = @('Block JavaScript or VBScript from launching downloaded executable content', 'd3e037e1-3eb8-44c8-a917-57927947596d')
    'blockofficeapplicationsfromcreatingexecutablecontent' = @('Block Office applications from creating executable content', '3b576869-a4ec-4529-8536-b80a7769e899')
    'blockofficeapplicationsfrominjectingcodeintootherprocesses' = @('Block Office applications from injecting code into other processes', '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84')
    'blockofficecommunicationappfromcreatingchildprocesses' = @('Block Office communication applications from creating child processes', '26190899-1602-49e8-8b27-eb1d0a1ce869')
    'blockpersistencethroughwmieventsubscription' = @('Block persistence through WMI event subscription', 'e6db77e5-3df2-4cf1-b95a-636979351e5b')
    'blockprocesscreationsfrompsexecandwmicommands' = @('Block process creations originating from PSExec and WMI commands', 'd1e49aac-8f56-4280-b9ba-993a6d77406c')
    'blockuntrustedunsignedprocessesthatrunfromusb' = @('Block untrusted and unsigned processes that run from USB', 'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4')
    'blockwin32apicallsfromofficemacros' = @('Block Win32 API calls from Office macros', '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b')
    'useadvancedprotectionagainstransomware' = @('Use advanced protection against ransomware', 'c1db55ab-c21a-4637-bb3f-a12568109d35')
    'blockwebshellcreationforservers' = @('Block web shell creation for servers', 'a8f5898e-1dc8-49a9-9878-85004b8a61e6')
    'blockrebootingmachineinsafemode' = @('Block rebooting machine in Safe Mode', '33ddedf1-c6e0-47cb-833e-de6133960387')
    'blockuseofcopiedorimpersonatedsystemtools' = @('Block use of copied or impersonated system tools', 'c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb')
}

function ConvertTo-KqlString {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    return $Value.Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", ' ')
}

function Get-GraphCollection {
    param([Parameter(Mandatory)][string]$Uri)
    $items = [System.Collections.Generic.List[object]]::new()
    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject
        if ($null -ne $response.value) {
            foreach ($item in $response.value) { $items.Add($item) }
        }
        else {
            $items.Add($response)
        }
        $Uri = $response.'@odata.nextLink'
    } while ($Uri)
    return $items
}

function Get-ChoiceMode {
    param([Parameter(Mandatory)][string]$Value)
    $suffix = ($Value -split '_')[-1].ToLowerInvariant()
    switch ($suffix) {
        '0' { 'Off' }
        '1' { 'Block' }
        '2' { 'Audit' }
        '6' { 'Warn' }
        'off' { 'Off' }
        'block' { 'Block' }
        'audit' { 'Audit' }
        'warn' { 'Warn' }
        default { $suffix }
    }
}

Import-Module Microsoft.Graph.Authentication
$requiredScopes = @(
    'DeviceManagementConfiguration.Read.All',
    'Group.Read.All'
)
$context = Get-MgContext
$missingScopes = $requiredScopes | Where-Object { $_ -notin $context.Scopes }
if (-not $context -or $missingScopes -or ($TenantId -and $context.TenantId -ne $TenantId) -or $context.Environment -ne $Environment) {
    $connectParameters = @{ Scopes = $requiredScopes; Environment = $Environment; NoWelcome = $true }
    if ($TenantId) { $connectParameters.TenantId = $TenantId }
    if ($UseDeviceCode) { $connectParameters.UseDeviceCode = $true }
    Connect-MgGraph @connectParameters
}

$policies = Get-GraphCollection -Uri '/beta/deviceManagement/configurationPolicies?$top=100'
$asrPolicies = $policies | Where-Object {
    $_.templateReference.templateFamily -eq 'endpointSecurityAttackSurfaceReduction' -and
    $_.templateReference.templateDisplayName -eq 'Attack Surface Reduction Rules'
}

if (-not $asrPolicies) {
    throw 'No Intune Endpoint Security Attack Surface Reduction Rules policies were found.'
}

$rows = [System.Collections.Generic.List[object]]::new()
$unmappedSettings = [System.Collections.Generic.List[string]]::new()

foreach ($policy in $asrPolicies) {
    $settings = Get-GraphCollection -Uri "/beta/deviceManagement/configurationPolicies/$($policy.id)/settings?`$top=100"
    $assignments = Get-GraphCollection -Uri "/beta/deviceManagement/configurationPolicies/$($policy.id)/assignments"
    $assignmentNames = [System.Collections.Generic.List[string]]::new()

    foreach ($assignment in $assignments) {
        $targetType = $assignment.target.'@odata.type'
        if ($assignment.target.groupId) {
            try {
                $group = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($assignment.target.groupId)?`$select=displayName" -OutputType PSObject
                $prefix = if ($targetType -like '*exclusionGroupAssignmentTarget') { 'Exclude: ' } else { 'Group: ' }
                $assignmentNames.Add($prefix + $group.displayName)
            }
            catch {
                $assignmentNames.Add("Group: $($assignment.target.groupId)")
            }
        }
        elseif ($targetType -like '*allDevicesAssignmentTarget') { $assignmentNames.Add('All devices') }
        elseif ($targetType -like '*allLicensedUsersAssignmentTarget') { $assignmentNames.Add('All users') }
        else { $assignmentNames.Add($targetType) }
    }
    $assignmentText = ($assignmentNames | Sort-Object -Unique) -join '; '

    $instances = foreach ($setting in $settings) {
        $instance = $setting.settingInstance
        if ($instance.groupSettingCollectionValue) {
            foreach ($groupValue in $instance.groupSettingCollectionValue) {
                $groupValue.children
            }
        }
        else { $instance }
    }

    foreach ($instance in $instances) {
        if (-not $instance.choiceSettingValue) { continue }
        $definitionId = [string]$instance.settingDefinitionId
        $ruleKey = $definitionId -replace '^device_vendor_msft_policy_config_defender_attacksurfacereductionrules_', ''
        if (-not $asrRules.Contains($ruleKey)) {
            if ($definitionId -like '*attacksurfacereductionrules*') { $unmappedSettings.Add($definitionId) }
            continue
        }

        $rule = $asrRules[$ruleKey]
        $rows.Add([pscustomobject]@{
            PolicyName       = $policy.name
            PolicyId         = $policy.id
            Assignments      = $assignmentText
            RuleName         = $rule[0]
            RuleId           = $rule[1]
            ConfiguredMode   = Get-ChoiceMode -Value $instance.choiceSettingValue.value
        })
    }
}

if (-not $rows.Count) {
    throw 'ASR policies were found, but no recognized ASR rule settings were configured.'
}

$kqlRows = foreach ($row in $rows) {
    '    "{0}", "{1}", "{2}", "{3}", "{4}", "{5}"' -f (
        ConvertTo-KqlString $row.PolicyName),
        (ConvertTo-KqlString $row.PolicyId),
        (ConvertTo-KqlString $row.Assignments),
        (ConvertTo-KqlString $row.RuleName),
        (ConvertTo-KqlString $row.RuleId),
        (ConvertTo-KqlString $row.ConfiguredMode)
}

$kql = @"
// Generated from live Intune configuration ($Environment) on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K').
// MDE events contain the ASR RuleId, but not the originating Intune PolicyId.
let Lookback = ${LookbackDays}d;
let DefenderModeLookback = 7d;
let PolicyRules = datatable(PolicyName:string, PolicyId:string, Assignments:string, RuleName:string, RuleId:string, ConfiguredMode:string) [
$($kqlRows -join ",`n")
];
let LatestDefenderMode = DeviceTvmInfoGathering
| where Timestamp > ago(DefenderModeLookback)
| extend AvMode = toint(parse_json(AdditionalFields).AvMode)
| summarize arg_max(Timestamp, AvMode) by DeviceId
| extend DefenderMode = case(
    AvMode == 0, "Active",
    AvMode == 1, "Passive",
    AvMode == 2, "Disabled",
    AvMode == 3, "Other",
    AvMode == 4, "EDR Blocked",
    AvMode == 5, "Passive Audit",
    isnull(AvMode), "Not reported",
    strcat("Unknown (", tostring(AvMode), ")"))
| project DeviceId, DefenderMode, AvMode;
let OverallDefenderModeCounts = toscalar(
    LatestDefenderMode
    | summarize DeviceCount=dcount(DeviceId) by DefenderMode
    | summarize make_bag(bag_pack(DefenderMode, DeviceCount)));
let AsrEvents = DeviceEvents
| where Timestamp > ago(Lookback)
| where ActionType startswith "Asr"
| extend RuleId = tolower(tostring(parse_json(AdditionalFields).RuleId))
| join kind=leftouter LatestDefenderMode on DeviceId
| extend DefenderMode = coalesce(DefenderMode, "Not reported")
| summarize
    EventCount=count(),
    DeviceCount=dcount(DeviceId),
    FirstEvent=min(Timestamp),
    LastEvent=max(Timestamp),
    ObservedActions=make_set(ActionType),
        Devices=make_set(DeviceName, 100),
        DefenderModes=make_set(DefenderMode),
        DeviceModeDetails=make_set(strcat(DeviceName, ": ", DefenderMode), 100)
  by RuleId;
PolicyRules
| join kind=leftouter AsrEvents on RuleId
| project
    PolicyName,
    PolicyId,
    Assignments,
    RuleName,
    RuleId,
    ConfiguredMode,
    EventCount=coalesce(EventCount, 0),
    DeviceCount=coalesce(DeviceCount, 0),
    FirstEvent,
    LastEvent,
    ObservedActions,
    Devices,
    DefenderModes,
    DeviceModeDetails,
    OverallDefenderModeCounts
| order by PolicyName asc, EventCount desc, RuleName asc
"@

$resolvedOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
[System.IO.File]::WriteAllText($resolvedOutputPath, $kql, [System.Text.UTF8Encoding]::new($false))

Write-Host "Generated $resolvedOutputPath"
Write-Host "Policies: $($asrPolicies.Count); configured ASR rules: $($rows.Count); lookback: $LookbackDays days"
if ($unmappedSettings.Count) {
    Write-Warning "Unmapped ASR settings were found and omitted:`n$($unmappedSettings -join "`n")"
}