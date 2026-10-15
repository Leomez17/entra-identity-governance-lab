<#
  Leaver: set a user's employeeLeaveDateTime, as an HR system would.
  The Offboard workflow (Phase 4) acts on this date. Setting it does NOT disable
  the account by itself: that is the workflow's job.

  Default: James Turner, leaving 5 minutes ago (so the workflow picks him up now).
    .\05-set-leave-date.ps1

  A future date instead (e.g. Priya Shah leaving in 14 days):
    .\05-set-leave-date.ps1 -UserName priya.shah -DaysFromNow 14

  Updating this property in delegated mode needs a Global Administrator sign-in.
#>
param(
    [string]$UserName    = 'james.turner',
    [int]   $DaysFromNow = 0
)
# Sign in first (see README):  Connect-MgGraph -TenantId <your-tenant>.onmicrosoft.com -Scopes "User.ReadWrite.All", "User-LifeCycleInfo.ReadWrite.All", "Domain.Read.All" -UseDeviceCode

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { throw "Not signed in to Microsoft Graph. Run Connect-MgGraph first (see the lab guide)." }
Write-Host "Signed in as $((Get-MgContext).Account) to tenant $((Get-MgContext).TenantId)" -ForegroundColor DarkGray

$domain = (Get-MgDomain | Where-Object IsDefault).Id
$upn    = "$UserName@$domain"
$leave  = (Get-Date).ToUniversalTime().AddDays($DaysFromNow).AddMinutes(-5)

Update-MgUser -UserId $upn -BodyParameter @{ employeeLeaveDateTime = $leave.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'") }
Get-MgUser -UserId $upn -Property DisplayName, EmployeeLeaveDateTime, AccountEnabled |
    Select-Object DisplayName, EmployeeLeaveDateTime, AccountEnabled | Format-List
