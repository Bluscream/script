function ReverseGuid($guid) {
    Write-Host "Reversing GUID: $guid"
    # Split the GUID into parts and reverse the order of the first three parts's bytes
    # Example:
    # Input GUID: {01020304-0506-0708-0910-111213141516}
    # Split: 01 02 03 04 - 05 06 - 07 08 - 09 10 - 11 12 13 14 15 16
    # Reversed Bytes: 04 03 02 01 06 05 08 07 09 10 11 12 13 14 15 16
    # Output: {04030201-0605-0807-0910-111213141516}
    $reversedParts = @()
    $guidParts = ($guid -replace "[{}]") -split '-'
    for ($i=0; $i -lt $guidParts.Length; $i++){
        $part = $guidParts[$i]
        # Write-Host "[$i] Part: $part"
        if ($i -lt 3) {
            $splitPart = $part -split '(..)' | Where-Object { $_ }
            # Write-Host "[$i] Split Part: $splitPart (len: $($splitPart.Length))"
            $reversedSplitPart = $splitPart.Clone()
            [array]::Reverse($reversedSplitPart)
            # Write-Host "[$i] Reversed Split Part: $reversedSplitPart"
            $reversedPart = $reversedSplitPart -join ''
            # Write-Host "[$i] Reversed Part: $reversedPart"
            $reversedParts += $reversedPart
        } else {
            $reversedParts += $part
        }
    }
    Write-Host "Reversed Parts: $reversedParts"
    $reversedGuid = "{" + ($reversedParts -join '-') + "}"
    Write-Host "Reversed GUID: $reversedGuid"
    return $reversedGuid
}

# Get the current working directory
$currentDir = (Get-Location).Path
$outputDirectory = Join-Path -Path $currentDir -ChildPath "reg"

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

# Run the wmic command and parse the output
$wmicOutput = wmic nicconfig get description,settingid,macaddress /format:csv
$parsedOutput = ConvertFrom-Csv -InputObject $wmicOutput

# Iterate over each network adapter configuration
foreach ($adapter in $parsedOutput) {
    Write-Host ""
    Write-Host "Adapter: $($adapter.Description) ($($adapter.SettingID))"
    # Sanitize the description for the filename
    $filename = $adapter.Description -replace '[^a-zA-Z0-9]', '_'
    $filename = Join-Path -Path $outputDirectory -ChildPath "$filename.reg"

    # Final Output: "PreferredPublicInterface"=hex:04,03,02,01, 06,05, 08,07, 09,10, 11,12,13,14,15,166

    # Convert the SettingID GUID to binary and reverse the order of the bytes
    # $guidBytes = ([System.Guid]$adapter.SettingID).ToByteArray()
    # $reversedBytes = $guidBytes[0..3] + $guidBytes[5..6] + $guidBytes[4..4] + $guidBytes[7..15]

    # Format the reversed bytes as a comma-separated string
    # $byteString = ($reversedBytes | ForEach-Object { "{0:X2}" -f $_ }) -join ","
    $byteString = (ReverseGuid -guid $adapter.SettingID) # -join ','

    # Generate the registry content with the modified SettingID and additional values
    $regContent = @"
Windows Registry Editor Version   5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\icssvc\Settings\PreferredPublicInterface]
"PreferredPublicInterface"=hex:$byteString
"PreferredPublicInterfaceName"="$($adapter.Description)"
"PreferredPublicInterfaceID"="$($adapter.SettingID)"
"PreferredPublicInterfaceMAC"="$($adapter.MACAddress)"
"@
    Write-Host $regContent
    # Write the registry content to the .reg file
    Set-Content -Path $filename -Value $regContent
}

# SIG # Begin signature block
# MIIbwgYJKoZIhvcNAQcCoIIbszCCG68CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBD8uvfHR0qMJmP
# 6N6xTkRrqzAaNWWTIvknbtAoMDYEx6CCFhMwggMGMIIB7qADAgECAhBpwTVxWsr9
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDg
# IY+/pVThJJVczVNf17Rh6koXa/MUvnjNOqiAHXtWATANBgkqhkiG9w0BAQEFAASC
# AQA5+z2Y9/opeS/9QbGpSc4n6VJAQblq6fg+0CsqdkzwqN/O6Ipgnw+gaVnqsnzx
# 9gTQXK/1R63rnIEwvvAtokFKK69C5jTdyJXbGX6kMeQ4SplIyEvVUrXUcUdpjkh/
# ABPnshBMcIIJ2AU8pxKf/+B/Dh66j2GLYZxMiNDE0wbCchoTcLmjsSAaJJo3Ajch
# YW9huez3a/RpbT7BVLsdzCfxAs/dMnlI5mmEmGtwEEZ+WjDQ206GFd0GOY3sZAJR
# rQ5Fxepe56s9CnVndak+yl1NsJDrhl6N65rV30uD2e5Mjl7GWae489zQQgMiDSya
# uey1FBZfTef1pdChR/u9YCaJoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEB
# MHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYD
# VQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFt
# cGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQMEAgEFAKBpMBgGCSqG
# SIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0MDMwNTAxMjQz
# MVowLwYJKoZIhvcNAQkEMSIEIBxy1b7pSIYwunztx4bJ+uKNpbpqfprXoKp4ZwxI
# zHTDMA0GCSqGSIb3DQEBAQUABIICAJe+NX3Sid8da5a022k/dwi0bP5NjKVPZORi
# rFHGLzWG4oSY8/EmMMJikWvw+up/Z6zfne1Kgg4t6MyICWlN3LJK9nZVprMQ6LBD
# B2Eiq3kOhKPxpv9ctnPh9YeL0m/lol3ZsWLts5/HE5H8gyBpnQS4m/7ZgxeQlmNE
# dQnQi/tb11IVkfDTjiw4uKbaJuylo5QNxbKpJyIGt1TYRojIRrMVxdLw03oFCjYO
# SzG1jmb6ZHKvPP7ugRaOpkrKtB9pEDhNpMT0v3FcxzG/91HHiPWgtftfvhQzX0wZ
# jB3OdYSs+gdaJN7YenrcecMukmZH5iLMRTp8RKQJEZJOlmWcmq8y2VbrOBEa+uJ/
# WbwSG/pOzgtryqhatvc9YbaE6RWuDgbeebyARFTcWKkUH1RyMA8MhhOcqG58Y27l
# 1okfBBstFROu8E48M/TL+KraxO0f++dDY3eMhiTrZM4xfpB61l+lVDG32GiTrxiC
# qb7yyCtVeFLQQ5d/GOMZBgXNCB6MbVsNbKUFtEgaTbfKlqVS0Inz+WfhGcRlpL2z
# OwP4HlsI+l4UJcFt4G2vKDe4JKwYRfgJ47tjhs/LpVt4GtuqdS4ySPGc1wn1/YWn
# V1ddRlUBKLCIL1rrZelzNrtYhz+8qGSgYeX9jXJKksDol6fKR8eVvukWvrdKgmg+
# 19Wcnu73
# SIG # End signature block
