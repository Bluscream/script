function Get-AllAvailableWiFiNetworks {
    param (
        [Parameter(Mandatory=$false)]
        [int]$TopResults = 10
    )

    # Get all network interfaces
    $interfaces = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*802.11*"}

    # Initialize array to store results
    $results = @()

    # Loop through each interface
    foreach ($interface in $interfaces) {
        try {
            # Get IP configuration for the interface
            $ipConfig = Get-NetIPAddress -InterfaceAlias $interface.InterfaceAlias | Where-Object {$_.AddressFamily -eq "IPv4"} | Select-Object IPAddress, PrefixLength, DefaultGateway

            # Get link-local IPv6 address
            $ipv6LinkLocal = Get-NetIPAddress -InterfaceAlias $interface.InterfaceAlias -AddressFamily IPv6 | Where-Object {$_.PrefixOrigin -eq "Manual"} | Select-Object IPAddress

            # Get network profile name
            $networkProfile = (Get-NetAdapter -InterfaceAlias $interface.InterfaceAlias).Status

            # Get SSID (if applicable)
            $ssid = (Get-NetAdapter | Where-Object {$_.InterfaceDescription -eq $interface.InterfaceDescription}).Description

            # Create custom object with all collected information
            $result = [PSCustomObject]@{
                InterfaceName = $interface.Name
                Description = $interface.Description
                SSID = $ssid
                IPv4Address = $ipConfig.IPAddress
                IPv4SubnetMask = $ipConfig.SubnetMask
                IPv4DefaultGateway = $ipConfig.DefaultGateway
                IPv6Address = $ipv6LinkLocal.IPAddress
                NetworkProfile = $networkProfile
            }

            # Add result to the array
            $results += $result
        }
        catch {
            Write-Warning "Error processing interface $($interface.InterfaceAlias): $_"
        }
    }

    # Sort results by signal strength (if available)
    $sortedResults = $results | Sort-Object -Property @{
        Name = "OverallScore";
        Expression = {
            if ([string]::IsNullOrEmpty($_.SSID)) {0} else {
                $adapter = Get-NetAdapter | Where-Object {$_.Description -eq $_.SSID}
                if ($adapter) {
                    $adapter.LinkSpeed
                } else {
                    0
                }
            }
        };
        Descending = $true
    }

    # Return top N results
    return $sortedResults | Select-Object -First $TopResults
}

# Example usage:
$wifiNetworks = Get-AllAvailableWiFiNetworks -TopResults 20
$wifiNetworks | Format-Table -AutoSize
