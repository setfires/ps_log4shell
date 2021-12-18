$base_path = Split-Path $PSCommandPath
try { . ("$base_path\_ANSI_COLORS.ps1") } catch { Write-Host "Error loading imports"} # Load ANSI colors and symbols for console output
if ( !( Test-Path -Path "$base_path\reports\" ) ) { New-Item -Path "$base_path\reports\" -ItemType Directory | Out-Null }

$fileprefix = Get-Content -Path $base_path\prefix.txt # Get site prefix
$updatelog = "$base_path\reports\$($fileprefix)_Working.csv" # Set update log file name
$newlog = "$base_path\reports\$($fileprefix)_$(Get-Date -Format "yy-MM-dd_HHmm").csv" #Set new log file name

# Error Log
$errorlog = "$base_path\reports\$($fileprefix)_Error_$(Get-Date -Format "yy-MM-dd_HHmm").csv"
New-Item -Path $errorlog | Out-Null
Add-Content -Path $errorlog -Value "`"Hostname`",`"Online`",`"Error`",`"Description`""

$firstRun = (Test-Path -Path $base_path\first.txt)
$new = (Test-Path -Path $base_path\new.txt)
$update = (Test-Path -Path $base_path\update.txt)

$clientList = "$base_path\101-Clients.txt"
$psremotingClients = "$base_path\999-Clients.txt"
if ( Test-Path $psremotingClients ) {
    Remove-Item -Path $psremotingClients
    New-Item -Path $psremotingClients -ItemType File | Out-Null
}
$reviewList = "$base_path\999-ReviewList.txt"
if ( !( Test-Path $reviewList ) ) {
    New-Item -Path $reviewList -ItemType File | Out-Null
}

if ( $firstRun ) {

    if ( !( Test-Path -Path $clientList ) ) {
        New-Item -Path $clientList | Out-Null
    }

    if ( !( Test-Path -Path $psremotingClients ) ) {
        New-Item -Path $psremotingClients | Out-Null
    }

    if ( !( Test-Path -Path $updatelog ) ) {
        New-Item -Path $updatelog | Out-Null
        Add-Content -Path $updatelog -Value "`"Hostname`",`"Connected`",`"CommandSuccess`",`"Found`""
    }

    $log = $updatelog

    Import-Module ActiveDirectory
    $ou = Get-Content -Path "$base_path\ou.txt" # Retrieve target OU for initial search
    $clients = Get-ADComputer -Filter "Enabled -eq 'true'" -SearchBase $ou -Properties Name |  Select-Object -ExpandProperty Name # Modify search filters here

}
elseif ( $new ) {
    if ( !( Test-Path -Path $newlog ) ) {
        New-Item -Path $newlog| Out-Null
        Add-Content -Path $newlog -Value "`"Hostname`",`"Connected`",`"CommandSuccess`",`"Found`""
    }

    $log = $newlog

    $clients = Get-Content -Path $clientList
}
elseif ( $update ) {

    $log = $updatelog

    $clients = Get-Content -Path $clientList
}

$clients = @($clients) | Sort-Object
$clientTotal = ($clientList).Count
$clientCount = 0
$successCount = 0
$jobsDone = $false

$main_command = {
    $clientResult = [PSCustomObject]@{}
    $Found = @( Get-ChildItem -Path "C:\" -Filter '*log4j*.jar' -Recurse | Select-Object @{Name="FilePath";Expression={"$($_.Directory)\$($_.Name);".Trim()}} | Select-Object FilePath -ExpandProperty FilePath )
    $clientResult | Add-Member -MemberType NoteProperty -Name 'Connected' -Value $true
    $clientResult | Add-Member -MemberType NoteProperty -Name 'CommandSuccess' -Value $true
    if ( $found ) {
        $clientResult | Add-Member -MemberType NoteProperty -Name 'Found' -Value "$(( $Found | Out-String ).Trim() )"
    }
    else {
        $clientResult | Add-Member -MemberType NoteProperty -Name 'Found' -Value "No results"
    }
    $clientResult
}

Write-Host "$hlBlue Starting @ $(Get-Date -Format "yy-MM-dd_HH:mm:ss") $clear"

$jobs = @()
foreach ($client in $clients ) {
    $jobs += Invoke-Command -ComputerName $client -ScriptBlock $main_command -AsJob -JobName "Log4Shell" -ErrorAction SilentlyContinue
    Write-Host "$hlGreen $($clientCount + 1) $clear $fgGreen$($jobs[$clientCount].id)$clear $hlYellow $client $clear" -NoNewline
    $clientCount += 1
    if ( $clientCount -ne $clientTotal ) { Write-Host " " -NoNewline }
}

Write-Host ""

$waitSec = 0
while ( $jobsDone -ne $true ) {
    $jobRunning = $false
    foreach ( $job in (Get-Job) ) {
        if ( ( $job.State -eq "Completed" ) -and ( $job.HasMoreData -eq $true ) ) {

            $successCount += 1 

            $r = $job | Receive-Job | Select-Object @{Name="Hostname";Expression={$_.PSComputerName}}, Connected, CommandSuccess, Found

            if( $r.Connected ) { $cStatus = "$fgGreen$CHECK$clear Connected" }
            if( $r.CommandSuccess ) { $sStatus = "$fgGreen$CHECK$clear Success" }
            if( $r.Found -ne "No results" ) { $fStatus = "$hlYellow $CHECK Found $clear" } else { $fStatus = "$hlGreen $CHECK Not found $clear" }
            
            if ( $nl -eq $true ) {
                Write-Host ""
                $nl = $false
            }
            Write-Host "$hlGreen $successCount $clear $fgGreen$($job.Location)$clear`t$fgGreen$CHECK$clear Job complete $clear$cStatus $sStatus $fStatus"

            Add-Content -Path $log -Value "`"$($job.Location)`",`"$($r.Connected)`",`"$($r.CommandSuccess)`",`"$($r.Found)`""

            Set-Content -Path $clientList -Value ( Get-Content $clientList | Select-String -Pattern $job.Location -NotMatch )

            Remove-Job -Job $job
        }
        elseif( ( $job.State -eq "Completed" ) -and ( $job.HasMoreData -eq $false ) ) {
            $cStatus = "$fgGreen$CHECK$clear Connected"
            $sStatus = "$fgGreen$CHECK$clear Failed" 
            
            if ( $nl -eq $true ) {
                Write-Host ""
                $nl = $false
            }
            Write-Host "$hlGreen $successCount $clear $fgGreen$($job.Location)$clear`t$fgGreen$CHECK$clear Job complete $clear$cStatus $sStatus"

            Remove-Job -Job $job
        }

        if ( $job.State -eq "Running" ) {
            $jobRunning = $true
        }
    }

    if ( $jobRunning -ne $true ) {
        $jobsDone = $true
    }
    
    if ( $waitSec % 60 ) {
        Write-Host "." -NoNewline
    }
    else {
        Write-Host "$hlYellow!$clear" -NoNewline
    }
    $nl = $true
    Start-Sleep -Seconds 5
    $waitSec += 5
}

