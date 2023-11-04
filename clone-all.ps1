param(
    [Parameter(Mandatory=$true)]
    [string]$username
)

# Get the list of repositories for the specified user
$repos = gh repo list $username --json name -q ".[].name"

# Loop through the list of repositories
foreach ($repo in $repos) {
    # Clone each repository
    git clone "https://github.com/$username/$repo.git"
}
