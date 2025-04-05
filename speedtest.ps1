param(
    [string]$Server = "29320",
    [int]$ThrottleLimit = 5,
    [switch]$Parallel = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command "Set-ConsoleFont" -ErrorAction SilentlyContinue)) {
    try {
        Install-Module WindowsConsoleFonts -ErrorAction Stop
    } catch {}
}
if (Get-Command "Set-ConsoleFont" -ErrorAction SilentlyContinue) {
    Get-ConsoleFont | Select-Object -ExpandProperty Name | Set-ConsoleFont -Size 5
}

$networkInterfaces = Get-NetIPConfiguration | 
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and 
        $_.NetAdapter.Status -ne "Disconnected"
    }
# Write-Host -ForegroundColor DarkGray "Found $($networkInterfaces.Count) enabled network interfaces"

$interfaceDetails = @()
foreach ($interface in $networkInterfaces) {
    $ipv4Addresses = $interface.IPv4Address.IPAddress
    foreach ($ipv4_ in $ipv4Addresses) {
        $interfaceDetails += @{
            name = "$($interface.InterfaceAlias) ($($interface.InterfaceDescription)): $ipv4_"
            ipv4 = $ipv4_
            server = $server
        }
    }
}

function RunSpeedTest($if) {
    Write-Host -ForegroundColor DarkGray "[$($if.name)] Starting speed test"
    try {
        # $speedTestResult = & 
        speedtest.exe -i $if.ipv4 -s $if.server
        Write-Host "[$($if.name)] Speed test completed" -ForegroundColor Green
        # Write-Host $speedTestResult
    } catch {
        Write-Host "[$($if.name)] Error running speed test: $_" -ForegroundColor Red
    }
}
$funcDef = ${function:RunSpeedTest}.ToString()

$useParallel = ($Parallel -and $($PSVersionTable.PSVersion.Major -ge 7))
if ($useParallel) {
    $interfaceDetails | ForEach-Object -Parallel {
        ${function:RunSpeedTest} = $using:funcDef
        RunSpeedTest $_
    } -ThrottleLimit $ThrottleLimit
} else {
    foreach ($if in $interfaceDetails) {
        RunSpeedTest $if
    }
}