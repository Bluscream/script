# https://superuser.com/a/1434648

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

Function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

Function AwaitAction($WinRtAction) {
    $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]
    $netTask = $asTask.Invoke($null, @($WinRtAction))
    $netTask.Wait(-1) | Out-Null
}

Function Get_TetheringManager() {
    $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
    $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)
    return $tetheringManager;
}

Function SetHotspot($Enable) {
    $tetheringManager = Get_TetheringManager

    if ($Enable -eq 1) {
        if ($tetheringManager.TetheringOperationalState -eq 1)
        {
            "Hotspot is already On!"
        }
        else{
            "Hotspot is off! Turning it on"
            Await ($tetheringManager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
        }
    }
    else {
        if ($tetheringManager.TetheringOperationalState -eq 0)
        {
            "Hotspot is already Off!"
        }
        else{
            "Hotspot is on! Turning it off"
            Await ($tetheringManager.StopTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
        }
    }
}

# Define a function to check the status of the hotspot
Function Check_HotspotStatus() {
    $tetheringManager = Get_TetheringManager
    return $tetheringManager.TetheringOperationalState -eq "Off"
}

# Define a function to start the hotspot
Function Start_Hotspot() {
    $tetheringManager = Get_TetheringManager
    Await ($tetheringManager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
}

$currentDateTime = Get-Date -Format "MM-dd-yyyy HH:mm:ss"
"$currentDateTime Starting hotspot keep-alive."

# Keep alive wifi.
while ($true) {
    # Get the current date and time in a specific format
    $currentDateTime = Get-Date -Format "MM-dd-yyyy HH:mm:ss"

    if (Check_HotspotStatus) {
        "$currentDateTime Hotspot is off! Turning it on"
        Start_Hotspot
    }

    Start-Sleep -Seconds 10  # Wait for 10 seconds before checking again
}
