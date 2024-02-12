Connect-MgGraph -Scopes Policy.ReadWrite.ConditionalAccess,Directory.Read.All -device

$policyList = @()
$policy = @()

$uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"

$policyList = Get-ChildItem -Path '*.json'

try{
    foreach($policy in $policyList){
        $json = Get-Content $policy.fullName
        #$response = Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" -UseBasicParsing -Method POST -ContentType "application/json" -Body $JSON
        Invoke-MgGraphRequest -Method POST -Uri $uri -Body $json -ContentType "application/json"
         
    }
  }
  catch{
    write-host "Error: $($_.Exception.Message)" -ForegroundColor red
  }