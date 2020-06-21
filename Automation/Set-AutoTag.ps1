$connectionName = "AzureRunAsConnection"
    
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

$connectionResult = Connect-AzAccount `
    -ServicePrincipal `
    -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

$subscriptions = Get-AzSubscription | select-azSubscription

foreach ($subscription in $subscriptions) {

    # Select Azure subscription
    Select-azSubscription -SubscriptionId $subscription.SubscriptionId

    # Resolve Azure virtual machines
    $resources = Get-AzVm | Where-Object { $_.tags.Creator -eq $null }

    Write-output "Found $($resources.Count) total resources"

    foreach ($resource in $resources) {
        # Search for creator in activity logs
        $caller = Get-azLog -ResourceId $resource.id -StartTime (get-date).AddDays(-90) -EndTime (get-date) | `
            Where-Object { $_.Authorization.Action -like "*/write" } | Sort-Object EventTimestamp | Select-Object caller, EventTimestamp -First 1
        
        # Create Owner email tag if not exist
        if ($caller -ne $null -and $caller.caller -match "@") {
            write-output "Setting $($caller.caller) as Creator for $($resource.Name)"
            $formatDate = (($caller.EventTimestamp) -split ' ')[0]
            $tags = (get-azResource -ResourceId $resource.id).tags
            
            if ($tags -eq $null) {
                $tags = @{CreationDate = $formatDate; Creator = $caller.caller }
            }
            else {
                $tags.add("CreationDate", "$formatDate")
                $tags.add("Creator", "$($caller.caller)")
            }
            
            Set-azResource -ResourceId $resource.id -Tag $tags -Force
        }
        else {
            Write-Output "No Creator was found, Creator set to Unknown for $($resource.Name)"
            $tags = (get-azResource -ResourceId $resource.id).tags
            if ($tags -eq $null) {
                $tags = @{CreationDate = "Unknown"; Creator = "Unknown" }
            }
            else {
                $tags.add("CreationDate", "Unknown")
                $tags.add("Creator", "Unknown")
            }
            Set-azResource -ResourceId $resource.id -Tag $tags -Force
        }
    }
}

