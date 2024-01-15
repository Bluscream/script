# Define the IP addresses to ping
$ipAddresses = @('192.168.2.1', '192.168.2.4', '192.168.2.38', '8.8.8.8')

# Continuously ping the IP addresses
while ($true) {
    $results = @()
    foreach ($ip in $ipAddresses) {
        $result = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
        $ping = "Failed"
        if ($result.Status -eq "Success") {
            $ping = $result.Latency
        } else {
            $ping = $result.Status
        }
        $results += New-Object PSObject -Property @{
            IPAddress = $ip
            Ping = $ping
        }
    }
    Clear-Variable result
    $results | Select-Object IPAddress, Ping | Format-Table -AutoSize
    Start-Sleep -Seconds 1
}
