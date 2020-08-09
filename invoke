PARAM(
  [String]$sasToken
)
# Connect Azure Automation
$connectionName = "AzureRunAsConnection"
    
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

$connectionResult = Connect-AzAccount `
    -ServicePrincipal `
    -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

# Resolve VMs
$RunningVMs = Get-azVM -Status | where-object { $_.powerstate -eq 'VM running' }    

# look for VM's without cybereason tag
$VMsToInstall = $RunningVMs | Where-Object { $_.tags.cybereasonInstalled -eq $null }

$blobUrl = 'https://cyberdemostg.blob.core.windows.net/configscripts/'

foreach ($VM in $VMsToInstall){
    # determine OS type
    $result= $null

    if($VM.OSProfile.WindowsConfiguration){
        $ostype= 'windows'
        $script = 'config.ps1'
        $url= "{0}{1}/{2}{3}" -f $blobUrl, $ostype, $script, $sastoken
        Invoke-WebRequest -Uri $url -OutFile ".\$script"
        $result= Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -CommandId 'RunPowerShellScript' -ScriptPath ".\$script"
    }
    elseif ($VM.OSProfile.LinuxConfiguration){
        $ostype= 'linux'
        $script = 'config.sh'
        $url = "{0}{1}/{2}{3}" -f $blobUrl, $ostype, $script, $sastoken
        Invoke-WebRequest -Uri $url -OutFile ".\$script"
        $result= Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -CommandId 'RunShellScript' -ScriptPath ".\$script"
    }
    
    # Tag Virtual machines
    if ($result)
    {
        # Set tag cybereason is installed true
        if ($vm.tags){
            $tags= (Get-AzResource -Resourceid $vm.id).tags
            $tags += @{CybereasonInstalled = $true }
            $tags += @{CybereasonOsSupported = $true }
            set-AzResource -Resourceid $vm.id -Tag $tags -Force
        }
        elseif(!$vm.tags){
            $tags=@()
            $tags += @{CybereasonInstalled = $true }
            $tags += @{CybereasonOsSupported = $true }
            set-AzResource -Resourceid $vm.id -Tag $tags -Force
        }
        # Set tag installationResult success
    }
    else
    {
        # Set tag cybereason is installed false
        if ($vm.tags) {
            $tags = (Get-AzResource -Resourceid $vm.id).tags
            $tags += @{CybereasonInstalled = $false }
            $tags += @{CybereasonOsSupported = $false }
            set-AzResource -Resourceid -Tag $tags -Force
        }
        elseif (!$vm.tags) {
            $tags = @()
            $tags += @{CybereasonInstalled = $false }
            $tags += @{CybereasonOsSupported = $false }
            set-AzResource -Resourceid -Tag $tags -Force
        }
        # Set tag installationResult failed
    }

} 
