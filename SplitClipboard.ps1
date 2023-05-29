Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public static class ClipboardHelper
    {
        [DllImport("user32.dll")]
        public static extern IntPtr GetClipboardData(uint uFormat);

        [DllImport("user32.dll")]
        public static extern bool IsClipboardFormatAvailable(uint format);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool OpenClipboard(IntPtr hWndNewOwner);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool CloseClipboard();

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SetClipboardData(uint uFormat, IntPtr hMem);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GlobalAlloc(uint uFlags, UIntPtr dwBytes);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GlobalLock(IntPtr hMem);

        [DllImport("kernel32.dll")]
        public static extern bool GlobalUnlock(IntPtr hMem);

        [DllImport("kernel32.dll")]
        public static extern IntPtr memcpy(IntPtr dest, IntPtr src, UIntPtr count);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GlobalFree(IntPtr hMem);
    }
"@

function Set-ClipboardContent {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Text
    )

    $uFormat = 13 # CF_UNICODETEXT

    [IntPtr]$hWnd = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle

    [void]$null = [ClipboardHelper]::OpenClipboard($hWnd)

    [void]$null = [ClipboardHelper]::EmptyClipboard()

    $byteCount = [System.Text.Encoding]::Unicode.GetByteCount($Text)
    $hMem = [ClipboardHelper]::GlobalAlloc(0x0002 /* GMEM_MOVEABLE */, [UIntPtr]$byteCount)

    if ($hMem -eq [IntPtr]::Zero) {
        throw "Failed to allocate global memory."
    }

    $ptr = [ClipboardHelper]::GlobalLock($hMem)

    if ($ptr -eq [IntPtr]::Zero) {
        throw "Failed to lock global memory."
    }

    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
    [ClipboardHelper]::memcpy($ptr, $bytes, [UIntPtr]$byteCount)

    [ClipboardHelper]::GlobalUnlock($hMem)

    $result = [ClipboardHelper]::SetClipboardData($uFormat, $hMem)

    if ($result -eq [IntPtr]::Zero) {
        throw "Failed to set clipboard data."
    }

    [void]$null = [ClipboardHelper]::CloseClipboard()
}

# Read the clipboard content
$clipboardContent = Get-Clipboard

# Split the content into chunks of 499 characters
$chunkSize = 499
$chunks = for ($i = 0; $i -lt $clipboardContent.Length; $i += $chunkSize) {
    $clipboardContent.Substring($i, [Math]::Min($chunkSize, $clipboardContent.Length - $i))
}

# Iterate over the chunks
for ($i = 0; $i -lt $chunks.Length; $i++) {
    $chunk = $chunks[$i]

    # Set the current chunk to the clipboard
    Set-ClipboardContent -Text $chunk

    # Wait for the clipboard to be cleared (i.e., for the chunk to be pasted)
    while ((Get-Clipboard) -eq $chunk) {
        Start-Sleep -Milliseconds 100
    }

    # Check if it is the last chunk
    if
