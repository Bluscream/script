param (
    [switch]$skipUAC = $false
)

if (-Not $skipUAC) {
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
            $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
            Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
            Exit
        }
    }
}
function Generate-Certificate {
    $cert = New-SelfSignedCertificate -DnsName 'localhost' -CertStoreLocation 'cert:\LocalMachine\My'
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store 'Root', 'LocalMachine'
    $store.Open('ReadWrite')
    $store.Add($cert)
    $store.Close()
}
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Certificate Generator'
$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Text = 'Generate Certificate'
$generateButton.Add_Click({ Generate-Certificate }) # We'll define this function later
$form.Controls.Add($generateButton)
$form.ShowDialog()