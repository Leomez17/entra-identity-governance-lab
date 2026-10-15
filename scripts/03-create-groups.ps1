<#
  Phase 2 and 3: create the lab groups.

  Dynamic groups (role-based access): membership follows the user's department, so a
  mover changes groups automatically. Every rule also requires an ENABLED account,
  so a future joiner gets nothing before day one and a disabled leaver drops out of
  every group straight away.

  Assigned groups (APP-...): stand-ins for FinanceHub application roles. Phase 3 puts
  them inside access packages.

  Run from this folder:  .\03-create-groups.ps1
#>
# Sign in first (see README):  Connect-MgGraph -TenantId <your-tenant>.onmicrosoft.com -Scopes "Group.ReadWrite.All" -UseDeviceCode

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { throw "Not signed in to Microsoft Graph. Run Connect-MgGraph first (see the lab guide)." }
Write-Host "Signed in as $((Get-MgContext).Account) to tenant $((Get-MgContext).TenantId)" -ForegroundColor DarkGray

$dynamic = @(
    @{ Name = 'GRP-All-Staff';         Rule = '(user.employeeId -ne null) and (user.accountEnabled -eq true)' },
    @{ Name = 'GRP-Finance-Users';     Rule = '(user.department -eq "Finance") and (user.accountEnabled -eq true)' },
    @{ Name = 'GRP-Procurement-Users'; Rule = '(user.department -eq "Procurement") and (user.accountEnabled -eq true)' },
    @{ Name = 'GRP-Clinical-Users';    Rule = '(user.department -eq "Clinical") and (user.accountEnabled -eq true)' },
    @{ Name = 'GRP-HR-Users';          Rule = '(user.department -eq "HR") and (user.accountEnabled -eq true)' },
    @{ Name = 'GRP-IT-Staff';          Rule = '(user.department -eq "IT") and (user.accountEnabled -eq true)' }
)
$assigned = @(
    @{ Name = 'APP-FinanceHub-SupplierMaintenance'; Desc = 'FinanceHub: create and amend suppliers' },
    @{ Name = 'APP-FinanceHub-ApprovePayments';     Desc = 'FinanceHub: approve payments' }
)

function Test-Group($name) { [bool](Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue) }

foreach ($g in $dynamic) {
    if (Test-Group $g.Name) { Write-Host "  Skipped $($g.Name) (exists)" -ForegroundColor Yellow; continue }
    New-MgGroup -DisplayName $g.Name -MailEnabled:$false -SecurityEnabled `
        -MailNickname ($g.Name -replace '-', '') `
        -GroupTypes 'DynamicMembership' -MembershipRule $g.Rule -MembershipRuleProcessingState 'On' `
        -Description "Fenwick Valley lab: dynamic, $($g.Rule)" | Out-Null
    Write-Host "  Created dynamic group $($g.Name)" -ForegroundColor Green
}

foreach ($g in $assigned) {
    if (Test-Group $g.Name) { Write-Host "  Skipped $($g.Name) (exists)" -ForegroundColor Yellow; continue }
    New-MgGroup -DisplayName $g.Name -MailEnabled:$false -SecurityEnabled `
        -MailNickname ($g.Name -replace '-', '') -Description "Fenwick Valley lab: $($g.Desc)" | Out-Null
    Write-Host "  Created assigned group $($g.Name)" -ForegroundColor Green
}

Write-Host "Dynamic membership usually fills in within a few minutes. Check with .\06-show-users.ps1 -Groups" -ForegroundColor Cyan
