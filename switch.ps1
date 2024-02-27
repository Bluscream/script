param(
    [string]$version = "",
    [bool]$switch = $true,
    [switch]$force = $false,
    [switch]$killGame = $false,
    [switch]$ignoreRunning = $false,
    [switch]$startGame = $false,
    [string]$gameExe = "iw4x.exe",
    [string]$gameArgs = "-disable-notifies -unprotect-dvars -multiplayer -scriptablehttp -console -nointro +set logfile 0",
    [string]$basePath = (Get-Location).Path,
    [switch]$debug = $false,
    [switch]$help
)

$gameProcessName = $gameExe -split "\." | Select-Object -First 1
$success = $false
$scriptArgs = $MyInvocation.BoundParameters
$argStr = $scriptArgs.GetEnumerator() | ForEach-Object { "-$($_.Key) ""$($_.Value)""" } | ForEach-Object { $_ -join " " }
$scriptPath = $MyInvocation.MyCommand.Path
# $scriptName = $MyInvocation.MyCommand.Name
$gamePath = Join-Path $basePath $gameExe
$versions = @{}

function Log {
    param(
        [string]$message,
        [string]$level = "Info"
    )
    # $message = "$($scriptName): $message"
    switch ($level.ToLower()) {
        "warn" { Write-Warning "[$(Get-Date)] Warning: $message" }
        "warning" { Write-Warning "[$(Get-Date)] Warning: $message" }
        "error" { Write-Host "[$(Get-Date)] Error: $message" -ForegroundColor Red}
        "debug" { if ($debug) { Write-Host "[$(Get-Date)] $message" -ForegroundColor Blue } }
        "success" { Write-Host "[$(Get-Date)] ✅ $message" -ForegroundColor Green }
        default { Write-Host "[$(Get-Date)] $message" }
    }
}

function Convert-JsonToPowershellArray {
    param(
        [Parameter(Mandatory=$true)]
        [string]$JsonFilePath
    )
    $jsonContent = Get-Content -Path $JsonFilePath -Raw
    $jsonObject = $jsonContent | ConvertFrom-Json
    $convertedArray = @{}
    foreach ($key in $jsonObject.PSObject.Properties.Name) {
        $convertedArray[$key] = @{}
        foreach ($subKey in $jsonObject.$key.PSObject.Properties.Name) {
            $convertedArray[$key][$subKey] = $jsonObject.$key.$subKey
        }
    }
    return $convertedArray
}
function Get-Versions {
    $versions = @{}
    $versionsPath = Join-Path $basePath "versions.json"
    $versionsItem = Get-Item -Path $versionsPath -ErrorAction SilentlyContinue
    if ($versionsItem) {
        try {
            $versions = Convert-JsonToPowershellArray -JsonFilePath $versionsPath
            Log "Read $($versions.Count) versions from $versionsPath" -level "Info"
            return $versions
        } catch {
            Log "Error reading or converting JSON file: $_" -level "Error"
        }
    }

    $versionsPath = Join-Path $basePath "versions.ps1"
    $versionsItem = Get-Item -Path $versionsPath -ErrorAction SilentlyContinue
    if ($versionsItem) {
        . $versionsPath
        Log "Read $($versions.Count) versions from $versionsPath" -level "Info"
        return $versions
    }
    Log "Could not read versions from any source (json, ps1), falling back to hardcoded" -level "Error"
    return @{
        "latest" = @{
            "iw4x.dll" = "iw4x_latest.dll"
        }
        "r4432" = @{
            "iw4x.dll" = "iw4x_r4432.dll"
        }
    }
}
$versions = Get-Versions
function List-Versions {
    Log "Available versions:"
    $versions.Keys | ForEach-Object { Log " - $_" }
}

function Show-Help {
    Invoke-Expression "Get-Help ""$scriptPath"" -detailed"
}

function Get-Current-Version {
    $currentVersion = "Unknown"
    foreach ($version in $versions.Keys) {
        $firstItem = $versions[$version].Keys | Select-Object -First 1
        $targetPath = Join-Path $basePath $firstItem
        $targetItem = Get-Item -Path $targetPath -ErrorAction SilentlyContinue
        if ($targetItem) {
            $sourcePath = $targetItem.Target
            $sourceVersion = $sourcePath -split "_" | Select-Object -Last 1
            $sourceVersion = $sourceVersion -split "\." | Select-Object -First 1
            Log "Found symlink for $firstItem ($targetItem): $sourceVersion ($sourcePath)" -level "Debug"
            if (-not $sourceVersion -eq "") {
                $currentVersion = $sourceVersion
            }
            break
        }
    }
    return $currentVersion
}
$currentVersion = Get-Current-Version

