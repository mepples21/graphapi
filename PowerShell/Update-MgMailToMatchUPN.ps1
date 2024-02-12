Connect-MgGraph -Scopes User.ReadWrite.All

$users = Get-MgUser -All

foreach ($user in $users) {
    Update-MgUser -UserId $user.Id -Mail $user.UserPrincipalName
}