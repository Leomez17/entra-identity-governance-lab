<#
  Mover: change a user's department and job title, as an HR system would.

  Phase 2 example (Daniel Kim, Clinical -> HR):
    .\04-move-user.ps1 -UserName daniel.kim -Department HR -JobTitle "HR Advisor"

  Phase 4 example (Laura Chen, Procurement -> Finance), the default:
    .\04-move-user.ps1
#>
param(
    [string]$UserName   = 'laura.chen',
    [string]$Department = 'Finance',
    [string]$JobTitle   = 'Accounts Payable Supervisor'
)
# Sign in first (see README):  Connect-MgGraph -TenantId <your-tenant>.onmicrosoft.com -Scopes "User.ReadWrite.All", "Domain.Read.All" -UseDeviceCode

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { throw "Not signed in to Microsoft Graph. Run Connect-MgGraph first (see the lab guide)." }
Write-Host "Signed in as $((Get-MgContext).Account) to tenant $((Get-MgContext).TenantId)" -ForegroundColor DarkGray

$domain = (Get-MgDomain | Where-Object IsDefault).Id
$upn    = "$UserName@$domain"

$before = Get-MgUser -UserId $upn -Property DisplayName, Department, JobTitle
Update-MgUser -UserId $upn -Department $Department -JobTitle $JobTitle
$after  = Get-MgUser -UserId $upn -Property DisplayName, Department, JobTitle

Write-Host "$($before.DisplayName): $($before.Department) / $($before.JobTitle)  ->  $($after.Department) / $($after.JobTitle)" -ForegroundColor Green
