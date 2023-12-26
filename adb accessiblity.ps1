function Split-OnLastOccurrence {
    param (
        [Parameter(Mandatory=$true)]
        [string]$string,
        
        [Parameter(Mandatory=$true)]
        [string]$delimiter
    )
    
    $splitArray = $string.Split($delimiter)
    $firstPart = $splitArray[0..($splitArray.Length-2)] -join $delimiter
    $lastPart = $splitArray[$splitArray.Length-1]
    
    return $firstPart, $lastPart
 }

function WriteOutput {
    $finalStr = ""
    foreach ($arg in $args) {
        $finalStr += $arg + " "
    }
    Write-Output $finalStr
    # Write-Output ($args | ForEach-Object { $_ } | Join-String " ")
}

function Get-InstalledAccessibilityServices {
    $dumpSys = adb shell dumpsys
    # find lines matching ".*: android.permission.BIND_ACCESSIBILITY_SERVICE", split them by ":" and return the first part and add to new array
    $accessibilityServices = $dumpSys | Where-Object { $_ -match ".*: android.permission.BIND_ACCESSIBILITY_SERVICE" } | ForEach-Object { $_.Split(":")[0] }
    return $accessibilityServices
}

function Get-InstalledAccessibilityServices2 {
    $dumpSys = adb shell dumpsys
    # find line like "android.accessibilityservice.AccessibilityService:" and return the next 50 lines after it
    $accessibilityServices = $dumpSys | Where-Object { $_ -match "android.accessibilityservice.AccessibilityService:" } | Select-Object -First 50
    return $accessibilityServices
}

function Get-EnabledAccessibilityServices {
    $enabledServices = & adb shell settings get secure enabled_accessibility_services
    return $enabledServices -split ":"
}

# create class for installed package containing package name and apk path, make the path be an actual parsed path
class InstalledPackage {
    [string]$PackageName
    [string]$PackagePath
    [string]$PackageFileName
 
    InstalledPackage([string]$PackageLine) {
        $packagePathPart, $this.PackageName = Split-OnLastOccurrence -string $PackageLine -delimiter "="
        $packagePathParts = $packagePathPart.Split(":", 2)
        $this.PackagePath = $packagePathParts[1]
        $this.PackageFileName = $this.GetFileName()
    }

    InstalledPackage([string]$PackageName, [string]$PackagePath) {
        $this.PackageName = $PackageName
        $this.PackagePath = $packagePath
        $this.PackageFileName = $this.GetFileName()
    }
    [void]Pull() {
        & adb pull $this.PackagePath
    }
    [void]Extract() {
        Expand-Archive -Path .\$this.PackageFileName -DestinationPath .\$this.PackageName
    }
    [string]GetFileName() {
        return $this.PackagePath.Split("/")[-1]
    }
    [string]GetManifest() {
        $manifestContent = Get-Content -Path .\$this.PackageName\AndroidManifest.xml
        return $manifestContent
    }
    [void]Cleanup() {
        Remove-Item -Recurse -Force .\$this.PackageName
        Remove-Item -Force .\$this.PackageFileName
    }
 }
 

function Get-InstalledPackages {
    $installedPackages = & adb shell pm list packages -f
    # create empty list of InstalledPackage
    $packages = @()
    # loop through each line
    foreach ($package in $installedPackages) {
        try {
            $installedPackage = [InstalledPackage]::new($package)
            if ($installedPackage.PackageName -eq "" -and $installedPackage.PackagePath -eq "") {
                throw "Failed to parse package: $package"
            }
            $packages += $installedPackage
        } catch {
            Write-Output "Failed to parse package: $package"
        }
    }
    return $packages
}

# Execute ADB commands
$installedPackages = Get-InstalledPackages
# $installedPackages = $installedPackages | Where-Object { $_ -ne "" }
$installedPackages = $installedPackages | Sort-Object -Property PackageName
Write-Output $installedPackages
# exit script
exit
$services = & adb shell dumpsys activity services
$enabledServices = Get-EnabledAccessibilityServices

# Filter installed packages to only show accessibility receivers
$accessibilityReceivers = $installedPackages | Where-Object { $_ -match "receiver" }
$accessibilityServices = $services | Where-Object { $_ -match "AccessibilityService" }

Write-Output ""
Write-Output "Installed accessibility receivers:"

$hass = adb shell dumpsys package io.homeassistant.companion.android
Write-Output $hass
Write-Output(Get-Manifest -PackagePath "/data/app/~~dEMhmXyJulC2gP5b-MWrxA==/io.homeassistant.companion.android-1rP7KjqOlYZeUE5_tcz5ng==/base.apk")

# # Loop through each installed package
# foreach ($package in $installedPackages) {
#     # Get the package name
#     $packageName = $package.Split("=")[1]

#     # skip if name is not io.homeassistant.companion.android
#     if ($packageName -ne "io.homeassistant.companion.android") {
#         continue
#     }
   
#     # Get package details
#     $packageDetails = & adb shell dumpsys package $packageName
#     Write-Output $packageDetails
   
#     # Check if the package has accessibility service
#     if ($packageDetails -match "AccessibilityService") {
#         # Write lines that contain accessibility service
#         $packageDetails | Where-Object { $_ -match "AccessibilityService" } | ForEach-Object {
#             Write-Output $_
#           }
#     }
#    }

# # Loop through each installed package
# foreach ($package in $installedPackages) {
#     # Get the package name
#     $packageName = $package.Split("=")[1]
   
#     # Pull the APK file
#     & $adbPath pull /data/app/$packageName.apk
   
#     # Unzip the APK file
#     Expand-Archive -Path .\$packageName.apk -DestinationPath .\$packageName
   
#     # Read the manifest file
#     $manifestContent = Get-Content -Path .\$packageName\AndroidManifest.xml
   
#     # Print the manifest content
#     Write-Output $manifestContent
   
#     # Delete the extracted files
#     Remove-Item -Recurse -Force .\$packageName
#     Remove-Item -Force .\$packageName.apk
#    }

Write-Output ""
Write-Output "Enabled services:"
$enabledServices -split ":" | ForEach-Object {
    Write-Output $_
  }