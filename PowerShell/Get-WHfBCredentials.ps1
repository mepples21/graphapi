$client_secret = Get-Content -Path /Users/miepping/Github/graphapi/.creds/postman_client_secret

$tenantId = "0348ff6f-154e-41c2-b1b7-60743cb165dc"

$body = @{
    grant_type='client_credentials'
    client_id="972317fa-2b02-4632-88cd-61f84ff0ddf8"
    client_secret="$client_secret"
    resource="https://graph.microsoft.com"
   }
   $contentType = 'application/x-www-form-urlencoded' 
   
   $authresult = "No Auth"
   $authresult = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Method 'Post' -Body $body -Headers $header -ContentType $contenttype

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

$userListRequest = @()
$userListRequest = Invoke-RestMethod -Uri 'https://graph.microsoft.com/v1.0/users?$select=userPrincipalName,objectId' -Method 'Get' -Headers $authHeader -ContentType 'application/json'

$userList = @()
$userList += $userListRequest.value

while($null -ne $userListRequest.'@odata.nextLink') {
    $userListRequest = Invoke-RestMethod -Uri $userListRequest.'@odata.nextLink' -Method 'Get' -Headers $authHeader -ContentType 'application/json'
    $userList += $userListRequest.value
}

$userList += $userListRequest.value
$userListArray = $userList.Split("`r`n")

$whfbCredentials = @()

foreach ($user in $userList) {
    $userPrincipalName = @()
    $userPrincipalName = $user.userPrincipalName
    $userWhfbCred = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$userPrincipalName/authentication/windowsHelloForBusinessMethods" -Method 'Get' -Headers $authHeader -ContentType 'application/json'
    $whfbCredentials += $userWhfbCred.value
}