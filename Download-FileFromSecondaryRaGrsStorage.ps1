﻿<#
.Synopsis
   This Script will Download files from Azure RA-GRS storage (secondary replica)
.DESCRIPTION
   This script will 
.EXAMPLE
   .\
.EXAMPLE
   .\
#>

    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $storageAccountName= "tessstgidan",
        
        $container= "xyz",

        $file= "AzureDDoSProtectionServiceOfferings.png",

        $ResourceGroupName= "teststg-rg",

        $OutputFolderPath= "c:\temp\",

        $TimeFrameInHours = 2

    )

    Begin
    {
        $ErrorActionPreference = 'stop'
        
        # start logging
        $date= get-date -Format s
        Start-Transcript "c:\temp\Move-AzureVmResourceGroup$date.log" -Force

        # Check azure login
        if (-not (Get-AzureRmContext -ErrorAction Ignore))
        {
            Login-AzureRmAccount
            $subscription= Get-AzureRmSubscription | ogv -PassThru
            $subscription | Select-AzureRmSubscription
        }

        $OutputFilePath = $OutputFolderPath + $file

    }
    Process
    {
       
       
    # Resolve storage account
    $stg= Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $ResourceGroupName
    Write-Output "Your Primary Location is $($stg.PrimaryLocation)"
    Write-Output "Your Secondary Location is $($stg.SecondaryLocation)"

    $StartTime = Get-Date
    $EndTime = $startTime.AddHours($TimeFrameInHours)
    
    
    $sasToken = New-AzureStorageBlobSASToken -Container $container -Blob $file -Permission rwd -StartTime $StartTime -ExpiryTime $EndTime -Context $stg.Context

    $secondaryUri= $stg.SecondaryEndpoints.blob + "$container" + "/$file" + $sasToken
    $primaryUri = $stg.PrimaryEndpoints.Blob + "$container" + "/$file" + $sasToken
    
    

    }
    End
    {
        Invoke-WebRequest -Uri $secondaryUri -OutFile $OutputFilePath
        
    }