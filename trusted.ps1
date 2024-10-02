$ConfirmPreference = "None"
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# if (-not $isAdmin) {
#     Start-Process powershell -ArgumentList "-NoProfile -File `"$PSCommandPath`"" -Verb RunAs
#     exit
# }
Set-ExecutionPolicy -ExecutionPolicy bypass
Install-Module -Name NtObjectManager
Start-Service -Name TrustedInstaller
$parent = Get-NtProcess -ServiceName TrustedInstaller
$proc = New-Win32Process cmd.exe -CreationFlags NewConsole -ParentProcess $parent
$ConfirmPreference = "High"