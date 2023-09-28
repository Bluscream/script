function Set-Signature {
    [CmdletBinding()]
 
    [Alias('sig')]
 
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
 
    begin{
        $Certificate = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
            Where-Object -Property NotAfter -GT (Get-Date) |
            Sort-Object -Property NotAfter -Descending |
            Select-Object -First 1
    }
 
    process{
        foreach ($Path in $FilePath) {
            $TimeStampServer = @(
                'http://timestamp.verisign.com/scripts/timstamp.dll'
                'http://timestamp.globalsign.com/scripts/timstamp.dll'
                'http://timestamp.comodoca.com/authenticode'
            ) | Get-Random
 
            $Params = @{
                Certificate = $Certificate
                TimestampServer = $TimeStampServer
                HashAlgorithm = 'SHA256'
                FilePath = $Path
                Verbose = $True
            }
 
            Set-AuthenticodeSignature @Params
        }
    }
}