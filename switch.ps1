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
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($level.ToLower()) {
        "warn" { Write-Warning "[$date] Warning: $message" }
        "warning" { Write-Warning "[$date] Warning: $message" }
        "error" { Write-Host "[$date] Error: $message" -ForegroundColor Red}
        "debug" { if ($debug) { Write-Host "[$date] $message" -ForegroundColor Blue } }
        "success" { Write-Host "[$date] ✅ $message" -ForegroundColor Green }
        default { Write-Host "[$date] $message" }
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
# SIG # Begin signature block
# MIIbwgYJKoZIhvcNAQcCoIIbszCCG68CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCFP3BIvAqgiBHA
# TpDWE/bLY5QfRB33nNTxykPCJHbzhqCCFhMwggMGMIIB7qADAgECAhBpwTVxWsr9
# sEdtdKBCF5GpMA0GCSqGSIb3DQEBCwUAMBsxGTAXBgNVBAMMEEFUQSBBdXRoZW50
# aWNvZGUwHhcNMjMwNTIxMTQ1MjUxWhcNMjQwNTIxMTUxMjUxWjAbMRkwFwYDVQQD
# DBBBVEEgQXV0aGVudGljb2RlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAoYBnOJ64OauwmbLN3bJ4EijORLohvNN3Qbjxxo/mTvQqqOLNAezk/A08LVg0
# GjQBR7L6LK/gnIVyeQxW4rKiLyJrS+3sBb+H6rTby5jiVBJmjiULxiVDEB+Fyz4h
# JGCWrn0BGGH4aLYfSdtlOD1sc0ySQuEuixZMV9dZIckNxYmJoeeLrwvnfio34ngy
# qxRY6lzULq9oTYoRTFSNxpb13mfZLhxz2pOzbEKBmYkbrDj4JtSzwBggly04oJXM
# ZZSRNavH6ZHxOUhs1UMgFHBe8dpepTBHY2uFjcynJaA5K02Yf2JAzfwc7A/tyuAM
# XNpK11pZ8aurlGws0W3TJtA6VQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFIrvKx60YqR0ov787AjXn8zIl/36
# MA0GCSqGSIb3DQEBCwUAA4IBAQCdF+EBLn7mIQdZlfOFrJyarvy8SIaWcPUPVZPW
# ZdOH3U/HeANjbhPIZIbrmlB/uSqfoCOjKcqP1/wT1uHA8HdDkMC+WmWT0PpVBtr8
# W/dxgGc531Ykli1qn7qh8pKqQvSBC42cn3iX9KuN8yguyUIoxyATBBnJb/9a+nMA
# 3u8W3tF7gVwvvCETEE0cM8R6LY5/DjT5NRmo090lx/w8io//t0ZjyHuf9sY0CxLP
# 56MZgI/EIZq/M+LIX4WsYTvp3vkmcFDfhgEV8BVqKzPT/sKjKq61PED2jCjLj7L5
# Fdo8ip3XaTURhXg1syUHbSYOnCinoiT4AHIYJYrx+flT+9ecMIIFjTCCBHWgAwIB
# AgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIw
# ODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Y
# q3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lX
# FllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxe
# TsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbu
# yntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I
# 9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmg
# Z92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse
# 5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKy
# Ebe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwh
# HbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/
# Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwID
# AQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM
# 3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYD
# VR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+
# MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUA
# A4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSI
# d229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7U
# z9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxA
# GTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAID
# yyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW
# /VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0o
# ZipeWzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhE
# aWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIy
# MjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# OzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGlt
# ZVN0YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1
# BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3z
# nIkLf50fng8zH1ATCyZzlm34V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZ
# Kz5C3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald6
# 8Dd5n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zk
# psUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYn
# LvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIq
# x5K/oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOd
# OqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJ
# TYsg0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJR
# k8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEo
# AA6EVO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8G
# A1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjAT
# BgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYD
# VR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9
# bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0T
# zzBTzr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYS
# lm/EUExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaq
# T5Fmniye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl
# 2szwcqMj+sAngkSumScbqyQeJsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1y
# r8THwcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05
# et3/JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6um
# AU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSwe
# Jywm228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr
# 7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYC
# JtnwZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzga
# oSv27dZ8/DCCBsIwggSqoAMCAQICEAVEr/OUnQg5pr/bP1/lYRYwDQYJKoZIhvcN
# AQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTsw
# OQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVT
# dGFtcGluZyBDQTAeFw0yMzA3MTQwMDAwMDBaFw0zNDEwMTMyMzU5NTlaMEgxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEgMB4GA1UEAxMXRGln
# aUNlcnQgVGltZXN0YW1wIDIwMjMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQCjU0WHHYOOW6w+VLMj4M+f1+XS512hDgncL0ijl3o7Kpxn3GIVWMGpkxGn
# zaqyat0QKYoeYmNp01icNXG/OpfrlFCPHCDqx5o7L5Zm42nnaf5bw9YrIBzBl5S0
# pVCB8s/LB6YwaMqDQtr8fwkklKSCGtpqutg7yl3eGRiF+0XqDWFsnf5xXsQGmjzw
# xS55DxtmUuPI1j5f2kPThPXQx/ZILV5FdZZ1/t0QoRuDwbjmUpW1R9d4KTlr4HhZ
# l+NEK0rVlc7vCBfqgmRN/yPjyobutKQhZHDr1eWg2mOzLukF7qr2JPUdvJscsrdf
# 3/Dudn0xmWVHVZ1KJC+sK5e+n+T9e3M+Mu5SNPvUu+vUoCw0m+PebmQZBzcBkQ8c
# tVHNqkxmg4hoYru8QRt4GW3k2Q/gWEH72LEs4VGvtK0VBhTqYggT02kefGRNnQ/f
# ztFejKqrUBXJs8q818Q7aESjpTtC/XN97t0K/3k0EH6mXApYTAA+hWl1x4Nk1nXN
# jxJ2VqUk+tfEayG66B80mC866msBsPf7Kobse1I4qZgJoXGybHGvPrhvltXhEBP+
# YUcKjP7wtsfVx95sJPC/QoLKoHE9nJKTBLRpcCcNT7e1NtHJXwikcKPsCvERLmTg
# yyIryvEoEyFJUX4GZtM7vvrrkTjYUQfKlLfiUKHzOtOKg8tAewIDAQABo4IBizCC
# AYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1Ud
# IwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSltu8T5+/N0GSh
# 1VapZTGj3tXjSTBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5n
# Q0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1w
# aW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCBGtbeoKm1mBe8cI1PijxonNgl
# /8ss5M3qXSKS7IwiAqm4z4Co2efjxe0mgopxLxjdTrbebNfhYJwr7e09SI64a7p8
# Xb3CYTdoSXej65CqEtcnhfOOHpLawkA4n13IoC4leCWdKgV6hCmYtld5j9smViuw
# 86e9NwzYmHZPVrlSwradOKmB521BXIxp0bkrxMZ7z5z6eOKTGnaiaXXTUOREEr4g
# DZ6pRND45Ul3CFohxbTPmJUaVLq5vMFpGbrPFvKDNzRusEEm3d5al08zjdSNd311
# RaGlWCZqA0Xe2VC1UIyvVr1MxeFGxSjTredDAHDezJieGYkD6tSRN+9NUvPJYCHE
# Vkft2hFLjDLDiOZY4rbbPvlfsELWj+MXkdGqwFXjhr+sJyxB0JozSqg21Llyln6X
# eThIX8rC3D0y33XWNmdaifj2p8flTzU8AL2+nCpseQHc2kTmOt44OwdeOVj0fHMx
# VaCAEcsUDH6uvP6k63llqmjWIso765qCNVcoFstp8jKastLYOrixRoZruhf9xHds
# FWyuq69zOuhJRrfVf8y2OMDY7Bz1tqG4QyzfTkx9HmhwwHcK1ALgXGC7KP845VJa
# 1qwXIiNO9OzTF/tQa/8Hdx9xl0RBybhG02wyfFgvZ0dl5Rtztpn5aywGRu9BHvDw
# X+Db2a2QgESvgBBBijGCBQUwggUBAgEBMC8wGzEZMBcGA1UEAwwQQVRBIEF1dGhl
# bnRpY29kZQIQacE1cVrK/bBHbXSgQheRqTANBglghkgBZQMEAgEFAKCBhDAYBgor
# BgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCAw
# Ii6B5hWDdyK2JvNDHs62nYXDxmk1lXVJrDn6jgJN1zANBgkqhkiG9w0BAQEFAASC
# AQCDEOZNKRsj+6R/qQiLd0FYZgIUUj0q+vzzx4xnoAGjL4t5brrDGg7MitjEo+o5
# PVP00NGpfMCY83SX4OKpF1WetO+pNNxf4iKB419ueSC3coEroHdwtWkP82uJFC95
# v6mkh4SToZBSnHn76Xb9ELu4JUVkoAwJnNdwHWyYQCrkhIZbLW1fC0M6KTCEmwAO
# ZLvcyPDYdm+EDqyQbgHmPCi6NnCSJJdCrR/ned8ZkS5l0u7jLCvSAmGV6X+ZJAnN
# rQRzEIaSEv9sBRrUrML6gFf/tPtpXp+POurzDbTloMcYwU6XwhkVV+C2zebHjSMC
# 8E68+vKEEVMoDx+Z6MPiMVoqoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEB
# MHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYD
# VQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFt
# cGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEFAKBpMBgGCSqG
# SIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0MDUxNTE5MTg0
# NFowLwYJKoZIhvcNAQkEMSIEIFL1L0jkcTO7Raz1vQHZyydgQOKHZfPPt3icP6Td
# LrmwMA0GCSqGSIb3DQEBAQUABIICAD1+D5ME5OHt9/bq68c9LvH1rbFq8/vjjz4N
# d9+00cUvCLlsRO95PsrLppLHQYRZAwUn/IBel3ItYceSR5Ep+NmkXRpvA7iPMKxe
# rRcwJ1reBFx42hje5FJGpzA+nQO4cD4tBw1xZOteCC+NhAEK/sji2NcB08BLSN3J
# WZa95OEG/pIAzu0uYj3tjKexwNFcmd9mEhY307CvStObH0+p8vmAniX/8Ke2bmff
# 8bLq0N7fQNVck2T4gkLJtxAFiKow12sJbRQsAgRpaaB8eRSnpwIA+dKCzQhJ/o6k
# x8Mzfuknmmnj/pf2bIQ8g5rNWwp2eZtt0eGTIQ7gr1RnzbfwNJ5w42H0OzOkBTer
# KiZDhAtFjfVbCw+J167Vj+dt9dWxTE/dnCLG1ZO0Xj2JoKBGbAlMyz5qCDC/+Nxc
# cxag4VfGJImOKKX5PaSXhPlCdozmWFH28TnV1sxGW7GUOTy3f/lC4rZdmLeQC5ze
# Uqx56JxyLhI2yiGRkZMhCg1dibpCptIxh6cqfZeYgVq4tDu4afhgnN7/xhmgVIav
# 58KgO1eAewGvG52V0W0F3Ui7KfbRpRf7x17iU2lBwm3RH5Tvrhdf7o/Yxu4XvRD3
# F1GIfE+8W3PW0S7ZBpGFbTSb+JXShTv4C6P2vBhJKD2M9A0UuX/q8+j7nBvqhCw5
# YH3qZW0U
# SIG # End signature block
