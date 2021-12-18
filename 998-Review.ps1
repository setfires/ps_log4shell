$base_path = Split-Path $PSCommandPath
try { . ("$base_path\_ANSI_COLORS.ps1") } catch { Write-Host "Error loading imports"}

$clientList = Get-Content -Path "$base_path\999-ReviewList.txt"
$clients = @($clientList) | Sort-Object
$clientTotal = ($clients).Count

Write-Host "$hlYellow $clientTotal $clear"

foreach ($client in $clients ) {
    Get-ADComputer -Identity $client -Properties Description, Enabled | Select-Object Name, Description, Enabled
}