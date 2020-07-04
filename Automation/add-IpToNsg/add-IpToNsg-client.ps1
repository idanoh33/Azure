<#
.Synopsis
   This script will run the client computer, resolve the public IP and trigger a webhook with the IP parameter
.DESCRIPTION
   Long description
.EXAMPLE
   This script will run the client computer, resolve the public IP and trigger a webhook with the IP parameter
   The webhook will trigger Azure automation runbook which add the client IP to NSG white list
   
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Add-IpToNsg
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
       [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
                   $WebhookUri = "Webhook URI goes here"
    )

    Begin
    {
        
        $ip= (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
 
        $IpAddress= @(
                    @{ IpAddress="$ip"}
                     )
 
        $body = ConvertTo-Json -InputObject $IpAddress
        $header = @{ message = "$env:USERNAME" }
    }
    Process
    {
        $response = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $header
        $jobid = (ConvertFrom-Json ($response.Content)).jobids[0]
    }
    End
    {
        $jobid 
    }
}
