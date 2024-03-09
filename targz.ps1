param(
    [Parameter(Mandatory=$true)]
    [string]$OutputArchive,

    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$InputPaths
)

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path "targz.log" -append

# Check for 7-Zip executables
$sevenZipExe = $null
foreach ($exe in '7z.exe', '7za.exe', '7zg.exe') {
    try {
        $sevenZipExe = Get-Command $exe -ErrorAction Stop
        break
    } catch {
        # Continue checking other executables
    }
}

if ($null -eq $sevenZipExe) {
    Write-Error "7-Zip executable not found. Please install 7-Zip."
    exit 1
}

$outPath = Get-Item $InputPaths[0]
Write-Host "outPath: $outPath"
$commonRoot = $outPath.Directory.Name
Write-Host "commonRoot: $commonRoot"
foreach ($path in $InputPaths) {
    $item = Get-Item $path
    while ($item.FullName -ne $commonRoot) {
        Write-Host "item.FullName: $($item.FullName)"
        try {
            $commonRoot = Split-Path $commonRoot
        } catch {
            throw "The input paths do not share a common root directory."
        }
    }
}

# Convert input paths to relative paths
$relativePaths = $InputPaths | ForEach-Object {
    $relativePath = $_.Replace($commonRoot, '')
    if ($relativePath.StartsWith('\')) {
        $relativePath = $relativePath.Substring(1)
    }
    return $relativePath
}

# Create the archive
& $sevenZipExe.Source a -ttar -so $OutputArchive $relativePaths | & $sevenZipExe.Source a -si -tgzip $OutputArchive

Write-Host "Compression completed. The archive is $OutputArchive."

Stop-Transcript