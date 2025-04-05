Enable Windows 11 Mobile Hotspot Automatically After Reboot
===========================================================

Forked from [https://gist.github.com/primaryobjects/8b54f7f4219960127f1f620116315a37](https://gist.github.com/primaryobjects/8b54f7f4219960127f1f620116315a37)

On Windows 11, the Mobile Hotspot feature is automatically disabled when rebooting the machine. Users are required to manually open the Mobile Hotspot settings and toggle the slider for "Share my Internet connection with other devices" in order to enable it.

The included PowerShell script can be added to the Windows Task Scheduler to automatically turn on your Windows 10 Mobile Hotspot upon reboot, login, and unlock of the workstation by any user.

## Quick Start

1. Copy the two script files to a folder on your computer: `hotspot.ps1` and `hotspot.bat`
2. Open the Windows **Task Scheduler**.
3. Right-click on **Task Scheduler Library** and select **Create Task**.
    - Enter a **Name** and **Description**.
4. Click the **Triggers** tab.
5. Click **New**.
    - For **Begin the task** select **At startup**.
    - Checkmark **Delay task for: 1 minute**.
    - Checkmark **Stop task if it runs longer than: 30 minutes**.
    - Checkmark **Enabled**.
6. Click the **Conditions** tab.
7. Uncheck the options **Stop if the computer switches to battery power** and **Start the task only if the computer is on AC power**.
9. Change User to **SYSTEM** (**Run whether user is logged on or not** will be activated by default).
8. Click **OK**.

## Troubleshooting Hotspot Not Activating After Sleep/Hibernation

If the hotspot enable task is not running after your PC wakes from sleep/hibernation, you can add a trigger to execute the task as soon as possible after waking. Create an additional trigger with the following steps.

1. Edit the task and click the **Triggers** tab.
2. For **Begin the task** select **On a schedule**.
3. Check the radio option **Daily**.
4. Enter the earliest **Start Time** to run. *For example, 8:00 AM EST. This computer does not need to be awake during this time, so it is recommended to make this time earlier than you actually need.*
5. Select **Recur every 1 day**.
6. Click **OK**.
7. Click the **Settings** tab.
8. Checkmark the option **Run task as soon as possible after a scheduled start is missed**.

## Troubleshooting Hotspot Disabling Frequently

See also [Windows 10 Mobile Hotspot Keep Alive Script](https://gist.github.com/primaryobjects/ce8c7173ff9c6a453cda336aa2e3ff5c).

If the mobile hotspot is turning itself off at random periods, you can try the following [settings](https://www.guidingtech.com/fix-windows-10-mobile-hotspot-keeps-turning-off/):

1. Disable mobile hotspot power saving by opening the Mobile Hotspot settings and disabling **When no devices are connected, automatically turn off mobile hotspot**.
2. Set the **PeerlessTimeoutEnabled** and **PublicConnectionTimeout** value to a longer duration. This can be done by setting the registry value `HKLM\System\ControlSet001\Services\ICSSVC\Settings\PeerlessTimeoutEnabled` to **120** (Hexadecimal) and `HKLM\System\ControlSet001\Services\ICSSVC\Settings\PublicConnectionTimeout` to **60** (Hexadecimal).

    An example registry script is shown below.

    ```
    Windows Registry Editor Version 5.00

    [HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\icssvc\Settings]
    "PeerlessTimeoutEnabled"=dword:00000120
    "PublicConnectionTimeout"=dword:00000060
    ```
3. Run the script [hotspot-keep-alive.ps1](#file-hotspot-keep-alive-ps1).

## Running the Task When Connecting to the Internet Network

You may optionally want to add a condition to run the task whenever you [connect](https://www.groovypost.com/howto/automatically-run-script-on-internet-connect-network-connection-drop/) to the Internet. This may be done by adding a new "Trigger" to the task scheduler. Select **On an event**, for "Log" select **Microsoft-Windows-NetworkProfile/Operational**, for Source select **NetworkProfile**, for Event ID enter **10000** *(enter 10001 for network disconnect instead of connect)*. Checkmark **Delay task for** and select **30 seconds**.

This trigger may inadvertantly toggle your mobile hotspot multiple times throughout the day, depending upon your Internet connection stability. Therefore, it is generally not recommended.
