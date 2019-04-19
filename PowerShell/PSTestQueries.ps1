$tenantURL = "michaelepping.onmicrosoft.com"

$body = @{
    grant_type='client_credentials'
    client_id=""
    client_secret=""
    resource="https://graph.microsoft.com"
   }
   $contentType = 'application/x-www-form-urlencoded' 
   
   $authresult = "No Auth"
   $authresult = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantURL/oauth2/token" -Method 'Post' -Body $body -Headers $header -ContentType $contenttype

   do {
    Start-Sleep 3
} until ($authresult -ne "No Auth")

if($authResult.access_token){

    # Creating header for Authorization token
    $authHeader = @{
        'Authorization'="Bearer " + $authResult.access_token
        'Content-Type'='application/json'
        'ExpiresOn'=$authResult.expires_on
    }
}

else {
    Write-Host
    Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
    Write-Host
    break
}


$allUnifiedGroupsQueryURI = -join('https://graph.microsoft.com/beta/groups?','$filter',"=groupTypes/any(c:c+eq+'Unified')")  # This gets all the Unified Groups in the tenant
$allUnifiedGroups = Invoke-RestMethod -Uri $allUnifiedGroupsQueryURI -Headers $authHeader -Method Get

$groupsWithTeamsURI = -join('https://graph.microsoft.com/beta/groups?','$filter',"=resourceProvisioningOptions/Any(x:x eq 'Team')") # This gets all the Unified Groups WITH Teams attached
$groupsWithTeams = Invoke-RestMethod -Uri $groupsWithTeamsURI -Headers $authHeader -Method Get

$groupsWithoutTeams = # Need to add logic here to subtract the list of Groups WITH teams from the list of all Groups

#$unifiedgroups = Get-UnifiedGroup -ResultSize Unlimited    # A method for getting all the unified groups from Exchange Online PowerShell
# Exhange Group Attribute representing Azure AD group ID: ExternalDirectoryObjectId

foreach ($group in $groupsWithTeams.Value) {

    $groupID = $group.id
    $graphgroupdata = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/groups/$groupID" -Headers $authHeader -Method Get

    # Collect Group Owners
    $groupOwners = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/groups/$groupID/owners" -Headers $authHeader -Method Get

    # Collect Group Members
    $groupMembers = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/groups/$groupID/members" -Headers $authHeader -Method Get

    # Collect Planner Info
    $groupPlanner = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/groups/$groupID/planner" -Headers $authHeader -Method Get

    # Collect Teams Info
    $groupTeams = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/groups/$groupID/teams" -Headers $authHeader -Method Get
    
    $groupData = New-Object PSObject -Property @{
        Id = $groupID
        GraphData = $graphgroupdata
        Owners = $groupOwners
        Members = $groupMembers
        Planner = $groupPlanner
        Teams = $groupTeams
    }

    $groupData | Export-Csv .\export_test_data.csv -Append -NoTypeInformation

}