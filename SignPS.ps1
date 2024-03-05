$XAML =@'


<Window x:Name="MainWindows" 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp1"
        mc:Ignorable="d"
        Title="Certificate Code Signing Tool" Height="490" Width="894" ResizeMode="NoResize">
    <Grid x:Name="MainWindow1" Margin="0,0,-20.333,-19">
        <Grid.RowDefinitions>
            <RowDefinition Height="82*"/>
            <RowDefinition Height="399*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="409*"/>
            <ColumnDefinition Width="77*"/>
            <ColumnDefinition Width="154*"/>
            <ColumnDefinition Width="155*"/>
            <ColumnDefinition Width="73*"/>
            <ColumnDefinition Width="27*"/>
        </Grid.ColumnDefinitions>
        <GroupBox x:Name="CertInfoGroupBox" Grid.ColumnSpan="4" Grid.Column="1" Header="Certificate Info:" Height="252" Margin="9.667,64,12.333,0" Grid.RowSpan="2" VerticalAlignment="Top" RenderTransformOrigin="0.5,0.5">
            <GroupBox.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.213"/>
                    <TranslateTransform/>
                </TransformGroup>
            </GroupBox.RenderTransform>
        </GroupBox>
        <Button VerticalAlignment="Bottom" x:Name="Browse" Content="Browse..." RenderTransformOrigin="1.797,2.286" Height="35" FontSize="10" Margin="11.667,0,0,33.333" Grid.ColumnSpan="2" Grid.Row="1" Grid.Column="1" Width="120" HorizontalAlignment="Left"/>
        <Button x:Name="Sign" Content="Sign" IsEnabled="False" RenderTransformOrigin="-0.219,0.514" FontSize="10" Margin="90.667,0,0,33.333" Grid.ColumnSpan="2" Grid.Column="2" Grid.Row="1" Width="120" Height="35" HorizontalAlignment="Left" VerticalAlignment="Bottom" />
        <Button x:Name="Close" Content="Close" IsCancel="True" Margin="99.667,0,0,33.333" Grid.Column="3" Grid.Row="1" Grid.ColumnSpan="2" Width="120" Height="35" FontSize="10" HorizontalAlignment="Left" VerticalAlignment="Bottom" />
        <ComboBox x:Name="ComboBox1" Margin="11.667,30,10.333,23" Grid.ColumnSpan="4" Grid.Column="1"/>
        <TextBlock HorizontalAlignment="Left" Margin="10.667,10,0,0" TextWrapping="Wrap" VerticalAlignment="Top" RenderTransformOrigin="0.467,1.629" Height="18" Width="200" Grid.ColumnSpan="2" Grid.Column="1"><Run Text="Choose Code"/><Run Text=" "/><Run Text="Signing"/><Run Text=" "/><Run Text="Certificate"/><Run Text=":"/></TextBlock>
        <ListView x:Name="List1" HorizontalAlignment="Left" Margin="10,30,0,0" Width="400" Height="365" VerticalAlignment="Top" Grid.RowSpan="2" Grid.ColumnSpan="2">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label Content="Choose your files to sign:" HorizontalAlignment="Left" Margin="10,5,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <TextBox x:Name="Message" Grid.ColumnSpan="4" Grid.Column="1" Height="231" Margin="16.667,0,18.333,0" TextWrapping="Wrap" VerticalAlignment="Top" Grid.Row="1" RenderTransformOrigin="0.5,0.5" FontSize="10">
            <TextBox.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="-0.05"/>
                    <TranslateTransform/>
                </TransformGroup>
            </TextBox.RenderTransform>
        </TextBox>
        <GroupBox x:Name="NotificationGroupBox" Grid.ColumnSpan="4" Grid.Column="1" Header="Notifications:" Height="82" Margin="10.667,235,12.333,0" Grid.Row="1" VerticalAlignment="Top" BorderBrush="#FFFF1700">
            <TextBox x:Name="Notification" Height="57" Margin="0,0,3,0" TextWrapping="Wrap" VerticalAlignment="Top" RenderTransformOrigin="0.5,0.5" FontSize="10"/>
        </GroupBox>

    </Grid>
</Window>


'@

