[CmdletBinding()]
param
(
    [Parameter (Mandatory = $false)]
    [object] $WebhookData,
    [String] $subscriptionId = ''

)

$VmName = (ConvertFrom-Json -InputObject $WebhookData.RequestBody).VmName
$RgName = (ConvertFrom-Json -InputObject $WebhookData.RequestBody).RgName
write-output $VmName
if ($VmName -eq $null) { break }

$connectionName = "AzureRunAsConnection"
    
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

$connectionResult = Connect-AzAccount `
    -ServicePrincipal `
    -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

$subscriptions = Get-AzSubscription -SubscriptionId $subscriptionId| select-azSubscription


$Vm= get-azvm -Name $vmName -ResourceGroupName $RgName
if($Vm.name -eq $vmName){$vm | stop-azvm -Force}