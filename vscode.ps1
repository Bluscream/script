param(
    [string]$Path
)

# Check if exactly one argument is passed
if (-not $Path) {
    Write-Host "No arguments supplied."
    exit
}

# Function to validate URL
function Validate-Url {
    param($url)
    $isValid = $false
    
    # Check for GitHub URL
    if ($url.StartsWith("https://github.com/")) {
        $isValid = $true
    }
    # Check for GitLab URL
    elseif ($url.StartsWith("https://gitlab.com/")) {
        $isValid = $true
    }

    return $isValid
}

# Validate the URL
$isValid = Validate-Url -url $Path

if ($isValid) {
    # Clone the repository
    git clone $Path .\repository
    
    # Open the cloned repository in VS Code
    Start-Process "C:\Users\blusc\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe" -ArgumentList ".\repository"
} else {
    Start-Process "C:\Users\blusc\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe" -ArgumentList $Path
}