function Convert-XAMLtoWindow
{
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $XAML
  )
  
  Add-Type -AssemblyName PresentationFramework
  
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  $result = [Windows.Markup.XAMLReader]::Load($reader)
  $reader.Close()
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  while ($reader.Read())
  {
    $name=$reader.GetAttribute('Name')
    if (!$name) {$name=$reader.GetAttribute('x:Name')}
    if($name)
    {$result | Add-Member NoteProperty -Name $name -Value $result.FindName($name) -Force}
  }
  $reader.Close()
  $result
}

function Show-WPFWindow
{
  param
  (
    [Parameter(Mandatory)]
    [Windows.Window]
    $Window
  )
  
  $result = $null
  $null = $window.Dispatcher.InvokeAsync{
    $result = $window.ShowDialog()
    Set-Variable -Name result -Value $result -Scope 1
  }.Wait()
  $result
}

function Get-Files
{
  if ($window.List1.SelectedIndex -ne -1) {
    $filenames = $window.List1.SelectedItems
    return $filenames
  }
  else { 
    Write-Verbose -Message ("Please select your files to sign")
    $window.Notification.Text = "You have to select at least one file to sign"
  
  }
}

function Invoke-SignFile ([Parameter(Mandatory=$true)]$filename) {
  try {
    $thumbprint = $script:mycodesigningcerts[($window.ComboBox1.SelectedIndex)].Thumbprint
    $mycert = Get-ChildItem("Cert:\CurrentUser\my\$thumbprint")
    Set-AuthenticodeSignature -FilePath $filename `
    -Certificate $mycert `
    -TimestampServer http://timestamp.digicert.com `
    -IncludeChain All `
    -HashAlgorithm SHA256
    Write-Verbose -Message ("File {0} signed" -f $filename)
    $window.Notification.Text += "File: {0} have been signed`n" -f $filename.Name
  }
   catch { 
    Write-Verbose -Message ("Error: {0}" -f $_.Exception.Message)
    $window.Notification.Text = "Error: {0}`n" -f $_.Exception.Message
    
  } 
}

$window = Convert-XAMLtoWindow -XAML $XAML
$script:mycodesigningcerts = @()

$window.Close.add_Click{
  # remove param() block if access to event information is not required
  
  Exit
}

$window.Browse.add_Click{

  # add event code here
  # Clear Forms in UI
  $window.List1.items.Clear()
  $window.ComboBox1.Items.Clear()
  
  Add-Type -AssemblyName System.Windows.Forms
  $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Multiselect = $true # Multiple files can be chosen
    Filter = 'PowerShell (PowerShell (*.ps*)|*.ps*;*.ps1xml|All Files (*.*)|*.*' # Specified file types
  }

  [void]$FileBrowser.ShowDialog()

  $path = $FileBrowser.FileNames

  If($FileBrowser.FileNames -like "*\*") {

    # Do something before work on individual files commences
    foreach($file in Get-ChildItem $path){
      # add filepath to the ListBox List1
      Get-ChildItem ($file) |
      ForEach-Object {
        $window.List1.items.Add($file)
      }
    }
    # Get all my valid code signing certs in user my store and populate ComboBox
          
    $certs = @(Get-ChildItem cert:\currentuser\my -CodeSigningCert)
    $certs|ForEach-Object {
      If (([datetime]($_.NotAfter.ToString("MM/dd/yyyy HH:mm:ss")) -gt ([datetime](get-date -UFormat "%m/%d/%Y %R")))) {
        $window.ComboBox1.Items.Add($_.Subject)
        $script:mycodesigningcerts += $_    
      }
      elseif (([datetime]($_.NotAfter.ToString("MM/dd/yyyy HH:mm:ss")) -lt ([datetime](get-date -UFormat "%m/%d/%Y %R")))) { 
        Write-Verbose -Message ("No valid codesigning certificate found:`n $_.Subject")
        $window.Notification.Text = "Certificate:`n{0}`nwith Thumbprint {1}`nis not valid and has been skipped" -f $_.Subject, $_.Thumbprint  
      }
      else {
        Write-Verbose -Message ("No valid codesigning certificate found")
        $window.Message.Text = "No certificates have been found that can be used!" 
      }
    }
    $window.ComboBox1.SelectedIndex = 0
   
  }

  else {
    Write-Verbose -Message ("Cancelled by user")
  }
}

