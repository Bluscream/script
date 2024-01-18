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
    $batchFileName = "powerprofiles/$($scheme.Name).bat"
    $batchContent = "powercfg -setactive $($scheme.GUID)"
    Set-Content -Path $batchFileName -Value $batchContent
}

Write-Host "Batch files created for each power profile."
