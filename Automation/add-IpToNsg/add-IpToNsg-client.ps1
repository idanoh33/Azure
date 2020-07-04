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
        $response = Invoke-WebRequest -Method Post -Uri $WebhookUri -Body $body -Headers $header
        $jobid = (ConvertFrom-Json ($response.Content)).jobids[0]
    }
    End
    {
        $jobid 
    }
}
