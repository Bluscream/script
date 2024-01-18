# Create powerprofiles/ subdirectory if it doesn't exist
if (-not (Test-Path -Path powerprofiles)) {
    New-Item -Path powerprofiles -ItemType Directory
}

# Get all power scheme GUIDs
$powerSchemes = powercfg -list | Select-String -Pattern 'Power Scheme GUID: (.*)  \((.*)\)' | ForEach-Object {
    $matches = $_.Matches
    [PSCustomObject]@{
        GUID = $matches.Groups[1].Value.Trim()
        Name = $matches.Groups[2].Value.Trim()
    }
}

# For each power scheme, create a batch file to activate it
foreach ($scheme in $powerSchemes) {
    $batchContent = "powercfg /S $($scheme.GUID)"
    Set-Content -Path "powerprofiles/$($scheme.Name).bat" -Value $batchContent
    # $ps1Content = @"
    # # Activate power scheme $($scheme.ElementName)
    # $guid = '$($scheme.InstanceID.SubString($scheme.InstanceID.LastIndexOf("{")))'
    # (powercfg /S $guid)
    # "@
    # Set-Content -Path "powerprofiles/$($scheme.Name).ps1" -Value $ps1Content
    powercfg -export "powerprofiles/$($scheme.Name).pow" $scheme.GUID
}

Write-Host "Batch files created for each power profile."
