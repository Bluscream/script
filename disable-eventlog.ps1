
# Define the keywords to match against
$Keywords = 'telemetry', 'analytics', 'diag'

# Get all event logs
$Logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue

# Loop through each log
foreach ($Log in $Logs) {
    # Check if the log name contains any of the keywords (case-insensitive)
    if ($Log.LogName -imatch ($Keywords -join '|')) {
        # Debug print before attempting to disable the log
        Write-Host "Attempting to disable log: $($Log.LogName)"
        
        # Disable the log
        try {
            wevtutil sl "$($Log.LogName)" /e:false
            Write-Host "Successfully disabled log: $($Log.LogName)"
        } catch {
            Write-Host "Failed to disable $($Log.LogName). Error: $_"
        }

        # Debug print before attempting to delete the log
        Write-Host "Attempting to delete log: $($Log.LogName)"
        
        # Delete the log
        try {
            Remove-Item -Path "HKLM:\System\CurrentControlSet\Services\EventLog\Application\$($Log.LogName)" -Recurse -Force
            Write-Host "Successfully deleted log: $($Log.LogName)"
        } catch {
            Write-Host "Failed to delete $($Log.LogName) registry key. Error: $_"
        }
    } else {
        # Debug print for logs that don't match the keywords
        Write-Debug "No match found for keywords in log: $($Log.LogName)"
    }
}
