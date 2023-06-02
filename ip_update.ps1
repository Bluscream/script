# $networkInterfaces = Get-NetAdapter | Where-Object { $_.PhysicalMediaType -eq '802.3' }
$networkInterfaces = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
$ips = $networkInterfaces.IPAddress -join ","
$macs = $networkInterfaces.MacAddress -join ","

$hosts = @("http://minopia.de", "http://local.minopia.de", "http://remote.minopia.de", "http://192.168.2.38", "http://192.168.2.39")

foreach ($_host in $hosts) {
    $url = "$_host/api/ip.php?name=bluscream-pc&domains=bluscream.pc,timo.pc,gaming.pc&ips=$ips&macs=$macs"
    Write-Host $url
    $response = Invoke-WebRequest -Uri $url -TimeoutSec 30 2>&1
    Write-Host $response
    if ($response -notmatch "Operation timed out") {
        break
    }
}