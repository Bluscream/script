# Elevate the script to run as an administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script elevated"
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Retrieve all event log names
$LogNames = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LogName
Write-Host "Found $($LogNames.Count) event logs"

# Iterate through each log name and clear it
foreach ($LogName in $LogNames) {
    $txt = "Clearing $LogName"
    $logSizeMB = -1
    try {
        $fistLogEvent = Get-WinEvent -LogName $LogName -MaxEvents 1 --ErrorAction SilentlyContinue
        $logSizeMB = $fistLogEvent.MaximumSizeInBytes / 1MB
        $txt += " ($logSizeMB MB)"
    } catch { }
    Write-Host $txt
    try {
        # Clear the event log
        wevtutil.exe cl "$LogName"
    } catch {
        # Handle any errors that occur during the process
        Write-Host "Failed to clear $LogName. Error: $_"
    }
}

Write-Host "Event logs cleared"
