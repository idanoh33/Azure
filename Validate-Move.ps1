## vairables ##

$srcsub = 'xxx-xxx-xxx-xxx'
$dstsub = 'xxx-xxx-xxx-xxx'

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Validate-Move {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        $subscriptionid,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        $resourcegroup,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        $targetsub,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        $targetrgname
    )

    Begin {
        function Get-AzCachedAccessToken() {
            $ErrorActionPreference = 'Stop'
  
            if (-not (Get-Module Az.Accounts)) {
                Import-Module Az.Accounts
            }
            $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
            if (-not $azProfile.Accounts.Count) {
                Write-Error "Ensure you have logged in before calling this function."    
            }
  
            $currentAzureContext = Get-AzContext
            $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
            Write-Debug ("Getting access token for tenant" + $currentAzureContext.Tenant.TenantId)
            $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
            $token.AccessToken
        }

        # Select the source subscription, so we can dynamically get a list of resources
        #if ((Get-AzContext).Subscription.id -ne $subscriptionid) {Select-AzSubscription -subscription $subscriptionid}
        $resourceids = (get-azresource -resourcegroupname $resourcegroup | where { $_.ResourceType -notlike "*extensions*" }).ResourceId | ConvertTo-Json

        $BearerToken = ('Bearer {0}' -f (Get-AzCachedAccessToken))
        $RequestHeader = @{
            "Content-Type"  = "application/json";
            "Authorization" = "$BearerToken"
        }
        $Body = @"
                {
                 "resources": $resourceids ,
                 "targetResourceGroup": "/subscriptions/$targetsub/resourceGroups/$targetrgname"
                }
"@
    }
    Process {
        $URI = "https://management.azure.com/subscriptions/$subscriptionid/resourceGroups/$resourcegroup/validateMoveResources?api-version=2019-10-01"
        try {

            $response = Invoke-WebRequest -Uri $URI -Method POST -body $body -header $RequestHeader -ErrorAction Stop
            $validation = $true

        }
        catch {
            $_.exception
            $validation = $false
        }

    }
    End {
        Write-Output "$resourcegroup validation is $validation"
    }
}


$resourceGroups = Get-AzResourceGroup
Select-AzSubscription -Subscription $srcsub


foreach ($resourceGroup in $resourceGroups) {
    
    if ((Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName).count -gt 1 ) {
                
        Validate-Move -subscriptionid $srcsub -resourcegroup $resourceGroup.resourceGroupName -targetsub $dstsub -targetrgname $resourceGroup.resourceGroupName            
    }
    else { Write-Output "$($resourceGroup.resourceGroupName) has less than 2 resources" }
    
}


