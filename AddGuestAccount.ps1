# Set error action preference
$ErrorActionPreference = "Stop"

# Function to check if script is elevated
function Test-Elevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to elevate script if necessary
function Elevate-Script {
    if (-Not (Test-Elevated)) {
        Write-Log -Level Warning "Running without elevated privileges"
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

# Function to handle logging
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Debug","Info","Warning","Error")]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    # Create log directory if it doesn't exist
    $logDir = "$env:APPDATA\GuestAccountCreationLogs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }
    
    # Create log entry
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp][$Level] $Message"
    
    # Log to console
    switch ($Level) {
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Info" { Write-Host $logEntry -ForegroundColor Green }
        Default { Write-Host $logEntry }
    }
    
    # Log to file
    $logFile = Join-Path $logDir "guest_account_creation_$(Get-Date -Format yyyyMMdd).log"
    Add-Content -Path $logFile -Value $logEntry
}

try {
    # Attempt elevation
    Write-Log -Level Info "Checking for administrative privileges..."
    Elevate-Script
    
    # Main script logic
    Write-Log -Level Info "Starting guest account creation..."
    
    # Prompt for password securely
    Write-Log -Level Debug "Prompting for password..."
    $GuestPassword = Read-Host -AsSecureString
    
    # Create the new local user account
    Write-Log -Level Info "Creating new local user account..."
    New-LocalUser "Visitor" -Password $GuestPassword
    
    # Add the account to the Guests group
    Write-Log -Level Info "Adding account to Guests group..."
    Add-LocalGroupMember -Group "Guests" -Member "Visitor"
    
    Write-Log -Level Info "Guest account creation completed successfully!"
    Write-Host "Account creation successful! Please review logs at $logDir for details."
}
catch {
    Write-Log -Level Error "An error occurred: $_"
    throw
}