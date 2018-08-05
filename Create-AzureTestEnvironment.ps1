Login-AzureRmAccount 
$subscription = Get-AzureRmSubscription |  Out-GridView -PassThru
Set-AzureRmContext -SubscriptionId $subscription.Id

$ErrorActionPreference = 'stop'
$vmName = "IISVM"
$vNetName = "myIISSQLvNet"
$resourceGroup = "myIISSQLGroup"
$location = 'East US'
$subnetName= 'subnet-01'
$keyvaultName = 'iis-Vault2'

# Create Resource Group
$RG= New-AzureRmResourceGroup -Name $resourceGroup -Location $location
# create Vnet
$VNET= New-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $resourceGroup -Location $location -AddressPrefix '10.0.0.0/16'

# create Subnet
$subnet= Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $VNET -Name $subnetName -AddressPrefix '10.0.0.0/24'
Set-AzureRmVirtualNetwork -VirtualNetwork $VNET 


# Create NSG
$NSG= New-AzureRmNetworkSecurityGroup -Name "myNetworkSecurityGroup" -ResourceGroupName $resourceGroup -Location $location

# Create Key Vauly
$vault= New-AzureRmKeyVault -VaultName $keyvaultName -ResourceGroupName $resourceGroup -Location $location


# Create Vault Certificate policy
$policy = New-AzureKeyVaultCertificatePolicy `
    -SubjectName "CN=iisvm-fb0bb3.eastus.cloudapp.azure.com" `
    -SecretContentType "application/x-pkcs12" `
    -IssuerName Self `
    -ValidityInMonths 12

Add-AzureKeyVaultCertificate `
    -VaultName $keyvaultName `
    -Name "mycert" `
    -CertificatePolicy $policy 



New-AzureRmVm `
    -ResourceGroupName $resourceGroup `
    -Name $vmName `
    -Location $location `
    -VirtualNetworkName $vNetName `
    -SubnetName $subnetName `
    -SecurityGroupName "myNetworkSecurityGroup" `
    -AddressPrefix 10.0.0.0/24 `
    -PublicIpAddressName "myIISPublicIpAddress" `
    -OpenPorts 80,443,3389 `
    -Size Standard_D2s_v3 


Set-AzureRmVMExtension `
    -ResourceGroupName $resourceGroup `
    -ExtensionName IIS `
    -VMName $vmName `
    -Publisher Microsoft.Compute `
    -ExtensionType CustomScriptExtension `
    -TypeHandlerVersion 1.4 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server,Web-Asp-Net45,NET-Framework-Features"}' `
    -Location $location

