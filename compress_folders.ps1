param(
    # [Parameter()]
    # [string]$folderPath,
    # [Parameter()]
    # [string[]]$folderPaths
) # ValueFromRemainingArguments=$true Mandatory=$true ValueFromRemainingArguments=$true

$scriptArgs = $MyInvocation.BoundParameters
$argStr = $scriptArgs.GetEnumerator() | ForEach-Object { "-$($_.Key) ""$($_.Value)""" } | ForEach-Object { $_ -join " " }
$scriptPath = $MyInvocation.MyCommand.Path
$scriptName = $MyInvocation.MyCommand.Name
$scriptNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
$workDir = Split-Path -Path $(Get-Location) -Parent
$logPath = Join-Path -Path $workDir -ChildPath "$scriptNameNoExt.log"

function Log {
    param(
        [string]$message,
        [string]$level = "Info"
    )
    # $message = "$($scriptName): $message"
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($level.ToLower()) {
        "warn" { Write-Warning "[$date] Warning: $message" }
        "warning" { Write-Warning "[$date] Warning: $message" }
        "error" { Write-Host "[$date] Error: $message" -ForegroundColor Red}
        "debug" { if ($debug) { Write-Host "[$date] $message" -ForegroundColor Blue } }
        "success" { Write-Host "[$date] ✅ $message" -ForegroundColor Green }
        default { Write-Host "[$date] $message" }
    }
    
    Add-Content -Path $logPath -Value "[$date] $message"
}

Log "Script: ""$scriptPath"" $argStr $args"
Log "Working Directory: ""$workDir"""

# if ($folderPath -and $folderPaths) {
#     Wait "Both folderPath and folderPaths are set. Please provide only one of them."
#     exit 1
# } elseif (-not $folderPath -and -not $folderPaths) {
#     Wait "Neither folderPath nor folderPaths are set. Please provide one of them."
#     exit 1
# } elseif ($folderPath) {
#     $folderPaths = @($folderPath)
# }

$folderPaths = $args

Log "Compressing $(($folderPaths | Measure-Object).Count) folders"

foreach ($folderPath in $folderPaths) {
    if ($folderPath -match "^file:///") {
        $uri = New-Object System.Uri($folderPath)
        $folderPath = $uri.LocalPath
    }
    if (-not (Test-Path $folderPath)) {
        Log "Folder $folderPath does not exist"
        continue
    }
    if (-not (Test-Path -PathType Container $folderPath)) {
        Log "Path $folderPath is not a folder"
        continue
    }
    if (-not (Get-ChildItem -Path $folderPath)) {
        Log "Folder $folderPath is empty"
        continue
    }
    $folderSize = (Get-ChildItem -Path $folderPath -Recurse | Measure-Object -Property Length -Sum).Sum
    $folderSizeReadableMB = [math]::Round($folderSize / 1MB, 2)
    $zipName = "$(Split-Path $folderPath -Leaf).zip"
    $zipPath = Join-Path -Path (Split-Path $folderPath) -ChildPath $zipName
    Log "Compressing $folderPath ($($folderSizeReadableMB)MB)  into $zipPath"
    Compress-Archive -Path "$folderPath\*" -DestinationPath $zipPath -CompressionLevel Optimal
    $zipSize = (Get-Item -Path $zipPath).Length
    $zipSizeReadableMB = [math]::Round($zipSize / 1MB, 2)
    $sizeDiff = $folderSize - $zipSize
    $sizeDiffReadableMB = [math]::Round($sizeDiff / 1MB, 2)
    $sizeReduction = [math]::Round(($sizeDiff) / $folderSize * 100, 2)
    Log "Compressed by $($sizeDiffReadableMB)MB ($sizeReduction%) into $zipPath ($($zipSizeReadableMB)MB)"
}

Log "Done compressing $(($folderPaths | Measure-Object).Count) folders"
Start-Sleep -Seconds 15