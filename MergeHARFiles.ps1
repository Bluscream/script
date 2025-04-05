param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$FilePaths,
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Initialize array to store all entries
$allEntries = @()

foreach ($filePath in $FilePaths) {
    # Check if file exists
    if (-not (Test-Path $filePath)) {
        Write-Error "File not found: $filePath"
        continue
    }

    # Read and parse HAR file
    try {
        $harContent = Get-Content -Path $filePath -Raw
        $harData = $harContent | ConvertFrom-Json

        # Add entries from this file to combined array
        $allEntries += $harData.log.entries
    }
    catch {
        Write-Error "Error processing file $filePath : $_"
        continue
    }
}

# Create merged HAR structure
$mergedHar = @{
    log = @{
        version = "1.2"
        creator = @{
            name = "HAR File Merger"
            version = "1.0"
        }
        entries = $allEntries
    }
}

# Save merged HAR file
try {
    $mergedHar | ConvertTo-Json -Depth 100 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Output "Successfully merged $($FilePaths.Count) HAR files into $OutputPath"
    Write-Output "Total entries: $($allEntries.Count)"
}
catch {
    Write-Error "Error saving merged HAR file: $_"
}
