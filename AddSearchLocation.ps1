# Function to add a new location to Windows Search index
function Add-WindowsSearchLocation {
    param (
        [string]$Path,
        [switch]$Force
    )

    # Validate path exists
    if (-not (Test-Path $Path)) {
        throw "Path '$Path' does not exist"
    }

    # Get registry path
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\WorkingSetRules"

    # Check if registry path exists
    if (-not (Test-Path $registryPath)) {
        throw "Windows Search registry path not found"
    }

    # Find next available rule number
    $existingRules = Get-ChildItem -Path $registryPath | Where-Object { $_.PSChildName -match '^\d+$' }
    $nextRuleNumber = if ($existingRules.Count -eq 0) { 0 } else { ([int]($existingRules | Sort-Object { [int]$_.PSChildName } | Select-Object -Last 1).PSChildName) + 1 }

    # Create new rule
    $rulePath = Join-Path $registryPath "$nextRuleNumber"
    New-Item -Path $rulePath -Force:$Force | Out-Null

    # Set required values
    New-ItemProperty -Path $rulePath -Name "Url" -Value "file:///$($Path.Replace('\', '/'))/" -PropertyType String -Force
    New-ItemProperty -Path $rulePath -Name "DisplayURL" -Value "$Path\" -PropertyType String -Force
    New-ItemProperty -Path $rulePath -Name "Include" -Value "1" -PropertyType DWORD -Force
    New-ItemProperty -Path $rulePath -Name "Exclude" -Value "" -PropertyType String -Force

    Write-Host "Successfully added '$Path' to Windows Search index"
}

# Example usage:
try {    
    # Or force overwrite if rule exists
    Add-WindowsSearchLocation -Path "D:\OneDrive" -Force
    
} catch {
    Write-Error $_.Exception.Message
}
Read-Host