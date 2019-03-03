    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $location,

        # Param2 help description
        $sourceVHDURI = 'https://backboxstgeastus.blob.core.windows.net/eastus-cont/BackBoxv6tryFixed.vhd',

        $sasToken = 'sp=r&st=2019-03-03T13:21:27Z&se=2025-01-01T21:21:27Z&spr=https&sv=2018-03-28&sig=WbuxNPNEPTIWw7qCrGbzXyC90Z4ZDwr8EKquu3wXiI8%3D&sr=b'
    )
    
    $ErrorActionPreference = 'stop'
    $resourceGroupName = "Backbox-rg"
    $storageaccountname = "backboxstg" + ( -join (1..100 |Get-Random -Count 6))
    $contname = "$storageaccountname-cont"
    $vhd = Split-Path -Leaf $sourceVHDURI 
   
    if (!(Get-AzureRmResourceGroup -name $resourceGroupName -ErrorAction SilentlyContinue )) {
        $RG = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
    } else {$RG = Get-AzureRmResourceGroup -name $resourceGroupName}

    $stg = New-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storageaccountname -SkuName Standard_LRS -Location $location -Kind StorageV2 -AccessTier Cool
    $cont = New-AzureRmStorageContainer -StorageAccountName $storageaccountname -ResourceGroupName $rg.ResourceGroupName -Name $contname

    Write-Output "Start Time: $(get-date)"
    Write-Output "Start copy backbox VHD"

    $blob = Start-AzureStorageBlobCopy -AbsoluteUri ($sourceVHDURI + $sasToken) -DestContainer $cont.Name -DestBlob $vhd -DestContext $stg.Context
    $blob| Get-AzureStorageBlobCopyState

    Do {Write-Output "copy status is: $(($blob| Get-AzureStorageBlobCopyState).Status)"; sleep -Seconds 10} Until (($blob| Get-AzureStorageBlobCopyState).Status -ne "Pending")
    Write-Output "End Time: $(get-date)"

    $newUri = "$($blob.context.BlobEndPoint)" + "$($cont.name)/" + "$vhd" #+ $sas
    Write-Output "New URI: $newUri"  


