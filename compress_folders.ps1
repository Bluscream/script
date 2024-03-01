param(
    # [Parameter()]
    # [string]$folderPath,
    # [Parameter()]
    # [string[]]$folderPaths
) # ValueFromRemainingArguments=$true Mandatory=$true ValueFromRemainingArguments=$true
$scriptArgs = $MyInvocation.BoundParameters
$argStr = $scriptArgs.GetEnumerator() | ForEach-Object { "-$($_.Key) ""$($_.Value)""" } | ForEach-Object { $_ -join " " }
$scriptPath = $MyInvocation.MyCommand.Path
Write-Host "Script: ""$scriptPath"" $argStr $args"

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

foreach ($folderPath in $folderPaths) {
    if ($folderPath -match "^file:///") {
        $uri = New-Object System.Uri($folderPath)
        $folderPath = $uri.LocalPath
    }
    $zipName = "$(Split-Path $folderPath -Leaf).zip"
    $zipPath = Join-Path -Path (Split-Path $folderPath) -ChildPath $zipName
    Write-Output "Compressing $folderPath into $zipPath"
    Compress-Archive -Path "$folderPath\*" -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Output "Compressed $folderPath into $zipPath"
}

Write-Output "Press any key to finish..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Start-Sleep -Seconds 5