function Kill-Game {
    $runningProcesses = Get-Process | Where-Object { $_.ProcessName -eq $gameProcessName }
    if ($runningProcesses.Count -gt 0) {
        Log "Killing $gameProcessName..." -level "Warning"
        Stop-Process -Name $gameProcessName
        Start-Sleep -Seconds 1
    }
}
function Create-Symlink {
    param(
        [string]$sourcePath,
        [string]$targetPath
    )
    $targetIsFolder = $targetPath -notmatch "\."
    $targetType = if ($targetIsFolder) { "folder" } else { "file" }
    $sourceItem = Get-Item -Path $sourcePath -ErrorAction SilentlyContinue
    if (-not $sourceItem) {
        Log "Source $sourcePath does not exist." -level "Error"
        return $false
    }
    if ($sourceItem.LinkType -eq "SymbolicLink") {
        Log "Source $sourcePath is already a symlink." -level "Error"
        return $false
    }
    $targetItem = Get-Item -Path $targetPath -ErrorAction SilentlyContinue
    $goodTarget = if ($targetItem) { $targetItem.LinkType -eq "SymbolicLink" } else { $true }
    if (-not $goodTarget) {
        Log "Target $targetPath exists, but is not a symlink." -level "Error"
        return $false
    }
    if ($targetItem) {
        Log "Removing old target $targetPath"
        Remove-Item $targetPath
    }
    Log "Symlinking $targetType $sourcePath to $targetPath"

    # New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force
    $mkargs = "/c mklink"
    $mkargs += if ($targetIsFolder) { " /D" } else { "" }
    $mkargs += " ""$targetPath"" ""$sourcePath"""
    Log "cmd $mkargs" -level "Debug"
    $process = Start-Process -FilePath "cmd" -ArgumentList $mkargs -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        Log "Failed to create symlink from $sourcePath to $targetPathh" -level "Error"
        return $false
    }
    return $true
}

function Switch-GameVersion {
    param(
        [string]$version
    )
    if (-not $ignoreRunning) {
        $runningProcesses = Get-Process | Where-Object { $_.ProcessName -eq $gameProcessName }
        if ($runningProcesses.Count -gt 0) {
            if ($killGame) {
                Kill-Game
            } else {
                Log "Error: $gameExe is running. Please close it before switching versions or use -killGame to close it automatically."
                $userInput = Read-Host "Kill $gameExe? (y/n)"
                if ($userInput -eq "y") {
                    Kill-Game
                } else {
                    return $false
                }
            }
        }
    }
    if (-not $versions.ContainsKey($version)) {
        Log "Version $version does not exist."
        List-Versions
        return $false
    }
    if ($currentVersion -eq $version -and -not $force) {
        Log "Already on version $version."
        return $true
    }
    if (-not $switch) {
        Log "Switching is disabled by ""-switch false""." -level "Error"
        return $false
    }
    foreach ($target in $versions[$version].Keys) {
        $targetPath = Join-Path $basePath $target
        $sourcePath = Join-Path $basePath $versions[$version][$target]
        Create-Symlink -sourcePath $sourcePath -targetPath $targetPath
    }
    Log "Switched to version $version." -level "Success"
    return $true
}

Log "Script: ""$scriptPath"" $argStr $args" -level "Debug"
Log "Game: ""$gamePath"" $gameArgs" -level "Debug"
Log "Path: $basePath" -level "Debug"
if ($currentVersion -eq "Unknown") {
    Log "Detected game version: $currentVersion" -level "Warning"
} else {
    Log "Detected game version: $currentVersion" -level "Success"
}
if ($help) {
    Show-Help
    return
} elseif ($version -ne "") {
    # If version is provided as an argument, use it
    $success = Switch-GameVersion -version $version
} elseif ($args.Count -eq 1 -and $args[0] -ne "") {
    # If arguments are provided, use the first one as the version
    $version = $args[0]
    $success = Switch-GameVersion -version $version
} else {
    # If no arguments, prompt the user to select a version
    List-Versions
    $userInput = Read-Host "Version"
    if ($userInput -ne "") {
        $version = $userInput
        $success = Switch-GameVersion -version $version
    } else { Log "No version selected." -level "Error" }
}
if (-not $success) {
    Log "Failed to switch to version $version." -level "Error"
} else {
    if ($startGame) {
        Log "Starting $gameExe $gameArgs"
        Start-Process -FilePath $gamePath -ArgumentList $gameArgs
    }
}