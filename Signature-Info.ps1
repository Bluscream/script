param(
 
[Parameter(
    Mandatory,
    Position = 0,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName
)]
[ValidateScript({Test-Path -Path $PSItem})]
[ValidateNotNullOrEmpty()]
[string[]]$FilePath
)
Get-AuthenticodeSignature -FilePath $FilePath
Get-AuthenticodeSignature -FilePath $FilePath | Select-Object -Property Path, Status, StatusMessage, SignatureType, @{Name='SubjectName';Expression={$_.SignerCertificate.Subject}}, @{Name='SubjectIssuer';Expression={$_.SignerCertificate.Issuer}}, @{Name='SubjectSerialNumber';Expression={$_.SignerCertificate.SerialNumber}}
