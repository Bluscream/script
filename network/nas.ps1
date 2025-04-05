$name = "NAS"
$description = "Realtek PCIe 2.5GbE Family Controller"

# Get the network adapter
$adapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -eq $description }

# Check if adapter exists
if ($null -eq $adapter) {
    Write-Error "Network adapter '$description' not found!"
    exit
}

# Disable IPv6
Write-Host "Disabling IPv6..."
Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6

# Configure IPv4 settings
Write-Host "Configuring IPv4 settings..."
$ipv4Properties = @{
    InterfaceIndex = $adapter.InterfaceDescription
    AddressFamily  = IPv4
}
New-NetIPAddress @ipv4Properties -IPAddress "192.168.1.49" -PrefixLength 24

# Display confirmation
Write-Host "Configuration complete! Verifying settings..."
Get-NetAdapterBinding -Name $adapter.Name | Where-Object { $_.ComponentID -like "*ipv6*" } | Select-Object Name, Enabled
Get-NetIPAddress -InterfaceDescription $adapter.InterfaceDescription -AddressFamily IPv4 | Select-Object IPAddress, PrefixLength