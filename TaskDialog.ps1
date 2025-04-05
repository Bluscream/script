# TaskDialog.ps1

param(
    [string]$Title = "Title",
    [string]$Heading = "Heading",
    [string]$Message = "Message",
    [string]$Footer = "Footer",
    [string]$ExpandedInfo = "ExpandedInfo",
    [ValidateSet('None','Application','Warning','Question','Shield','Information','Error')]
    [string]$MainIcon = 'None',
    [ValidateSet('None','Application','Warning','Question','Shield','Information','Error')]
    [string]$TitleBarIcon = 'None',
    [string]$BarColor = "#FFBBFF"
)

Add-Type -AssemblyName PresentationFramework

# Convert bar color string to Color object if provided
if ($BarColor) {
    try {
        $barBrush = [System.Windows.Media.ColorConverter]::ConvertFrom($BarColor)
    } catch {
        Write-Warning "Invalid color format for BarColor. Using default."
        $barBrush = $null
    }
}

# Create XAML window
$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="$Title"
    WindowStyle="None"
    ResizeMode="NoResize"
    Width="400"
    Height="Auto">
    <Grid Margin="20">
        <!-- Main Icon -->
        <Image x:Name="MainIcon" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,0,10,0"/>
        
        <!-- Title -->
        <TextBlock x:Name="TitleText" HorizontalAlignment="Stretch" VerticalAlignment="Top" 
                  FontSize="14" FontWeight="Bold" TextWrapping="Wrap"/>
        
        <!-- Heading -->
        <TextBlock x:Name="HeadingText" HorizontalAlignment="Stretch" VerticalAlignment="Top" 
                  Margin="40,30,0,0" TextWrapping="Wrap"/>
        
        <!-- Message -->
        <TextBlock x:Name="MessageText" HorizontalAlignment="Stretch" VerticalAlignment="Top" 
                  Margin="40,60,0,0" TextWrapping="Wrap"/>
        
        <!-- Footer -->
        <Border x:Name="FooterBorder" BorderBrush="#CCCCCC" BorderThickness="1" 
                HorizontalAlignment="Stretch" VerticalAlignment="Bottom" Margin="0,10,0,0">
            <TextBlock x:Name="FooterText" Padding="5" TextWrapping="Wrap"/>
        </Border>
        
        <!-- Expanded Info Button -->
        <Button x:Name="ExpandButton" Content="More Details >>" HorizontalAlignment="Left" 
                VerticalAlignment="Bottom" Visibility="Collapsed" Margin="0,10,0,0"/>
        
        <!-- Expanded Info Content -->
        <TextBlock x:Name="ExpandedInfoText" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" 
                  Visibility="Collapsed" TextWrapping="Wrap"/>
    </Grid>
</Window>
"@

# Load XAML
$reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Error "Failed to load XAML: $_"
    exit
}

# Get controls
$controls = @{
    MainIcon = $window.FindName('MainIcon')
    TitleText = $window.FindName('TitleText')
    HeadingText = $window.FindName('HeadingText')
    MessageText = $window.FindName('MessageText')
    FooterText = $window.FindName('FooterText')
    ExpandButton = $window.FindName('ExpandButton')
    ExpandedInfoText = $window.FindName('ExpandedInfoText')
    FooterBorder = $window.FindName('FooterBorder')
}

# Set content
$controls.TitleText.Text = $Title
$controls.HeadingText.Text = $Heading
$controls.MessageText.Text = $Message
$controls.FooterText.Text = $Footer

# Handle expanded info
if ($ExpandedInfo) {
    $controls.ExpandedInfoText.Text = $ExpandedInfo
    $controls.ExpandButton.Visibility = 'Visible'
}

# Handle bar color
if ($barBrush) {
    $controls.FooterBorder.Background = $barBrush
}

# Icon mapping
$iconMap = @{
    None = $null
    Application = 'pack://application:,,,/Resources/app.ico'
    Warning = 'pack://application:,,,/Resources/warning.ico'
    Question = 'pack://application:,,,/Resources/question.ico'
    Shield = 'pack://application:,,,/Resources/shield.ico'
    Information = 'pack://application:,,,/Resources/info.ico'
    Error = 'pack://application:,,,/Resources/error.ico'
}

# Set icons
if ($MainIcon) {
    $controls.MainIcon.Source = $iconMap[$MainIcon]
}
if ($TitleBarIcon) {
    $window.Icon = $iconMap[$TitleBarIcon]
}

# Event handlers
$controls.ExpandButton.Add_Click({
    if ($controls.ExpandedInfoText.Visibility -eq 'Visible') {
        $controls.ExpandedInfoText.Visibility = 'Collapsed'
        $controls.ExpandButton.Content = 'More Details >>'
    } else {
        $controls.ExpandedInfoText.Visibility = 'Visible'
        $controls.ExpandButton.Content = 'Less Details <<'
    }
})

# Center window on screen
$screenWidth = [System.Windows.SystemParameters]::WorkArea.Width
$screenHeight = [System.Windows.SystemParameters]::WorkArea.Height
$windowWidth = 400
$windowHeight = $window.ActualHeight
$left = ($screenWidth/2) - ($windowWidth/2)
$top = ($screenHeight/2) - ($windowHeight/2)
$window.Left = $left
$window.Top = $top

# Show dialog
$async = $window.Dispatcher.InvokeAsync({
    $window.ShowDialog() | Out-Null
})
$async.Wait() | Out-Null