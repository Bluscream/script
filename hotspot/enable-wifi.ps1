# https://stackoverflow.com/questions/45833873/enable-win10-inbuild-hotspot-by-cmd-batch-powershell/60444585#answer-60444585
[Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime] | Out-Null

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
Function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

# https://stackoverflow.com/a/55563418
$connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)

# Be sure to include Ben N.'s await for IAsyncOperation:
# https://superuser.com/questions/1341997/using-a-uwp-api-namespace-in-powershell

# Check whether Mobile Hotspot is enabled
$tetheringManager.TetheringOperationalState

# Start Mobile Hotspot
Await ($tetheringManager.StartTetheringAsync())([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])

# Stop Mobile Hotspot
#Await ($tetheringManager.StopTetheringAsync())([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
