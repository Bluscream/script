param(
    [string[]]$Paths
)

# Default to the current directory if no paths are provided
if ($Paths) {
    # Ensure all paths are absolute
    $Paths = $Paths | Where-Object { $_ -like "\\*" } | ForEach-Object { Resolve-Path $_ }
}
if (-not $Paths) {
    $Paths = @((Get-Location))
}

# Function to check if a path is a Git repository
function Is-GitRepository($path) {
    return (Test-Path -Path "$path\.git" -PathType Container)
}

# Recursive function to find and process Git repositories
function Process-GitRepositories($path) {
    # Check if the current path is a Git repository
    if (Is-GitRepository $path) {
        Write-Host "Processing Git repository at $path"
        
        # Change directory to the Git repository
        Set-Location -Path $path
        
        # Pull submodules
        & git submodule update --init --recursive
        
        # Pull the main repository
        & git pull
        
        # Change back to the original directory after processing
        Set-Location -Path $basePath
    } else {
        # If not a Git repository, search through its contents
        Get-ChildItem -Path $path -Directory | ForEach-Object {
            Process-GitRepositories $_.FullName
        }
    }
}

# Iterate over each path provided as an argument
foreach ($path in $Paths) {
    Write-Host "Processing path $path"
    Process-GitRepositories -Path $path
}

Read-Host -Prompt "Finished, press any key to exit"