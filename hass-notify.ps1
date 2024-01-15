$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Write-Output $session

$url = "http://192.168.2.4:8123/api/services/notify/all_devices"
Write-Output $url

$body = @{
  # "target" = @("all")
  "data" = @{
    "title" = $args[1]
    "message" = $args[0]
  }
} # | ConvertTo-Json
Write-Output $body
$body_json = $body | ConvertTo-Json
Write-Output $body_json

$headers = @{
    "Authorization"="Bearer "
}
Write-Output $headers


$response = Invoke-WebRequest -UseBasicParsing -Uri $url -Method "POST" -WebSession $session -Headers $headers -ContentType "application/json;charset=UTF-8" -Body $body_json

Write-Output $response