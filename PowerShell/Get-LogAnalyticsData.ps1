#Your Workspace info
$logAnalyticsWorkspace = "958b0fcf-bbb8-42fd-870c-e847e6d774a1"
$logAnalyticsRegion = "westus2"
# $logQuery = "AuditLogs | where SourceSystem == `"Azure AD`" | project Identity, TimeGenerated, ResultDescription | limit 50"
$logQuery = "let details = dynamic({    'Name':'', 'Type':'*'});    let data = SigninLogs    |where AppDisplayName in ('*') or '*' in ('*')    |where UserDisplayName in ('*') or '*' in ('*')    |extend errorCode = toint(Status.errorCode)    |extend SigninStatus = case(errorCode == 0, 'Success',                         errorCode == 50058, 'Interrupt',                         errorCode == 50140, 'Interrupt',                         errorCode == 51006, 'Interrupt',                         errorCode == 50059, 'Interrupt',                         errorCode == 65001, 'Interrupt',                         errorCode == 52004, 'Interrupt',                         errorCode == 50055, 'Interrupt',                         errorCode == 50144, 'Interrupt',                         errorCode == 50072, 'Interrupt',                         errorCode == 50074, 'Interrupt',                         errorCode == 16000, 'Interrupt',                         errorCode == 16001, 'Interrupt',                         errorCode == 16003, 'Interrupt',                         errorCode == 50127, 'Interrupt',                         errorCode == 50125, 'Interrupt',                         errorCode == 50129, 'Interrupt',                         errorCode == 50143, 'Interrupt',                         errorCode == 81010, 'Interrupt',                         errorCode == 81014, 'Interrupt',                         errorCode == 81012 ,'Interrupt',                         'Failure')    |where SigninStatus == '*' or '*' == '*' or '*' == 'All Sign-ins'    |extend Reason = tostring(Status.failureReason)    |extend ClientAppUsed = iff(isempty(ClientAppUsed)==true,'Unknown' ,ClientAppUsed)    |extend isLegacyAuth = case(ClientAppUsed contains 'Browser', 'No', ClientAppUsed contains 'Mobile Apps and Desktop clients', 'No', ClientAppUsed contains 'Exchange ActiveSync', 'No', ClientAppUsed contains 'Other clients', 'Yes', 'Unknown')    |where isLegacyAuth=='Yes'    | where AppDisplayName in ('*') or '*' in ('*')    | where details.Type == '*' or (details.Type == 'App' and AppDisplayName == details.Name) or (details.Type == 'Protocol' and AppDisplayName == details.ParentId and ClientAppUsed == details.Name);    data    | top 200 by TimeGenerated desc    | extend TimeFromNow = now() - TimeGenerated    | extend TimeAgo = strcat(case(TimeFromNow < 2m, strcat(toint(TimeFromNow / 1m), ' seconds'), TimeFromNow < 2h, strcat(toint(TimeFromNow / 1m), ' minutes'), TimeFromNow < 2d, strcat(toint(TimeFromNow / 1h), ' hours'), strcat(toint(TimeFromNow / 1d), ' days')), ' ago')    | project User = UserDisplayName, ['Sign-in Status'] = strcat(iff(SigninStatus == 'Success', '✔️', '❌'), ' ', SigninStatus), ['Sign-in Time'] = TimeAgo, App = AppDisplayName, ['Error code'] = errorCode, ['Result type'] = ResultType, ['Result signature'] = ResultSignature, ['Result description'] = ResultDescription, ['Conditional access policies'] = ConditionalAccessPolicies, ['Conditional access status'] = ConditionalAccessStatus, ['Operating system'] = DeviceDetail.operatingSystem, Browser = DeviceDetail.browser, ['Country or region'] = LocationDetails.countryOrRegion, ['State'] = LocationDetails.state, ['City'] = LocationDetails.city, ['Time generated'] = TimeGenerated, Status, ['User principal name'] = UserPrincipalName"
#Your Client ID and Client Secret obtained when registering your WebApp
$clientid = "b683e0e1-0eff-403a-97cc-fff27de236f5"
$clientSecret = ""
$tenantURL = "michaelepping.onmicrosoft.com"


$resource = "https://$logAnalyticsRegion.api.loganalytics.io"
$scope = "Data.Read"

$body = @{
    grant_type='client_credentials'
    client_id=$clientid
    client_secret=$clientSecret
    resource=$resource
    scope=$scope
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

$querybody = @{"query" = $logQuery} | ConvertTo-Json

$result = Invoke-RestMethod -Uri "https://$logAnalyticsRegion.api.loganalytics.io/v1/workspaces/$logAnalyticsWorkspace/query" -Headers $authHeader -Method Post -ContentType 'application/json' -Body $querybody

# Output Columns for CSV
$headerRow = $null
$headerRow = $result.tables.columns | Select-Object name
$columnsCount = $headerRow.Count
# Format the Report
$logData = @()
foreach ($row in $result.tables.rows) {
    $data = new-object PSObject
    for ($i = 0; $i -lt $columnsCount; $i++) {
        $data | add-member -membertype NoteProperty -name $headerRow[$i].name -value $row[$i]
    }
    $logData += $data
    $data = $null
}
# Export to CSV
$logData | Export-Csv .\logAnalyticsData.csv -NoTypeInformation