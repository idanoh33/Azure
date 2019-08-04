#param([String]$password)
$domainname= "lab.local"
$username= "idadmin"
$user= "$domainname\$username"
$password= $args[0] 
$password > c:\pass.txt
$cred = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password

Add-Computer -DomainName $domainname -Credential $cred -force
