    [CmdletBinding()]
    param
    (
        [Parameter (Mandatory = $false)]
        [object] $WebhookData
    )

    $IpAddress = (ConvertFrom-Json -InputObject $WebhookData.RequestBody).IpAddress
    write-output $IpAddress
    if ($IpAddress -eq $null) {break}

    $connectionName = "AzureRunAsConnection"
    
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    $connectionResult = Connect-AzAccount `
   -ServicePrincipal `
   -TenantId $servicePrincipalConnection.TenantId `
   -ApplicationId $servicePrincipalConnection.ApplicationId `
   -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

   $subscriptions= Get-AzSubscription | select-azSubscription

   $NsgName= "vce-vm-nsg"
   $RgName= "vce-rg"
   $location= "westeurope"

    $nsg = Get-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $RgName
    if (!$nsg){
        $nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
          -Name "RDP"  `
          -Protocol "Tcp" `
          -Direction "Inbound" `
          -Priority 1000 `
          -SourceAddressPrefix $ip `
          -SourcePortRange * `
          -DestinationAddressPrefix * `
          -DestinationPortRange 3389 `
          -Access "Allow"

        $nsg = New-AzNetworkSecurityGroup `
          -ResourceGroupName $resourcegroupname `
          -Location $location `
          -Name "$prefix-nsg" `
          -SecurityRules $nsgRuleSSH 
    }
    
    $rule= $nsg | Get-AzNetworkSecurityRuleConfig -Name "RDP" 
    if (!$rule){}
    $ips = $rule.SourceAddressPrefix
    $ips
    $ips += $IpAddress

    #$nsg = Get-AzNetworkSecurityGroup -Name vce-vm-nsg -ResourceGroupName vce-rg
    Set-AzNetworkSecurityRuleConfig -SourceAddressPrefix $ips -NetworkSecurityGroup $nsg -Name RDP `
        -Protocol Tcp -SourcePortRange * `
        -DestinationPortRange 3389 -DestinationAddressPrefix * `
        -Access allow -Priority 300 -Direction Inbound

    $null = Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg