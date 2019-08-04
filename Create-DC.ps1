## Enter your domain name e.g. lab.local 
## Enter netBios Name e.g. lab 
## Enter safe password e.g. Passw0rd 
 
$regkey = test-path hklm:\software\FTCAD 
if ($regkey -eq $true) {exit} 
else { 
# Turn Off Windows Firewall 
netsh advfirewall set allprofiles state off 
# Set Winrm trust for remote powershell 
Set-Item wsman:\localhost\client\trustedhosts * -Force 
# Install ADDS prerequisites 
Add-WindowsFeature RSAT-AD-Tools 
Add-WindowsFeature -Name 'ad-domain-services' -IncludeAllSubFeature -IncludeManagementTools 
Add-WindowsFeature -Name 'dns' -IncludeAllSubFeature -IncludeManagementTools  
Add-WindowsFeature -Name 'gpmc' -IncludeAllSubFeature -IncludeManagementTools 
REG ADD HKLM\Software\FTCAD /v Data /t Reg_SZ /d 'Installed' 
# Windows PowerShell script for AD DS Deployment 
$domainname = 'lab.local'  
$netbiosName = 'lab'  
$safemodepassword = 'Passw0rd' | ConvertTo-SecureString -AsPlainText -Force 
Import-Module ADDSDeployment 
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath 'C:\Windows\NTDS' `
-DomainMode 'Win2012' `
-DomainName $domainname `
-DomainNetbiosName $netbiosName `
-ForestMode 'Win2012' `
-InstallDns:$True `
-LogPath 'C:\Windows\NTDS' `
-NoRebootOnCompletion:$false `
-SafeModeAdministratorPassword $safemodepassword `
-SysvolPath 'C:\Windows\SYSVOL' `
-Force:$true} 
# POWERSHELL TO EXECUTE ON REMOTE SERVER ENDS HERE
