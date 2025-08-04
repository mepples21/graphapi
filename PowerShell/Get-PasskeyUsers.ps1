Connect-MgGraph -Scopes Directory.Read.All -TenantId $tenant_id

$tenant_id = Get-Content -Path /Users/miepping/Github/graphapi/.creds/tenant_id

$upn = Get-Content -Path /Users/miepping/Github/graphapi/.creds/upn

$userId = (Get-MgUser -Filter "userPrincipalName eq '$upn'").Id

$pkuser = Get-MgReportAuthenticationMethodUserRegistrationDetail -UserRegistrationDetailsId $userId | select MethodsRegistered

if ($pkUser) {
    if ($pkUser.methodsRegistered -like "*passKeyDeviceBoundAuthenticator*" -or $pkUser.methodsRegistered -like "*passKeyDeviceBound*") {
        $passkey = $true
    } else {
        $passkey = $false
    }
} else {
    $passkey = "User Not Found"
}