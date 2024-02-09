# Get the current working directory
$currentDir = (Get-Location).Path
$outputDirectory = Join-Path -Path $currentDir -ChildPath "reg"

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

# Run the wmic command and parse the output
$wmicOutput = wmic nicconfig get description,settingid /format:csv
$parsedOutput = ConvertFrom-Csv -InputObject $wmicOutput

# Iterate over each network adapter configuration
foreach ($adapter in $parsedOutput) {
    # Sanitize the description for the filename
    $filename = $adapter.Description -replace '[^a-zA-Z0-9]', '_'
    $filename = Join-Path -Path $outputDirectory -ChildPath "$filename.reg"

    # Convert the SettingID GUID to binary and reverse the order of the bytes
    $guidBytes = ([System.Guid]$adapter.SettingID).ToByteArray()
    $reversedBytes = $guidBytes[3..0] + $guidBytes[5..6] + $guidBytes[4..4] + $guidBytes[7..15]

    # Format the reversed bytes as a comma-separated string
    $byteString = ($reversedBytes | ForEach-Object { "{0:X2}" -f $_ }) -join ","

    # Generate the registry content with the modified SettingID and additional values
    $regContent = @"
Windows Registry Editor Version   5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\icssvc\Settings\PreferredPublicInterface]
"PreferredPublicInterface"=hex:$byteString
"PreferredPublicInterfaceName"="$($adapter.Description)"
"PreferredPublicInterfaceID"="$($adapter.SettingID)"
"@

    # Write the registry content to the .reg file
    Set-Content -Path $filename -Value $regContent
}