Write-Host ""
Write-Host "$hlGreen $CHECK Main process complete $clear"
Write-Host "Checking online status of failed..."

foreach ( $job in (Get-Job) ) {
    if ( $job.State -eq "Failed" ) {

        $successCount += 1 

        $cStatus = "$fgRed$XMARK$clear Connected"
        $eStatus = $null

        if ( Test-Connection -TargetName $job.Location -Count 1 -Quiet -IPv4 -ErrorAction Ignore ) {
            $clientOnline = $true
            $oStatus = "$fgGreen$CHECK Online$clear"

            $clientIP = [System.Net.Dns]::GetHostByName("$($job.Location)").AddressList[0].IPAddressToString
            $clientFQDN = $clientFQDN = [System.Net.Dns]::GetHostByAddress("$($clientIP)").Hostname -replace "\.corp\.com"

            if ( $clientIP -match '67\.195\.197\.24' ) {
                $iStatus = "$fgRed$XMARK $clientIP$clear"
                $eStatus = "$fgRed$XMARK$clear DNS error"
                $clientDesc = "DNS / offline for very long time"
                if ($firstRun) { Add-Content -Path $clientList -Value "$($job.Location)" }
                Add-Content -Path $reviewList -Value "$($job.Location)"
            }
            elseif ( $clientIP -match '192\.200\..*' ) {
                $iStatus = "$fgRed$XMARK $clientIP$clear"
                $eStatus = "$fgRed$XMARK$clear VPN error"
                $clientDesc = "VPN error"
                if ($firstRun) { Add-Content -Path $clientList -Value "$($job.Location)" }
            }
            elseif ( $clientFQDN -ne $job.Location ) {
                $iStatus = "$fgRed$XMARK $clientIP$clear"
                $eStatus = "$fgRed$XMARK$clear Hostname / IP mismatch"
                $clientDesc = "Hostname / IP mismatch"
                if ($firstRun) { Add-Content -Path $clientList -Value "$($job.Location)" }
            }
            else {
                $iStatus = "$fgGreen$CHECK $clientIP$clear"
                $eStatus = $null
                $clientDesc = "Unknown"
                Add-Content -Path $psremotingClients -Value "$($job.Location)"
                if ($firstRun) { Add-Content -Path $clientList -Value "$($job.Location)" }
            }
        }
        else {
            $clientOnline = $true
            $oStatus = "$fgRed$XMARK$clear Offline"
            $iStatus = $null
            $clientDesc = "Offline"
            if ($firstRun) { Add-Content -Path $clientList -Value "$($job.Location)" }
        }

        $clientError = $true

        if ( $null -ne $iStatus ) {
            Write-Host $hlRed $successCount $clear, $fgRed$($job.Location)$clear`t, $fgRed$XMARK$clear, "Job failed", $oStatus, $iStatus, $cStatus, $eStatus
        }
        else {
            Write-Host $hlRed $successCount $clear, $fgRed$($job.Location)$clear`t, $fgRed$XMARK$clear, "Job failed", $oStatus, $cStatus, $eStatus
        }

        Add-Content -Path $errorlog -Value "`"$($job.Location)`",`"$($clientOnline)`",`"$($clientError)`",`"$($clientDesc)`""
    }
    Remove-Job -Job $job -ErrorAction SilentlyContinue
}

Write-Host "$hlGreen $CHECK All complete @ $(Get-Date -Format "yy-MM-dd_HH:mm:ss") $clear"