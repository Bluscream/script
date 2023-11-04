# Create the bat/ and lnk/ subfolders if they don't exist
if (!(Test-Path -Path .\bat)) {
    New-Item -Path .\bat -ItemType Directory | Out-Null
}
if (!(Test-Path -Path .\lnk)) {
    New-Item -Path .\lnk -ItemType Directory | Out-Null
}

# Import the required modules
Import-Module Microsoft.PowerShell.Utility

# Get all scheduled tasks
$tasks = Get-ScheduledTask

# Open the tasks.bat file for writing
$file = New-Item -Path .\tasks.bat -ItemType File -Force

# Iterate over each task
foreach ($task in $tasks) {
    # Construct the command
    $command = "schtasks /run /tn `"$($task.TaskPath)$($task.TaskName)`""
    
    # Write the command to the tasks.bat file
    $command | Out-File -FilePath $file.FullName -Append

    # Sanitize the task name for use as a filename
    $sanitizedTaskName = $task.TaskName -replace '[^\w]', '_'

    # Write the command to a .bat file in the bat/ subfolder
    $batFilePath = Join-Path -Path .\bat -ChildPath "$sanitizedTaskName.bat"
    $command | Out-File -FilePath $batFilePath

    # Debug print the path of the .bat file
    Write-Host "Writing .bat file to: $batFilePath"

    # Create a .lnk file in the lnk/ subfolder that points to the .bat file
    $lnkFilePath = Join-Path -Path .\lnk -ChildPath "$sanitizedTaskName.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($lnkFilePath)
    $shortcut.TargetPath = $batFilePath
    $shortcut.Save()

    # Debug print the path of the .lnk file
    Write-Host "Creating .lnk file at: $lnkFilePath"
}
