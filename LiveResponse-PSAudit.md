param([int]$Days = 30, [string]$OutDir = "$HOME\Desktop")

$out = Join-Path $OutDir "LR-Audit_$(Get-Date -Format yyyyMMdd_HHmmss).csv"

$rows = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-$Days) -EndDate (Get-Date) `
    -RecordType MSDEResponseActions -ResultSize 5000 |
    ForEach-Object {
        $d = $_.AuditData | ConvertFrom-Json
        [PSCustomObject]@{
            Time          = $d.CreationTime
            User          = $d.UserId
            Operation     = $d.Operation
            Device        = $d.DeviceName
            DeviceId      = $d.DeviceId
            Command       = $d.CommandsString
            FileName      = $d.FileName
            FileSHA256    = $d.FileSHA256
            ActionComment = $d.ActionComment
            ClientIP      = $d.ClientIP -replace '::ffff:',''
        }
    } | Sort-Object Time -Descending

$rows | Export-Csv $out -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($rows.Count) records to: $out"
