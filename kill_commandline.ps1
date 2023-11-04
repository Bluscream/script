param (
    [string]$PartialCommandLine
)

if ([string]::IsNullOrEmpty($PartialCommandLine)) {
    $processes = Get-Process | Select-Object Name, Id, CommandLine
    $processes | Format-Table -AutoSize
} else {
    $processes = Get-Process | Where-Object { $_.CommandLine -like "*$PartialCommandLine*" }

    if ($processes.Count -eq 0) {
        Write-Host "No processes found matching the command line: $PartialCommandLine"
    } else {
        foreach ($process in $processes) {
            $process | Stop-Process -Force
            Write-Host "Killed process with name $($process.Name), ID $($process.Id) and command line: $($process.CommandLine)"
        }
    }
}
