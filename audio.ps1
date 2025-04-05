param (
    [Parameter(Mandatory=$false)]
    [int]$Volume = 100
)


try { Install-Module -Name AudioDeviceCmdlets } catch { Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser }

function Get-DefaultAudioDevices {
    return @{
        Playback = Get-AudioDevice -Playback
        PlaybackCommunication = Get-AudioDevice -PlaybackCommunication
        Recording = Get-AudioDevice -Recording
        RecordingCommunication = Get-AudioDevice -RecordingCommunication
    }
}
function Set-DefaultAudioDevices {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Devices
    )
    if ($Devices.Playback) {
        Write-Host "Restoring default playback device ""$($Devices.Playback.Name)"
        Set-AudioDevice -DefaultOnly -InputObject $Devices.Playback | Out-Null
    }
    if ($Devices.PlaybackCommunication) {
        Write-Host "Restoring default playback communication device ""$($Devices.PlaybackCommunication.Name)"""
        Set-AudioDevice -CommunicationOnly -InputObject $Devices.PlaybackCommunication | Out-Null
    }
    if ($Devices.Recording) {
        Write-Host "Restoring default recording device ""$($Devices.Recording.Name)"""
        Set-AudioDevice -DefaultOnly -InputObject $Devices.Recording | Out-Null
    }
    if ($Devices.RecordingCommunication) {
        Write-Host "Restoring default recording communication device ""$($Devices.RecordingCommunication.Name)"""
        Set-AudioDevice -CommunicationOnly -InputObject $Devices.RecordingCommunication | Out-Null
    }
}

$defaults = Get-DefaultAudioDevices
Get-AudioDevice -List | Where-Object { $_.Type -eq "Recording" } | ForEach-Object {
    # if ($oldVol -ne 100) {
        Set-AudioDevice -InputObject $_ | out-null
        $oldVol = (Get-AudioDevice -RecordingVolume);
        Set-AudioDevice -RecordingVolume $Volume | out-null # -ID $id 
        Set-AudioDevice -RecordingCommunicationVolume $Volume | out-null # -ID $id 
        $newVol = (Get-AudioDevice -RecordingVolume);
        Write-Host """$($_.Name)"" ($($_.ID)): $oldVol -> $newVol";
    # }
}
Set-DefaultAudioDevices -Devices $defaults
Write-Host "Done!" -ForegroundColor Green
# Read-Host -Prompt "Enter to exit"
Start-Sleep -Seconds 3
Exit-PSHostProcess