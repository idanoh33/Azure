$CertificateOutputPath = "C:\Temp\certificate-str.cer"

# Create root new self sign certificate in current user
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
    -Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

# Create child new self sign certificate in current user
New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
    -Subject "CN=P2SChildCert" -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

# Export certificate to c:\temp\certificate.cer
$cert | Export-Certificate -FilePath $CertificateOutputPath -Type CERT -NoClobber-Force

# Convert certificate to base64
$base64Certificate = [convert]::tobase64string((get-item cert:\currentuser\my\$($Cert.Thumbprint)).RawData) 
$base64Certificate | Set-Content $CertificateOutputPath

$base64Certificate | clip.exe

# Copy base64 certificate string
Get-Content $CertificateOutputPath | clip.exe

# Open base64 certificate with notepad
notepad $CertificateOutputPath