$window.ComboBox1.add_SelectionChanged{
  
  # add event code here
  if ($window.ComboBox1.SelectedItem) {
    $window.Sign.IsEnabled = $true
    $window.Message.Text = $script:mycodesigningcerts[($window.ComboBox1.SelectedIndex)]
  }
  
}

$window.Sign.add_Click{
  $window.Notification.Text = ""
  
  # add event code here
  $files = Get-Files
  #$signcert = @($window.ComboBox1.SelectedItem)
  #Write-Host $global:mycodesigningcerts[(($window.ComboBox1.SelectedIndex))]
  Foreach ($file in $files) {
    #Set-AuthenticodeSignature -Certificate $global:mycodesigningcerts[($window.ComboBox1.SelectedIndex)] -FilePath $file
    try {
      Invoke-SignFile $file
    }
    catch {
      Write-Verbose -Message ("File {0} not signed, error was {1}" -f $file, $_.Exception.Message)
      $window.Notification.Text += "File: {0} not signed`nError: {1}" -f $file.Name, $_.Exception.Message
    }
  }
}

Show-WPFWindow -Window $window


# SIG # Begin signature block
# MIIbwgYJKoZIhvcNAQcCoIIbszCCG68CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDZ4jUIXKeS0nrv
# CNWHuw4edXqQ/nIXusDCO/SXoeda4KCCFhMwggMGMIIB7qADAgECAhBpwTVxWsr9
# sEdtdKBCF5GpMA0GCSqGSIb3DQEBCwUAMBsxGTAXBgNVBAMMEEFUQSBBdXRoZW50
# aWNvZGUwHhcNMjMwNTIxMTQ1MjUxWhcNMjQwNTIxMTUxMjUxWjAbMRkwFwYDVQQD
# DBBBVEEgQXV0aGVudGljb2RlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAoYBnOJ64OauwmbLN3bJ4EijORLohvNN3Qbjxxo/mTvQqqOLNAezk/A08LVg0
# GjQBR7L6LK/gnIVyeQxW4rKiLyJrS+3sBb+H6rTby5jiVBJmjiULxiVDEB+Fyz4h
# JGCWrn0BGGH4aLYfSdtlOD1sc0ySQuEuixZMV9dZIckNxYmJoeeLrwvnfio34ngy
# qxRY6lzULq9oTYoRTFSNxpb13mfZLhxz2pOzbEKBmYkbrDj4JtSzwBggly04oJXM
# ZZSRNavH6ZHxOUhs1UMgFHBe8dpepTBHY2uFjcynJaA5K02Yf2JAzfwc7A/tyuAM
# XNpK11pZ8aurlGws0W3TJtA6VQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFIrvKx60YqR0ov787AjXn8zIl/36
# MA0GCSqGSIb3DQEBCwUAA4IBAQCdF+EBLn7mIQdZlfOFrJyarvy8SIaWcPUPVZPW
# ZdOH3U/HeANjbhPIZIbrmlB/uSqfoCOjKcqP1/wT1uHA8HdDkMC+WmWT0PpVBtr8
# W/dxgGc531Ykli1qn7qh8pKqQvSBC42cn3iX9KuN8yguyUIoxyATBBnJb/9a+nMA
# 3u8W3tF7gVwvvCETEE0cM8R6LY5/DjT5NRmo090lx/w8io//t0ZjyHuf9sY0CxLP
# 56MZgI/EIZq/M+LIX4WsYTvp3vkmcFDfhgEV8BVqKzPT/sKjKq61PED2jCjLj7L5
# Fdo8ip3XaTURhXg1syUHbSYOnCinoiT4AHIYJYrx+flT+9ecMIIFjTCCBHWgAwIB
# AgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIw
# ODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Y
# q3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lX
# FllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxe
# TsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbu
# yntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I
# 9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmg
# Z92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse
# 5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKy
# Ebe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwh
# HbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/
# Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwID
# AQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM
# 3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYD
# VR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+
# MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUA
# A4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSI
# d229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7U
# z9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxA
# GTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAID
# yyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW
# /VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0o
# ZipeWzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhE
# aWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIy
# MjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# OzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGlt
# ZVN0YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1
# BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3z
# nIkLf50fng8zH1ATCyZzlm34V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZ
# Kz5C3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald6
# 8Dd5n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zk
# psUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYn
# LvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIq
# x5K/oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOd
# OqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJ
# TYsg0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJR
# k8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEo
# AA6EVO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8G
# A1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjAT
# BgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYD
# VR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9
# bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0T
# zzBTzr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYS
# lm/EUExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaq
# T5Fmniye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl
# 2szwcqMj+sAngkSumScbqyQeJsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1y
# r8THwcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05
# et3/JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6um
# AU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSwe
# Jywm228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr
# 7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYC
# JtnwZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzga
# oSv27dZ8/DCCBsIwggSqoAMCAQICEAVEr/OUnQg5pr/bP1/lYRYwDQYJKoZIhvcN
# AQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTsw
# OQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVT
# dGFtcGluZyBDQTAeFw0yMzA3MTQwMDAwMDBaFw0zNDEwMTMyMzU5NTlaMEgxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEgMB4GA1UEAxMXRGln
# aUNlcnQgVGltZXN0YW1wIDIwMjMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQCjU0WHHYOOW6w+VLMj4M+f1+XS512hDgncL0ijl3o7Kpxn3GIVWMGpkxGn
# zaqyat0QKYoeYmNp01icNXG/OpfrlFCPHCDqx5o7L5Zm42nnaf5bw9YrIBzBl5S0
# pVCB8s/LB6YwaMqDQtr8fwkklKSCGtpqutg7yl3eGRiF+0XqDWFsnf5xXsQGmjzw
# xS55DxtmUuPI1j5f2kPThPXQx/ZILV5FdZZ1/t0QoRuDwbjmUpW1R9d4KTlr4HhZ
# l+NEK0rVlc7vCBfqgmRN/yPjyobutKQhZHDr1eWg2mOzLukF7qr2JPUdvJscsrdf
# 3/Dudn0xmWVHVZ1KJC+sK5e+n+T9e3M+Mu5SNPvUu+vUoCw0m+PebmQZBzcBkQ8c
# tVHNqkxmg4hoYru8QRt4GW3k2Q/gWEH72LEs4VGvtK0VBhTqYggT02kefGRNnQ/f
# ztFejKqrUBXJs8q818Q7aESjpTtC/XN97t0K/3k0EH6mXApYTAA+hWl1x4Nk1nXN
# jxJ2VqUk+tfEayG66B80mC866msBsPf7Kobse1I4qZgJoXGybHGvPrhvltXhEBP+
# YUcKjP7wtsfVx95sJPC/QoLKoHE9nJKTBLRpcCcNT7e1NtHJXwikcKPsCvERLmTg
# yyIryvEoEyFJUX4GZtM7vvrrkTjYUQfKlLfiUKHzOtOKg8tAewIDAQABo4IBizCC
# AYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1Ud
# IwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSltu8T5+/N0GSh
# 1VapZTGj3tXjSTBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5n
# Q0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1w
# aW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCBGtbeoKm1mBe8cI1PijxonNgl
# /8ss5M3qXSKS7IwiAqm4z4Co2efjxe0mgopxLxjdTrbebNfhYJwr7e09SI64a7p8
# Xb3CYTdoSXej65CqEtcnhfOOHpLawkA4n13IoC4leCWdKgV6hCmYtld5j9smViuw
# 86e9NwzYmHZPVrlSwradOKmB521BXIxp0bkrxMZ7z5z6eOKTGnaiaXXTUOREEr4g
# DZ6pRND45Ul3CFohxbTPmJUaVLq5vMFpGbrPFvKDNzRusEEm3d5al08zjdSNd311
# RaGlWCZqA0Xe2VC1UIyvVr1MxeFGxSjTredDAHDezJieGYkD6tSRN+9NUvPJYCHE
# Vkft2hFLjDLDiOZY4rbbPvlfsELWj+MXkdGqwFXjhr+sJyxB0JozSqg21Llyln6X
# eThIX8rC3D0y33XWNmdaifj2p8flTzU8AL2+nCpseQHc2kTmOt44OwdeOVj0fHMx
# VaCAEcsUDH6uvP6k63llqmjWIso765qCNVcoFstp8jKastLYOrixRoZruhf9xHds
# FWyuq69zOuhJRrfVf8y2OMDY7Bz1tqG4QyzfTkx9HmhwwHcK1ALgXGC7KP845VJa
# 1qwXIiNO9OzTF/tQa/8Hdx9xl0RBybhG02wyfFgvZ0dl5Rtztpn5aywGRu9BHvDw
# X+Db2a2QgESvgBBBijGCBQUwggUBAgEBMC8wGzEZMBcGA1UEAwwQQVRBIEF1dGhl
# bnRpY29kZQIQacE1cVrK/bBHbXSgQheRqTANBglghkgBZQMEAgEFAKCBhDAYBgor
# BgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDG
# /WUriByUuJEuuv330MLr657wyuAWO3E6BxD6wgxP5jANBgkqhkiG9w0BAQEFAASC
# AQADtPvCwbDe7VkbeL4dJ273x8pYdHD5R0hJAuax7iMdvYdDasLofkA3GkV9AsBl
# T6BPwPl6MQw5xI+1jdCSqt2S6GABsnrMlIL6tyh2VmLqQceGA4HPGCGvtsD89qan
# JpG+7aGzSImtpKjBOpRKTS0xIcEhgFtzVl6Dy6tI6S93lVQW/qD0RpPg2ko588wa
# 3gqQKYvd6kUbX1FqwxoXZsr+eI06YEfSna4ueYQivx6yeQW88Dw0IE7na0KxNONZ
# KM16lOoyKMJlHu3xq3/4VGfrYqsfZxkNlkFyALq5mUxGe7Y5+BS3RHhPjqGvECG/
# doZDBKb7IkJzzqooaWbtqSAToYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEB
# MHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYD
# VQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFt
# cGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEFAKBpMBgGCSqG
# SIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0MDMwNTAxMjQz
# NFowLwYJKoZIhvcNAQkEMSIEIM2qOPqUJssYjQpNwcFT+FefK+OY+4O9uKNn7Igc
# +L2cMA0GCSqGSIb3DQEBAQUABIICAA9TeSdvsFOFD9uSmc/hH+6msV8OnuMuHjtE
# xhRQfjetNAgnWkKOjPh5Z/lNpZwDTJ1z5tzque+BfviMgT7W/Anordpmi1HvuABr
# HhsHx2YOn+5FkYH2GUagyLsRArtmQ+vPd8S3HATlhkzk6KKjbF7RTBnotJDM977T
# vzYERAvkZGV+4SVPUmV996mCO0Tu+BBbamxdohX6rQ3SyOgUBWq8luwuKClyAYOm
# O6/PWxdHFon5c8S4D0GuKR9NfAIiWA6/HaKAqh5mPuls2Rdeuk3L9TsrNV/oZEk3
# tHWW6oRwN1ZfQL+NG+yVsEJpyFy50E60vamAeLLpk9ekijO+3xH0M6nyZ0Yromw3
# ej2HsSXKlDHYfo9BZB65mAGfQp6SqoUEhOs9wly79CbqlxNaC5A4lZb+0bbrt5PS
# L8lFV++bVmbmCjPmv2aSU3+4MhCXkro1OjxVz8GLAIpvgStFj2Fh5lf0vc7paABi
# YFXkabKDfoBI9ehxWWoSdB26ue+VIV6l2Yhae3C2cXCgUe1Ky2jwHhPgIjChxE7e
# 1XU+07EKdf5hoRyH1T/0E3ZN8HKwFI2V/hhMLw9CwuMu4aiyFIT1LkLyP95wcb7D
# xUe7x7NzBUCeyaZqO07usGGwIn2iH5+QQ+WJRtZf908y7waoHr+JokuItOZq5ZHA
# 1WrR0xJI
# SIG # End signature block
