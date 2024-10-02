
$enableLogging = $true

$currentDir = $args[0] ?? (Get-Location)
Write-Host "Selected directory: $currentDir"
$currentUser = $args[1] ?? $env:USERNAME
Write-Host "Selected User: $currentUser"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, "FullControl", "Allow")

function ScriptLog {
    if ($enableLogging) {
        Write-Host $args
    }
}

Get-ChildItem -Path $currentDir -Recurse -Force | ForEach-Object {
    $itemTypeStr = $_.PSIsContainer ? "folder" : "file"
    $itemPath = """" + $_.FullName + """"
    $itemStr = "$($itemTypeStr): $itemPath"
    try {
        ScriptLog "Processing $itemStr"
        $acl = Get-Acl "$($_.FullName)" # -ErrorAction SilentlyContinue
        if ($null -eq $acl) {
            ScriptLog "ACL retrieval failed for $itemStr. Skipping."
            continue
        }
        $acl.SetAccessRule($rule)
        Set-Acl "$($_.FullName)" $acl
        ScriptLog "Processed $itemStr"
    }
    catch {
        Write-Error "Error setting permissions for $($itemStr): $_"
    }
}

Write-Host "All items processed."