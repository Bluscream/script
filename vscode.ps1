param(
    [string]$Path
)

# Check if exactly one argument is passed
if (-not $Path) {
    Start-Process "C:\Users\blusc\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe"
    exit
}

# Split the URL by '/' and take the first two parts
$urlParts = $Path.Split('/')
$userRepoName = "$($urlParts[1])/$($urlParts[2])"

# Function to validate URL
function Validate-Url {
    param($url)
    $pattern = "^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+)(.git)*$"
    if ($url -match $pattern) { 
        return $true
    } else {
        return $false
    }
}

# Validate the URL
if (Validate-Url -url $Path) {
    git clone $Path .\$userRepoName
    Start-Process "C:\Users\blusc\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe" -ArgumentList ".\$userRepoName"
} else {
    Start-Process "C:\Users\blusc\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe" -ArgumentList $Path
}
