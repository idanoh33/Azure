# Define variables
$resourceGroupName = "Backbox-rg"
$storageaccountname = "backboxstg" + ( -join (1..100 |Get-Random -Count 6))
$contname = "$storageaccountname-cont"
$location = read-host "enter location"
$sourceVHDURI = 'https://backboxstgeastus.blob.core.windows.net/eastus-cont/BackBoxv6tryFixed.vhd'
$vhd = Split-Path -Leaf $sourceVHDURI 

if (!(Get-AzureRmResourceGroup -name $resourceGroupName -ErrorAction SilentlyContinue )) {
    $RG = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
} else {$RG = Get-AzureRmResourceGroup -name $resourceGroupName}

$stg = New-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storageaccountname -SkuName Standard_LRS -Location $location -Kind StorageV2 -AccessTier Cool
$cont = New-AzureRmStorageContainer -StorageAccountName $storageaccountname -ResourceGroupName $rg.ResourceGroupName -Name $contname

Write-Output "Start Time: $(get-date)"
Write-Output "Start copy backbox VHD"

$blob = Start-AzureStorageBlobCopy -AbsoluteUri $sourceVHDURI  -DestContainer $cont.Name -DestBlob $vhd -DestContext $stg.Context
$blob| Get-AzureStorageBlobCopyState

Do {Write-Output "copy status is: $(($blob| Get-AzureStorageBlobCopyState).Status)"; sleep -Seconds 10} Until (($blob| Get-AzureStorageBlobCopyState).Status -ne "Pending")
Write-Output "End Time: $(get-date)"

#$sas = New-AzureStorageBlobSASToken -Container $cont.Name -Blob $blob -Context $stg.Context -ExpiryTime 10000 -Permission rwd
$newUri = "$($blob.context.BlobEndPoint)" + "$($cont.name)/" + "$vhd" #+ $sas

Write-Output "New URI: $newUri"   