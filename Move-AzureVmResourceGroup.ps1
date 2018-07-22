<#
.Synopsis
   This Script will create new VM in a new Resource Group
.DESCRIPTION
   This script will copy OS and data disks if exist, Remove the vm if the switch 'RemoveSourceVM' is on, and create it into a new Resource Group
   the script will create new NIC for the VM if switch 'RemoveSourceVM' is off, if not it will remove the VM and assign the old nic to new vm and will move it the new resource group
.EXAMPLE
   .\Move-AzureVmResourceGroup.ps1 -sourceResourceGroupName rg-test-1 -targetResourceGroupName rg-test-2 -SourceVMname test-vm-1 -Verbose
.EXAMPLE
   .\Move-AzureVmResourceGroup.ps1 -sourceResourceGroupName rg-test-1 -targetResourceGroupName rg-test-2 -SourceVMname test-vm-1 -RemoveSourceVM -Verbose
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
        $sourceResourceGroupName,

        # Param2 help description
        $targetResourceGroupName,

        # Source VM
        $SourceVMname,

        [Switch]$RemoveSourceVM
    )

    Begin
    {
        $ErrorActionPreference = 'stop'
        
        # start logging
        $date= get-date -Format s
        Start-Transcript "c:\temp\Move-AzureVmResourceGroup$date.log" -Force

        # Check azure login
        if (! (Get-AzureRmContext -ErrorAction SilentlyContinue ))
        {
            Login-AzureRmAccount
            $subscription= Get-AzureRmSubscription | ogv -PassThru
            $subscription | Select-AzureRmSubscription
        }

        Write-Output "Resolving VM $SourceVMname"
        # Resolve source VM and status
        $SourceVM= get-azurermvm -Name $SourceVMname -ResourceGroupName $sourceResourceGroupName
        $SourceVmStatus= get-azurermvm -Name $SourceVMname -ResourceGroupName $sourceResourceGroupName -Status
        
        # Stopping VM
        Write-Output "Stopping $SourceVMname"
        if (($SourceVmStatus.Statuses)[-1].displaystatus -notlike "VM deallocated" ) {$SourceVM | Stop-AzureRmVM -Force}

        # Reslove Nic and Subnet
        $NicName = Split-Path $SourceVM.NetworkProfile.NetworkInterfaces.id -Leaf 
        $Nic= Get-AzureRmNetworkInterface -Name $NicName -ResourceGroupName $sourceResourceGroupName
        $SubnetId= $Nic.IpConfigurations.subnet.id
        
        # Reslove OS disk
        $OSDiskName= $SourceVM.StorageProfile.OsDisk.name
        
        # Create Target resource Group if not exist
        $targetResourceGroup = Get-AzureRmResourceGroup $targetResourceGroupName -ErrorAction SilentlyContinue
        if (!($targetResourceGroup))
        { New-AzureRmResourceGroup $targetResourceGroupName -Location $SourceVM.Location }
    }
    Process
    {
        Write-Output "Copy $SourceVMname Disks"

        #Get the source managed disk
        $managedDisk= Get-AzureRMDisk -ResourceGroupName $sourceResourceGroupName -DiskName $OSDiskName
        
        # Copy Os Disk
        $diskConfig = New-AzureRmDiskConfig -SourceResourceId $managedDisk.Id -Location $managedDisk.Location -CreateOption Copy 
        
        #Create a new managed disk in the target subscription and resource group
        $newOSDisk= New-AzureRmDisk -Disk $diskConfig -DiskName $OSDiskName -ResourceGroupName $targetResourceGroupName
        
        # Copy Data disks
        $DataDisks= $SourceVM.StorageProfile.DataDisks
        if ($DataDisks.count -gt 0)
        {
            $newDataDisks= @{}
            $count= 1
            foreach ($datadisk in $DataDisks)
            {
                
                #Get the source managed disk
                $managedDisk= Get-AzureRMDisk -ResourceGroupName $sourceResourceGroupName -DiskName $DataDisk.name
            
                $diskConfig = New-AzureRmDiskConfig -SourceResourceId $managedDisk.Id -Location $managedDisk.Location -CreateOption Copy 
            
                #Create a new managed disk in the target subscription and resource group
                $newDataDisks.add($count,(New-AzureRmDisk -Disk $diskConfig -DiskName $DataDisk.name -ResourceGroupName $targetResourceGroupName).Id)
                
                $count++
            
            } # foreach end
        } # if end
        
        
        if ($RemoveSourceVM){
            
            # Remove Azure VM
            Write-Output "Remove $SourceVMname VM"
            Remove-AzureRmVM -Name $SourceVM.name -ResourceGroupName $sourceResourceGroupName
            
            # Move Nic to new Resource Group
            Move-AzureRmResource -ResourceId $Nic.Id -DestinationResourceGroupName $targetResourceGroupName -Force

            $newNic= Get-AzureRmNetworkInterface -Name $Nic.Name -ResourceGroupName $targetResourceGroupName
        }
        else {
            # Create New NIC
            $SubnetId
            $NewNic = New-AzureRmNetworkInterface -Name "$($SourceVM.name)-$(get-random -Minimum 10000 -Maximum 99999)-nic" -ResourceGroupName $targetResourceGroupName -Location $SourceVM.Location -SubnetId $SubnetId
        }

        # Create VM config data
        $newVmConfig = New-AzureRmVMConfig -VMName $SourceVM.Name -VMSize $SourceVM.HardwareProfile.VmSize
        
        # Add NIC to config data
        $newVm = Add-AzureRmVMNetworkInterface -VM $newVmConfig -Id $newnic.Id

        # Add OS disk  to config data
        $newVm = Set-AzureRmVMOSDisk -VM $newvm -ManagedDiskId $newOSDisk.Id -CreateOption Attach -Windows

        # Add Data disks to config data
        if ($DataDisks.count -gt 0)
        {
            $count=1
            foreach ($datadisk in $DataDisks){
            
            $newdataDisk= $newDataDisks.$count
            $newDataDiskName= Split-Path $newdataDisk -Leaf
            
            $newVm = Add-AzureRmVMDataDisk -VM $newvm -Name $newDataDiskName -CreateOption Attach -ManagedDiskId $newdataDisk -Lun $count
            $count++
            } # if end
        } # foreach end

    }
    End
    {
        # Create New VM
        New-AzureRmVM -ResourceGroupName $targetResourceGroupName -Location $SourceVM.Location -VM $newVm  
        
        # Validate VM
        $NewVM= get-azurermvm -Name $SourceVMname -ResourceGroupName $targetResourceGroupName -Status
        if (($NewVM.Statuses)[-1].displaystatus -notlike "Running" ) {Write-Output "$($NewVM.Name) is running"}
    }
