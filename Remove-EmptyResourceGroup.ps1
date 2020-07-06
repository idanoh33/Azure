# The script will remove empty resource groups

Param($subscriptionId)

get-azsubscription -SubscriptionId $subscriptionId | Select-AzSubscription

$ResourceGroups= Get-AzResourceGroup

foreach ($ResourceGroup in $resourceGroups)
{
    $resources = Get-AzResource -ResourceGroupName  $ResourceGroup.ResourceGroupName
    if ($resources.count -eq 0)
    {
        $ResourceGroup | Remove-AzResourceGroup -Force -Verbose
    }
}
