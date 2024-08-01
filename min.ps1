# param(
#     [string]$Path,
#     [string[]]$Arguments = @()
# )
$Path = $args[0]
$Arguments = $args[1..($args.Count - 1)]
$Arguments = $Arguments -join " "

# Execute the command
Invoke-Expression "cmd /c start /MIN `"`" `"$Path`" $Arguments"
