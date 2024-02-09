function ReverseGuid($guid) {
    Write-Host "Reversing GUID: $guid"
    # Split the GUID into parts and reverse the order of the first three parts's bytes
    # Example:
    # Input GUID: {01020304-0506-0708-0910-111213141516}
    # Split: 01 02 03 04 - 05 06 - 07 08 - 09 10 - 11 12 13 14 15 16
    # Reversed Bytes: 04 03 02 01 06 05 08 07 09 10 11 12 13 14 15 16
    # Output: {04030201-0605-0807-0910-111213141516}
    $reversedParts = @()
    $guidParts = ($guid -replace "[{}]") -split '-'
    for ($i=0; $i -lt $guidParts.Length; $i++){
        $part = $guidParts[$i]
        # Write-Host "[$i] Part: $part"
        if ($i -lt 3) {
            $splitPart = $part -split '(..)' | Where-Object { $_ }
            # Write-Host "[$i] Split Part: $splitPart (len: $($splitPart.Length))"
            $reversedSplitPart = $splitPart.Clone()
            [array]::Reverse($reversedSplitPart)
            # Write-Host "[$i] Reversed Split Part: $reversedSplitPart"
            $reversedPart = $reversedSplitPart -join ''
            # Write-Host "[$i] Reversed Part: $reversedPart"
            $reversedParts += $reversedPart
        } else {
            $reversedParts += $part
        }
    }
    Write-Host "Reversed Parts: $reversedParts"
    $reversedGuid = "{" + ($reversedParts -join '-') + "}"
    Write-Host "Reversed GUID: $reversedGuid"
    return $reversedGuid
}

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
    Write-Host ""
    Write-Host "Adapter: $($adapter.Description) ($($adapter.SettingID))"
    # Sanitize the description for the filename
    $filename = $adapter.Description -replace '[^a-zA-Z0-9]', '_'
    $filename = Join-Path -Path $outputDirectory -ChildPath "$filename.reg"

    # Final Output: "PreferredPublicInterface"=hex:04,03,02,01, 06,05, 08,07, 09,10, 11,12,13,14,15,166

    # Convert the SettingID GUID to binary and reverse the order of the bytes
    # $guidBytes = ([System.Guid]$adapter.SettingID).ToByteArray()
    # $reversedBytes = $guidBytes[0..3] + $guidBytes[5..6] + $guidBytes[4..4] + $guidBytes[7..15]

    # Format the reversed bytes as a comma-separated string
    # $byteString = ($reversedBytes | ForEach-Object { "{0:X2}" -f $_ }) -join ","
    $byteString = (ReverseGuid -guid $adapter.SettingID) # -join ','

    # Generate the registry content with the modified SettingID and additional values
    $regContent = @"
Windows Registry Editor Version   5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\icssvc\Settings\PreferredPublicInterface]
"PreferredPublicInterface"=hex:$byteString
"PreferredPublicInterfaceName"="$($adapter.Description)"
"PreferredPublicInterfaceID"="$($adapter.SettingID)"
"@
    Write-Host $regContent
    # Write the registry content to the .reg file
    Set-Content -Path $filename -Value $regContent
}
