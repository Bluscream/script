param (
    [string]$InputDevice,
    [string]$OutputDevice
)

# Function to get the audio device ID based on the device name and type
function GetAudioDeviceID($DeviceName, $DeviceType) {
    $devices = Get-WmiObject -Namespace 'Root\CIMv2\Audio' -Class 'Win32_SoundDevice'
    $deviceID = ($devices | Where-Object { $_.Name -like "*$DeviceName*" -and $_.Direction -eq $DeviceType }).DeviceID
    return $deviceID
}
# # Find the audio input device ID
# $InputDeviceID = GetAudioDeviceID $InputDevice "input"
# # Find the audio output device ID
# $OutputDeviceID = GetAudioDeviceID $OutputDevice "output"
# # Toggle the "Listen to this device" option
# Set-WmiInstance -Namespace 'Root\CIMv2\Audio' -Class 'Win32_AudioEndpoint' -Filter "Name='$InputDeviceID'" -Arguments @{ 'DeviceID' = $OutputDeviceID; 'Enable' = !$_.ListenToThisDevice }

# Find the audio input device
$InputDeviceObject = Get-AudioDevice | Where-Object { $_.Name -like "*$InputDevice*" -and $_.Playback }
if ($null -eq $InputDeviceObject) {
    Write-Host "Input device not found: $InputDevice"
    Exit 1
}

# Find the audio output device
$OutputDeviceObject = Get-AudioDevice | Where-Object { $_.Name -like "*$OutputDevice*" -and $_.Playback }
if ($null -eq $OutputDeviceObject) {
    Write-Host "Output device not found: $OutputDevice"
    Exit 1
}

# Toggle the "Listen to this device" option using nircmd
if ($InputDeviceObject.ListenTo) {
    & "C:\Tools\nircmd.exe" setdefaultsounddevice "$($OutputDeviceObject.ID)" 1
    Write-Host "Disabled 'Listen to this device' for: $InputDevice"
} else {
    & "C:\Tools\nircmd.exe" setdefaultsounddevice "$($OutputDeviceObject.ID)" 2
    Write-Host "Enabled 'Listen to this device' for: $InputDevice"
}