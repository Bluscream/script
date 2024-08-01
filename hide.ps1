param(
    [string]$Path,
    [string[]]$Arguments = @()
)
# $Path = $args[0]
# $Arguments = $args[1..($args.Count - 1)]
# $Arguments = $Arguments -join " "

# Invoke-Expression "cmd /c start /HIDDEN /HIDE `"`" `"$Path`" $Arguments"
Start-Process -FilePath $Path -ArgumentList $Arguments -WindowStyle Hidden
