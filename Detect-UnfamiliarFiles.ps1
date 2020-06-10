<#
.Synopsis
   This script will detect unfamiliar files and remove them
.DESCRIPTION
   This script will detect unfamiliar files by the suffix parameter and remove them
   in the end The script will add to the registrey the scan result (failed, success or incomplete)
   DryRun parameter is use to run the scan without the removal
.EXAMPLE
   Detect-UnfamiliarFiles -Suffix ps1
.EXAMPLE
   Detect-UnfamiliarFiles -Suffix ps1 -companyName "Neway" -dryRun
#>
function Detect-UnfamiliarFiles {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $Suffix,
        $companyName = "Neway",
        [switch]$dryRun
    )

    Begin {
        # Start logging
        Start-Transcript $env:TEMP\Detect-UnfamiliarFiles.log

        $filesToDelete = @()

        # resolve disks partitions
        $partitions = Get-Partition | where type -eq basic
    }
    Process {
        foreach ($partition in $partitions) {
            # Find relevant files with the required extention
            $filesToDelete += Get-ChildItem "$($partition.DriveLetter):\" -Recurse -Include "*.$Suffix" 
        }
    }
    End {
        $count = 1
        foreach ($file in $filesToDelete) {
            # Show Progress 
            Write-Progress -Activity "Deleting files" -Status "Deleting Files $count" -PercentComplete ($count / $filesToDelete.count*100)
            Write-Output "Delete $($file.fullname)"
            
            # Delete files
            if ($dryRun) { Remove-Item -Path $file.fullname -WhatIf }
            else { Remove-Item -Path $file.fullname }
            
            $count++
        }
        
        # validate result by resolve files with required extention again
        $validation = (Get-ChildItem "$($partition.DriveLetter):\" -Recurse -Include "*.$Suffix").count
        
        # Create registery key with script result
        if (!(Test-Path -Path "HKLM:\SOFTWARE\$companyName")) { New-Item -Path "HKLM:\SOFTWARE\" -Name $companyName }
        switch ($validation) {
            ($validation -eq 0) { New-ItemProperty -Path "HKLM:\SOFTWARE\$companyName" -Name scanStatus -Value success -Force }
            ($validation -eq $filesToDelete.count) { New-ItemProperty -Path "HKLM:\SOFTWARE\$companyName" -Name scanStatus -Value failed -Force }
            default { New-ItemProperty -Path "HKLM:\SOFTWARE\$companyName" -Name scanStatus -Value incomplete -Force }
        }

        # Stop logging
        Stop-Transcript
    }
}