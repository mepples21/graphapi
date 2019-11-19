
function Get-AzureADGraphAppToken {

    [CmdletBinding()]

    Param (
        #Target domain, e.g. contoso.com
        [Parameter(Mandatory=$false,
                   Position=0)]
        [string]$TenantDomain,

        #Client ID for app used to access graph
        [Parameter(Mandatory=$false,
                   Position=1)]
        [string]$ClientId,

        #Client secret used by app to access graph
        [Parameter(Mandatory=$false,
                   Position=2)]
        [string]$ClientSecret,

        #Switch for Azure AD graph token
        [switch]$AzureADGraph

    )
    

    #Nullify existing header
    $Header = $null
    
    if ($AzureADGraph) {

        #Azure AD Graph URL
        $Resource = "https://graph.windows.net/"

    }
    else {

        #MS Graph URL
        $Resource = "https://graph.microsoft.com"

    }

    
    #Login URL
    $LoginUrl = "https://login.microsoft.com"
    
    #Get a token
    $Body = @{grant_type="client_credentials";resource=$Resource;client_id=$ClientID;client_secret=$ClientSecret}
    $Oauth = Invoke-RestMethod -Method Post -Uri $LoginURL/$TenantDomain/oauth2/token?api-version=1.0 -Body $Body

    return $OAuth


}   #end of function


#Get a token
$OAuth = Get-AzureADGraphAppToken -TenantDomain "" `
                                  -ClientId "" `
                                  -ClientSecret "add_your_client_secret_here_but_dont_leave_it_permanently_saved_here_at_rest"



#Header variable for REST call
$Header = @{'Authorization'="$($OAuth.token_type) $($OAuth.access_token)"}


#MS Graph Query
$Query = "https://graph.microsoft.com/beta/users?`$select=UserPrincipalName,deviceKeys"


#Use do / while to repeat the query to fetch next 100 records
do {
    #Call REST method
    $Result = (Invoke-Restmethod -UseBasicParsing -Headers $Header -Uri $Query -Method Get)

    #$result.value

    #For every user returned check each extension attribute for a value
    $Result.Value | ForEach-Object {

        $User = $_.UserPrincipalName
        $Keys = $_.deviceKeys

        if ($Keys.keytype -like "NGC") {

            
            Write-Output "$User :: $($Keys.keymaterial.count) NGC Keys"
        }

    }   #foreach
    
    $Query = $Result.'@odata.nextLink'
}
while($Query -ne $null)

