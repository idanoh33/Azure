param([String]$password)
$domainname= "lab.local"
$username= "idadmin"
$user= "$domainname\$username"
$password= $password | ConvertTo-SecureString -AsPlainText -Force

$cred = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password

Add-Computer -DomainName $domainname -Credential $cred
