Connect-MgGraph -Scopes Policy.Read.All,Directory.Read.All

$caPoliciesRaw = @()
$caPolicies = @()

# Get policy list
try {
$uri = @'
https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?$filter=startsWith(displayName,'<prefix>')
'@

$caPoliciesRaw = Invoke-MgGraphRequest -Method GET -Uri $uri
$caPolicies = $caPoliciesRaw.value
}
catch {
    write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

# Export policies to JSON files in current directory
try {
    foreach ($policy in $caPolicies) {
        $PolicyName = $policy.DisplayName
    
        $PolicyJSON = $policy | ConvertTo-Json -Depth 10
    
        $PolicyJSON | Out-File "$PolicyName.json" -Force
    
        Write-Host "Successfully backed up CA policy: $($PolicyName)" -ForegroundColor Green
    }
}
catch {
    write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}
