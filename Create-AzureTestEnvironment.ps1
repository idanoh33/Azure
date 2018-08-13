$envSuffix= "1" 
$ErrorActionPreference = 'stop'
$vmName = "VM-" + $envSuffix
$vNetName = "vnet-" + $envSuffix
$resourceGroup = "ENV-RG-" + $envSuffix
$location = 'East US'
$subnetName= 'subnet-01'
$keyvaultName = 'iis-Vault'
$certificateName= "mycert1"
$NSGname= "nsg-" + $envSuffix 
$ipinfo = Invoke-RestMethod http://ipinfo.io/json 
$PublicIpName = $vmName + (Get-Random)
$VnetAddressPrefix = '10.0.0.0/16'
$SubnetAdressSpace = '10.0.0.0/24'
$newAvailSetName = "AvailabilitySet-" + $envSuffix
$vmSize= "Standard_B2ms"

if (-not (Get-AzureRmContext -ErrorAction Ignore) ){
Login-AzureRmAccount 
$subscription = Get-AzureRmSubscription |  Out-GridView -PassThru
Set-AzureRmContext -SubscriptionId $subscription.Id
}

# Create Resource Group
$RG= New-AzureRmResourceGroup -Name $resourceGroup -Location $location
# create Vnet
$VNET= New-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $resourceGroup -Location $location -AddressPrefix $VnetAddressPrefix

# create Subnet
$subnet= Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $VNET -Name $subnetName -AddressPrefix $VnetAddressPrefix
Set-AzureRmVirtualNetwork -VirtualNetwork $VNET 

# Create NSG rules
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix $ipinfo.ip  `
     -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

$rule2 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix $ipinfo.ip `
    -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443 

# Create NSG
$NSG= New-AzureRmNetworkSecurityGroup -Name "$NSGname" -ResourceGroupName $resourceGroup -Location $location -SecurityRules $rule1,$rule2

# Create new availability set if it does not exist
    $availSet = Get-AzureRmAvailabilitySet `
       -ResourceGroupName $resourceGroup `
       -Name $newAvailSetName `
       -ErrorAction Ignore
    if (-Not $availSet) {
    $availSet = New-AzureRmAvailabilitySet `
       -Location $location `
       -Name $newAvailSetName `
       -ResourceGroupName $resourceGroup `
       -PlatformFaultDomainCount 2 `
       -PlatformUpdateDomainCount 2 `
       -Sku Aligned
    }

# Create VM
$vm = New-AzureRmVm `
    -ResourceGroupName $resourceGroup `
    -Name $vmName `
    -Location $location `
    -VirtualNetworkName $vNetName `
    -SubnetName $subnetName `
    -SecurityGroupName $NSGname `
    -AddressPrefix $SubnetAdressSpace `
    -PublicIpAddressName $PublicIpName `
    -OpenPorts 80,443,3389 `
    -Size $vmSize `
    -AvailabilitySetName $newAvailSetName


Set-AzureRmVMExtension `
    -ResourceGroupName $resourceGroup `
    -ExtensionName IIS `
    -VMName $vmName `
    -Publisher Microsoft.Compute `
    -ExtensionType CustomScriptExtension `
    -TypeHandlerVersion 1.4 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server,Web-Asp-Net45,NET-Framework-Features"}' `
    -Location $location


$FQDN= (Get-AzureRmPublicIpAddress -Name $PublicIpName -ResourceGroupName $resourceGroup).DnsSettings.Fqdn

$keyvaultName="testvaultidan"
$kv= New-AzureRmKeyVault -VaultName $keyvaultName `
    -ResourceGroup $resourceGroup `
    -Location $location `
    -EnabledForDeployment

$policy = New-AzureKeyVaultCertificatePolicy `
    -SubjectName "CN=$FQDN" `
    -SecretContentType "application/x-pkcs12" `
    -IssuerName Self `
    -ValidityInMonths 12

$kvcertificate = Add-AzureKeyVaultCertificate `
    -VaultName $keyvaultName `
    -Name $certificateName `
    -CertificatePolicy $policy 

#$cred = Get-Credential

Start-Sleep -Seconds 60

$certURL=(Get-AzureKeyVaultSecret -VaultName $keyvaultName -Name $certificateName).id

$vm=Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName
$vaultId=(Get-AzureRmKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName).ResourceId

$vm = Add-AzureRmVMSecret -VM $vm -SourceVaultId $vaultId -CertificateStore "My" -CertificateUrl $certURL
# In case of duplicate error use the uncomment the following
# $vm = remove-AzureRmVMSecret -VM $vm -SourceVaultId $vaultId
# $vm = Add-AzureRmVMSecret -VM $vm -SourceVaultId $vaultId -CertificateStore "My" -CertificateUrl $certURL
Update-AzureRmVM -ResourceGroupName $resourceGroup -VM $vm



############ Set IIS Certificate

$PublicSettings = '{
    "fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/secure-iis.ps1"],
    "commandToExecute":"powershell -ExecutionPolicy Unrestricted -File secure-iis.ps1"
}'

Set-AzureRmVMExtension -ResourceGroupName $resourceGroup `
    -ExtensionName "IIS" `
    -VMName $vmName `
    -Location $location `
    -Publisher "Microsoft.Compute" `
    -ExtensionType "CustomScriptExtension" `
    -TypeHandlerVersion 1.8 `
    -SettingString $publicSettings