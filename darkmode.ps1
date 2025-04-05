# Enable Dark Mode for All Users.ps1

# Define the registry paths and values needed for dark mode
$registryPath = "Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$systemKey = "SystemUsesLightTheme"
$appsKey = "AppsUseLightTheme"
$darkValue = 0  # 0 enables dark mode, 1 enables light mode

# Function to enable dark mode for a single user
function Set-DarkModeForUser {
    param($username)
    
    $sid = (Get-WmiObject Win32_UserProfile | Where-Object LocalPath -like "*$username*").SID
    
    if ($sid) {
        Write-Host "Processing user: $username"
        
        try {
            # Load the user's registry hive
            reg load "HKU\$sid" "C:\Users\$username\NTUSER.DAT"
            
            # Construct the full path
            $regPathFull = "HKU:$sid\$registryPath"
            
            # Create the Personalize key if it doesn't exist
            if (-not (Test-Path $regPathFull)) {
                New-Item -Path $regPathFull -Force | Out-Null
                Write-Host "Created missing Personalize key for $username"
            }
            
            # Create and set both properties
            $props = @{
                Path        = $regPathFull
                Name        = $systemKey
                Value       = $darkValue
                PropertyType = 'DWORD'
                Force       = $true
            }
            
            New-ItemProperty @props | Out-Null
            
            $props.Name = $appsKey
            New-ItemProperty @props | Out-Null
            
            Write-Host "Successfully enabled dark mode for user: $username"
            
        }
        catch {
            Write-Warning "Failed to configure dark mode for user $username : $_"
        }
        finally {
            reg unload "HKU\$sid" | Out-Null
        }
    }
}

# Main script execution
try {
    if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Please run this script with administrator privileges"
    }
    
    # Get all user profiles
    $profiles = Get-WmiObject Win32_UserProfile | Where-Object Special -eq $false
    
    foreach ($profile in $profiles) {
        $username = Split-Path $profile.LocalPath -Leaf
        Set-DarkModeForUser -username $username
    }
    
    Write-Host "`nTo apply the changes, either:"
    Write-Host "1. Restart Windows"
    Write-Host "OR"
    Write-Host "2. Restart explorer.exe process:"
    Write-Host "   Stop-Process -Name explorer -Force; Start-Sleep -Seconds 2; Start-Process explorer"
}
catch {
    Write-Error $_
}