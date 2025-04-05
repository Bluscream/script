# Set the start and end IP addresses
$ipPrefix = "192.168.2."
$startDate = 1
$endDate = 255
$currentIP = $startDate

# Set the port number
$portNumber = 8006

# Set the timeout in seconds
$timeoutSeconds = 2

while ($true) {
    # Loop through each IP in the range
    for ($currentIP = $startDate; $currentIP -le $endDate; $currentIP++) {
        try {
            $fullIP = $ipPrefix + $currentIP
            # Attempt to connect to the port
            $result = (New-Object System.Net.Sockets.TcpClient).ConnectAsync($fullIP, $portNumber).Wait(150)
            # $result = Test-NetConnection -ComputerName $fullIP -Port $portNumber -WarningAction SilentlyContinue -ErrorAction Stop -Timeout 10000
            Write-Host $result
            # Check if the port is open and responding
            if ($result) { # .TcpTestSucceeded
                Write-Host "$($fullIP):$portNumber is open and responding."
                return
            } else {
                Write-Host "$($fullIP):$portNumber is closed or filtered."
            }
            
            # Add a small delay to avoid overwhelming the network
            # Start-Sleep -Milliseconds 500
        }
        catch {
            # Handle any exceptions (e.g., unreachable hosts)
            Write-Host "Unable to reach $fullIP"
        }
    }
    
    # Add a larger delay between full scans
    Start-Sleep -Seconds 1
}
