# Write me a batch or powershell script that takes a files and folders as arguments and recursively empties out all files in there recursively. (By emptying i mean deleting every files content)
# Example: clearfiles.ps1 C:\temp\testfolder
# Example: clearfiles.ps1 C:\temp\testfolder\testfile.txt
# Example: clearfiles.ps1 C:\temp\testfolder\testfile.txt C:\temp\testfolder2
# Example: clearfiles.ps1 C:\temp\testfolder\testfile.txt C:\temp\testfolder2\testfile2.txt

function clearfiles {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string[]]$Path
    )

    foreach ($p in $Path) {
        if (Test-Path $p) {
            if (Test-Path $p -PathType Leaf) {
                Clear-Content $p
            } else {
                Get-ChildItem $p -Recurse | Where-Object { !$_.PSIsContainer } | Clear-Content
            }
        } else {
            Write-Error "Path '$p' does not exist."
        }
    }
}

clearfiles $args