[OutputType("PSAzureOperationResponse")]
param
(
    [Parameter (Mandatory = $false)]
    [object] $WebhookData,
    [String] $subscriptionId,
    [String] $connectionName,
    [String] $vaultName,
    [String] $resourceGroupName
)

$ErrorActionPreference = 'Stop'


Enable-AzureRMAlias -Scope Process
Import-module az.accounts
Import-module Az.RecoveryServices
# Get the connection "AzureRunAsConnection "
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

"Logging in to Azure..."
login-AzAccount `
    -ServicePrincipal `
    -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

# Select Azure subscription
Select-AzSubscription -SubscriptionId $subscriptionId

# Resolve recovery services vault
$vault = Get-AZRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroupName
$SQLDB = Get-AzRecoveryServicesBackupItem -workloadType MSSQL -BackupManagementType azureworkload -VaultId $vault.id

# Resolve Webhookdata 
$WebhookBody = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
if (!$WebhookBody) { write-output "webhookbody is not available" }

# Resolve table
$table = $WebhookBody.data.alertcontext.SearchResults.tables
if (!($table.rows)) { write-output "table.rows is not available" }

# Create backup items Array
$array = [System.Collections.Generic.List[PSCustomObject]]::New()
$table.rows | foreach-object { $array.add($_[-1]) } 

# Disable backup
foreach ($item in $array) {
    $dbname = ($item -split ';')[-1]
    write-output "item: $dbname" 
    
    $db = $SQLDB | where-object FriendlyName -eq $dbname
    write-output "db: $db" 
    
    if ($db) {
        write-output "Disable protection for $dbname"
        Disable-AzRecoveryServicesBackupProtection -Item $db -VaultId $Vault.ID -verbose -confirm:$false -Force
    }
}

