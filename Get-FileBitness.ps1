param (
    [string]$path = $PWD.Path,
    [string[]]$extensions = @('*.exe', '*.dll')
)

function Get-FileBitness {
    param (
        [string]$path
    )

    $bytes = [System.IO.File]::ReadAllBytes($path)
    $stream = New-Object System.IO.MemoryStream([System.Array]::CreateInstance([byte], $bytes.Length))
    $writer = New-Object System.IO.BinaryWriter($stream)
    $reader = New-Object System.IO.BinaryReader($stream)

    try {
        $writer.Write($bytes,  0, $bytes.Length)
        $reader.BaseStream.Seek(0x3C, [System.IO.SeekOrigin]::Begin) | Out-Null
        $reader.BaseStream.Seek($reader.ReadUInt32(), [System.IO.SeekOrigin]::Begin) | Out-Null
        $reader.BaseStream.Seek(0x4, [System.IO.SeekOrigin]::Current) | Out-Null

        switch ($reader.ReadUInt16()) {
            0x014C { return '32-bit' }
            0x0200 { return '64-bit' }
            0x0162 { return 'ARM' }
            0xAA64 { return 'ARM64' }
            default { return 'Unknown' }
        }
    } finally {
        $reader.Close()
        $writer.Close()
        $stream.Close()
    }
}
function Get-FileBitnessAlt {
    param (
        [string]$path
    )

    $bytes = [System.IO.File]::ReadAllBytes($path)
    $stream = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter($stream)
    $reader = New-Object System.IO.BinaryReader($stream)

    try {
        $writer.Write($bytes,  0, $bytes.Length)
        $stream.Position =  0 # Reset the position to the start of the stream
        $reader.BaseStream.Seek(0x3C, [System.IO.SeekOrigin]::Begin) | Out-Null
        $reader.BaseStream.Seek($reader.ReadUInt32(), [System.IO.SeekOrigin]::Begin) | Out-Null
        $reader.BaseStream.Seek(0x4, [System.IO.SeekOrigin]::Current) | Out-Null

        switch ($reader.ReadUInt16()) {
            {$_ -eq   0x014C} {return '32-bit'}
            {$_ -eq   0x0200} {return '64-bit'}
            default {return 'Unknown'}
    } catch {
        return 'Unknown'
    }
    } finally {
        $reader.Dispose()
        $writer.Dispose()
        $stream.Dispose()
    }
}


Write-Host "Scanning for files with the following extensions: $($extensions -join ', ') in $path"
$items = Get-ChildItem -Recurse -Include $extensions -File -Path $path
Write-Host "Found $($items.Count) files"

$ErrorActionPreference = 'SilentlyContinue'
$items | ForEach-Object {
    $bitness = "Unknown"
    try {
        $bitness = Get-FileBitnessAlt -path $_.FullName
        if ($bitness -eq "Unknown") { $bitness = Get-FileBitness -path $_.FullName }
    } catch { $bitness = Get-FileBitness -path $_.FullName }
    Write-Output ("{0}: {1}" -f $_.FullName, $bitness)
}
$ErrorActionPreference = 'Continue'
# Pause