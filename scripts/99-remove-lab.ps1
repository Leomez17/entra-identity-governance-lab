<#
  Clean-up: delete the lab users and groups. Deleted users stay in
  "Deleted users" for 30 days, so this can be undone in that window.

    .\99-remove-lab.ps1
#>
# Sign in first (see README):  Connect-MgGraph -TenantId <your-tenant>.onmicrosoft.com -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Domain.Read.All" -UseDeviceCode

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { throw "Not signed in to Microsoft Graph. Run Connect-MgGraph first (see the lab guide)." }
Write-Host "Signed in as $((Get-MgContext).Account) to tenant $((Get-MgContext).TenantId)" -ForegroundColor DarkGray

$domain = (Get-MgDomain | Where-Object IsDefault).Id
$answer = Read-Host "Delete the 9 lab users and all GRP-/APP- groups in $domain ? Type YES"
if ($answer -ne 'YES') { Write-Host "Cancelled."; return }

foreach ($u in (Import-Csv "$PSScriptRoot\users.csv")) {
    Remove-MgUser -UserId "$($u.UserName)@$domain" -ErrorAction SilentlyContinue
    Write-Host "  Deleted user $($u.UserName)"
}
foreach ($g in (Get-MgGroup -All | Where-Object { $_.DisplayName -like 'GRP-*' -or $_.DisplayName -like 'APP-*' })) {
    Remove-MgGroup -GroupId $g.Id
    Write-Host "  Deleted group $($g.DisplayName)"
}
if (Test-Path "$PSScriptRoot\lab-passwords.csv") { Remove-Item "$PSScriptRoot\lab-passwords.csv"; Write-Host "  Deleted lab-passwords.csv" }
