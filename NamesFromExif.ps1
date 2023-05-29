Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$selected_path = $args[0];
# prompt the user to select a folder
if ($null -eq $selected_path) {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select a folder containing images"
    $dialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer # "G:/Temp/Bilder" # 
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        exit
    }
    $selected_path = $dialog.SelectedPath;
}
$objects = Get-ChildItem -Path $selected_path -include ('*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.tif', '*.tiff', '*.svg', '*.psd', '*.ai', '*.eps', '*.pdf', '*.webp', '*.ico', '*.heic', '*.cr2', '*.nef', '*.orf', '*.arw', '*.rw2', '*.dng') -Recurse
Write-Output "Processing $($objects.Length) objects"
# loop through all image files in the selected folder
$objects | ForEach-Object {
    Write-Output "Processing file: $($_.FullName)"
    try {
        # read the exif data from the image file
        Write-Output "Trying exif..."
        $img = New-Object System.Drawing.Bitmap($_.FullName)
        $exif = $img.GetPropertyItem(36867)
        if ($null -ne $exif) {
            $taken_time = [datetime]::MinValue
            if ([datetime]::TryParse([System.Text.Encoding]::ASCII.GetString($exif.Value), [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$taken_time)) {
                $new_filename = $taken_time.ToString('yyyy-MM-dd_HH-mm-ss') + $_.Extension
            } else {
                Write-Warning "Failed to parse EXIF timestamp for file: $($_.FullName)"
                continue
            }
        } else {
            # if exif data not available, fallback to file creation time
            Write-Output "Trying created_time..."
            $created_time = Get-Item $_.FullName | Select-Object -ExpandProperty CreationTime
            if ($null -eq $created_time) {
               Write-Warning "Failed to get creation time for file: $($_.FullName)"
               continue
            }
            $new_filename = $created_time.ToString('yyyy-MM-dd_HH-mm-ss') + $_.Extension
        }
        if ($null -eq $new_filename) {
            continue
        }
        # skip the file if it already has the new filename
        if ($_.Name -eq $new_filename) {
            Write-Warning "Skipping file because it already has the new filename: $($_.FullName)"
            continue
        }
    
        # rename the file with the new filename
        Rename-Item $_.FullName -NewName $new_filename
    } catch {
        Write-Output "Error: $($_.Exception)"
        Write-Output "Error details: $($_.ErrorDetails)"
        Write-Output "Error invocation info: $($_.InvocationInfo)"
        continue
    }
}
Write-Output "Finished processing all image files in $selected_path."

# SIG # Begin signature block
# MIIbmwYJKoZIhvcNAQcCoIIbjDCCG4gCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkqcvx8hUEizlNeO6QNynkkP7
# OJmgghYRMIIDBjCCAe6gAwIBAgIQacE1cVrK/bBHbXSgQheRqTANBgkqhkiG9w0B
# AQsFADAbMRkwFwYDVQQDDBBBVEEgQXV0aGVudGljb2RlMB4XDTIzMDUyMTE0NTI1
# MVoXDTI0MDUyMTE1MTI1MVowGzEZMBcGA1UEAwwQQVRBIEF1dGhlbnRpY29kZTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKGAZzieuDmrsJmyzd2yeBIo
# zkS6IbzTd0G48caP5k70KqjizQHs5PwNPC1YNBo0AUey+iyv4JyFcnkMVuKyoi8i
# a0vt7AW/h+q028uY4lQSZo4lC8YlQxAfhcs+ISRglq59ARhh+Gi2H0nbZTg9bHNM
# kkLhLosWTFfXWSHJDcWJiaHni68L534qN+J4MqsUWOpc1C6vaE2KEUxUjcaW9d5n
# 2S4cc9qTs2xCgZmJG6w4+CbUs8AYIJctOKCVzGWUkTWrx+mR8TlIbNVDIBRwXvHa
# XqUwR2NrhY3MpyWgOStNmH9iQM38HOwP7crgDFzaStdaWfGrq5RsLNFt0ybQOlUC
# AwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0G
# A1UdDgQWBBSK7ysetGKkdKL+/OwI15/MyJf9+jANBgkqhkiG9w0BAQsFAAOCAQEA
# nRfhAS5+5iEHWZXzhaycmq78vEiGlnD1D1WT1mXTh91Px3gDY24TyGSG65pQf7kq
# n6AjoynKj9f8E9bhwPB3Q5DAvlplk9D6VQba/Fv3cYBnOd9WJJYtap+6ofKSqkL0
# gQuNnJ94l/SrjfMoLslCKMcgEwQZyW//WvpzAN7vFt7Re4FcL7whExBNHDPEei2O
# fw40+TUZqNPdJcf8PIqP/7dGY8h7n/bGNAsSz+ejGYCPxCGavzPiyF+FrGE76d75
# JnBQ34YBFfAVaisz0/7CoyqutTxA9owoy4+y+RXaPIqd12k1EYV4NbMlB20mDpwo
# p6Ik+AByGCWK8fn5U/vXnDCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ4ghAGFow
# DQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNl
# cnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMxMTEwOTIz
# NTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3Rl
# ZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQc2je
# u+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW61bG
# l20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU0RBE
# EC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzryc/N
# rDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17cjo+A
# 2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypukQF8
# IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaPZPfB
# aYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUlibaa
# RBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESVGnZi
# fvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2QXXe
# eqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZFX50g
# /KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8GA1UdEwEB
# /wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1UdIwQY
# MBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5BggrBgEF
# BQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBD
# BggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3Js
# My5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMBEGA1Ud
# IAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhfoKN0Gz22
# Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv9P+Aufih
# 9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZy51PpwYD
# E3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTVPeix3P0c
# 2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGyWfVVa88n
# q2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3AamfV6peKOK5
# lDCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQELBQAw
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290
# IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBU
# cnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTepl1Gh
# 1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt+Feo
# An39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r07G1
# decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dhgxnd
# X7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfAcsW6
# Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpHIEPj
# Q2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJSlREr
# WHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0z9JM
# q++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y99xh
# 3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBIDfV8j
# u2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXTdrnS
# DmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1Ud
# DgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFdZEzf
# Lmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# dwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAG
# A1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOC
# AgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoNqilp
# /GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8Vc40B
# IiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJodskr2d
# fNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6skHibB
# t94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82HhyS7
# T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HNT7ZA
# myEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8zOYdB
# eHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIXmVnK
# cPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZE/6/
# pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSFD/yY
# lvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwggbAMIIEqKADAgEC
# AhAMTWlyS5T6PCpKPSkHgD1aMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjIwOTIx
# MDAwMDAwWhcNMzMxMTIxMjM1OTU5WjBGMQswCQYDVQQGEwJVUzERMA8GA1UEChMI
# RGlnaUNlcnQxJDAiBgNVBAMTG0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDIyIC0gMjCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAM/spSY6xqnya7uNwQ2a26Ho
# FIV0MxomrNAcVR4eNm28klUMYfSdCXc9FZYIL2tkpP0GgxbXkZI4HDEClvtysZc6
# Va8z7GGK6aYo25BjXL2JU+A6LYyHQq4mpOS7eHi5ehbhVsbAumRTuyoW51BIu4hp
# DIjG8b7gL307scpTjUCDHufLckkoHkyAHoVW54Xt8mG8qjoHffarbuVm3eJc9S/t
# jdRNlYRo44DLannR0hCRRinrPibytIzNTLlmyLuqUDgN5YyUXRlav/V7QG5vFqia
# nJVHhoV5PgxeZowaCiS+nKrSnLb3T254xCg/oxwPUAY3ugjZNaa1Htp4WB056PhM
# kRCWfk3h3cKtpX74LRsf7CtGGKMZ9jn39cFPcS6JAxGiS7uYv/pP5Hs27wZE5FX/
# NurlfDHn88JSxOYWe1p+pSVz28BqmSEtY+VZ9U0vkB8nt9KrFOU4ZodRCGv7U0M5
# 0GT6Vs/g9ArmFG1keLuY/ZTDcyHzL8IuINeBrNPxB9ThvdldS24xlCmL5kGkZZTA
# WOXlLimQprdhZPrZIGwYUWC6poEPCSVT8b876asHDmoHOWIZydaFfxPZjXnPYsXs
# 4Xu5zGcTB5rBeO3GiMiwbjJ5xwtZg43G7vUsfHuOy2SJ8bHEuOdTXl9V0n0ZKVkD
# Tvpd6kVzHIR+187i1Dp3AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYD
# VR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgG
# BmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxq
# II+eyG8wHQYDVR0OBBYEFGKK3tBh/I8xFO2XC809KpQU31KcMFoGA1UdHwRTMFEw
# T6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRH
# NFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGD
# MIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYB
# BQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQEL
# BQADggIBAFWqKhrzRvN4Vzcw/HXjT9aFI/H8+ZU5myXm93KKmMN31GT8Ffs2wklR
# LHiIY1UJRjkA/GnUypsp+6M/wMkAmxMdsJiJ3HjyzXyFzVOdr2LiYWajFCpFh0qY
# QitQ/Bu1nggwCfrkLdcJiXn5CeaIzn0buGqim8FTYAnoo7id160fHLjsmEHw9g6A
# ++T/350Qp+sAul9Kjxo6UrTqvwlJFTU2WZoPVNKyG39+XgmtdlSKdG3K0gVnK3br
# /5iyJpU4GYhEFOUKWaJr5yI+RCHSPxzAm+18SLLYkgyRTzxmlK9dAlPrnuKe5NMf
# hgFknADC6Vp0dQ094XmIvxwBl8kZI4DXNlpflhaxYwzGRkA7zl011Fk+Q5oYrsPJ
# y8P7mxNfarXH4PMFw1nfJ2Ir3kHJU7n/NBBn9iYymHv+XEKUgZSCnawKi8ZLFUrT
# mJBFYDOA4CPe+AOk9kVH5c64A0JH6EE2cXet/aLol3ROLtoeHYxayB6a1cLwxiKo
# T5u92ByaUcQvmvZfpyeXupYuhVfAYOd4Vn9q78KVmksRAsiCnMkaBXy6cbVOepls
# 9Oie1FqYyJ+/jbsYXEP10Cro4mLueATbvdH7WwqocH7wl4R44wgDXUcsY6glOJcB
# 0j862uXl9uab3H4szP8XTE0AotjWAQ64i+7m4HJViSwnGWH2dwGMMYIE9DCCBPAC
# AQEwLzAbMRkwFwYDVQQDDBBBVEEgQXV0aGVudGljb2RlAhBpwTVxWsr9sEdtdKBC
# F5GpMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqG
# SIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3
# AgEVMCMGCSqGSIb3DQEJBDEWBBR13PIjRHr5TBfzEK2dIpdpMjFGujANBgkqhkiG
# 9w0BAQEFAASCAQAo6aDRsCXdDxEphdDA5xGVcrwjx0WZSh4gqRFJJ2AsDZggD7Ph
# wSJEQgcc7pyPR76prgf6wSqf93rgroQepnzgFO0HOhlJfOzqMM01Re/GpeN9ExoT
# 4uJiCra2l85DkPmx89dl6kMmXG2E2uuoEyEIoHPwc+9QP+8Lnbgz79rS5M2clXNd
# 2DdDscV6vcHbKgw0VoVy4qWzzmngyamkbku69iO2C6wiz/zmfEvcHJyaowDjf2AJ
# 9h0NU7/MogD77oP3wcPgC3Icy8+zySLExaO5YmDPJLH/DdWLDCtceu/Q+6MR5We4
# M78XaudiOF8ngs+LBjUh6HhWWE8oIJKdHwLYoYIDIDCCAxwGCSqGSIb3DQEJBjGC
# Aw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQQIQDE1pckuU+jwqSj0pB4A9WjANBglghkgBZQMEAgEF
# AKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIz
# MDUyMTE1MDQ1NFowLwYJKoZIhvcNAQkEMSIEIAtkuUwg/bXKVfmFAb1CxcRTqFvs
# fdKJ/KmX3g4/r8ktMA0GCSqGSIb3DQEBAQUABIICALpdg0SYAg8cn/BhKXwCypi7
# sO4azesddmrXw6AiXNYd9EeTEh2D+TscUGI5mnoAIdxq/I9ZvuUncjFsyIZ65Sta
# Xkvk098UnnySvbHxD70G2oBlx6DkgQsty0jp0RSOHQZNvRQdQ8vt24IbcrnYy6lD
# HOK13Bhql0xKNJqepD+JfrHU02p/tB01cuh6zx0rZw0NVBnS7n2AbToYAwwLECKJ
# H+nmaZiS99W76ZW3VxmjM6+1Nsgm9q1ziaj5jh8olDlGvtCmC9op1S0nQpazJLmO
# 9BpwvqD2qcsI7rPBp9iQbGf0JIBVz3AbAIn/fUdZDtx+gmEVmcFPYYAp3j/hII5l
# ZtCnRi740EKZHUVtapZ8dNp9hKa10Z8m/NVdGslDCIKvy6sIwYSP/VyMFLV2zjNN
# ZVBf4xaAS/MZHhalYEl3NPRcjRrLPh3a2NBRjWjMoJOA30bhHp2NR5BqjsDtqQYi
# k480EHGmEmI8eMDydBelh+C0EmUIQt4/75XcebwN53lyUTR8Ek041xF3LxIDlC8v
# BGyLEaJKCyEY0Erc+jU4silzjWm0XjWDPSsC6QjuRkA5Yo8Lh67qtUJ+UdE3v8h0
# 5c4R+7II1tl3XEEiPEAouZ3EaC0AnF5jJm3ap2xsJl4edYX9fTUkwIMVcthNN0Ak
# 2NJavk98ip/L5WtBYZWE
# SIG # End signature block
