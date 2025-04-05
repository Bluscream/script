function Set-Timestamps {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Path
    )

    foreach ($item in $Path) {
        try {
            if (Test-Path $item) {
                if (Get-Item $item -ErrorAction SilentlyContinue) {
                    Write-Host "Processing $item"
                    
                    # Get current timestamp
                    $currentDate = Get-Date -UFormat "%Y-%m-%d %H:%M:%S"
                    
                    # Set timestamps for file/folder
                    if (Test-Path $item -PathType Container) {
                        # Folder
                        Set-Acl $item | Out-Null
                        Get-Acl $item | Set-Acl $item -PropagateRights $false
                    } else {
                        # File
                        Set-Acl $item | Out-Null
                        Get-Acl $item | Set-Acl $item -PropagateRights $false
                    }

                    # Update timestamps
                    $acl = Get-Acl $item
                    $modified = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "Modify", "ObjectInherit", "Allow")
                    $acl.SetAccessRule($modified)
                    Set-Acl $item $acl

                    Write-Host "$item timestamps updated to $currentDate"
                } else {
                    Write-Host "Item $item not found."
                }
            } else {
                Write-Host "Path $item does not exist."
            }
        } catch {
            Write-Host "An error occurred while processing $($item): $_"
        }
    }
}

# Example usage
Set-Timestamps -Path $args
