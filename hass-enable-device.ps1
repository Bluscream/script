# PowerShell script to enable all entities of a specific device using Home Assistant API

# Home Assistant API configuration
$haUrl = $env:HASS_SERVER
$longLivedToken = $env:HASS_TOKEN
$deviceId = "your_device_id"

# Headers for API requests
$headers = @{
    "Authorization" = "Bearer $longLivedToken"
    "Content-Type" = "application/json"
}

# Get all entities for the specified device
$entitiesUrl = "$haUrl/api/devices/$deviceId"
$response = Invoke-RestMethod -Uri $entitiesUrl -Headers $headers -Method Get

# Extract entity IDs from the response
$entityIds = $response.entities | ForEach-Object { $_.entity_id }

# Function to enable an entity
function Enable-Entity($entityId) {
    $serviceUrl = "$haUrl/api/services/homeassistant/turn_on"
    $body = @{
        "entity_id" = $entityId
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $serviceUrl -Headers $headers -Method Post -Body $body
    Write-Host "Enabled entity: $entityId"
}

# Iterate over all entities and enable them
foreach ($entityId in $entityIds) {
    Enable-Entity $entityId
}

Write-Host "All entities for device $deviceId have been enabled."
