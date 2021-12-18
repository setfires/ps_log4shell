$base_path = Split-Path $PSCommandPath
try { . ("$base_path\_ANSI_COLORS.ps1") } catch { Write-Host "Error loading imports"}
$clients = Get-Content -Path "$base_path\999-Clients.txt"
$clients = $clients | Sort-Object
$clientsTotal = ($clients).Count
$clientRunCount = 1

foreach( $client in $clients ) {
    try {
        $isAD = Get-ADComputer -Identity $client -ErrorAction Stop
        if ( $isAD ) { $ad = 1 }
    }
    catch { $ad = 0 }
    
    if( $ad ) {
        if ( Test-Connection -TargetName $client -Count 1 -Quiet -IPv4 -ErrorAction Ignore ) {
            Write-Host "$fgYellow$clientRunCount$clear/$clientsTotal $fgGreen$client$clear"

            $clientIP = [System.Net.Dns]::GetHostByName("$($client)").AddressList[0].IPAddressToString
            $clientFQDN = [System.Net.Dns]::GetHostByAddress("$($clientIP)").Hostname -replace "\.corp\.com"
            
            ## Primary process

            if ( $clientFQDN -eq $client ) { C:\bin\psexec\PsExec.exe \\$client -nobanner -e -h powershell enable-psremoting -force }
                        
            ##
        }
        else {
            Write-Host "$fgYellow$client$clear $XMARK Offline$clear"
        }
    } else {
        Write-Host "$fgRed$client$clear $XMARK Client not in AD$clear"
    }
    $clientRunCount += 1
    Write-Host ""
}
