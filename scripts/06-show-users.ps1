<#
  Check script: shows every lab user's lifecycle attributes, and with -Groups the
  membership of each lab group. Use it for the Check step at the end of each phase.

    .\06-show-users.ps1
    .\06-show-users.ps1 -Groups
#>
param([switch]$Groups)
# Sign in first (see README):  Connect-MgGraph -TenantId <your-tenant>.onmicrosoft.com -Scopes "User.Read.All", "Group.Read.All", "Domain.Read.All" -UseDeviceCode

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { throw "Not signed in to Microsoft Graph. Run Connect-MgGraph first (see the lab guide)." }
Write-Host "Signed in as $((Get-MgContext).Account) to tenant $((Get-MgContext).TenantId)" -ForegroundColor DarkGray

$domain = (Get-MgDomain | Where-Object IsDefault).Id
$props  = 'DisplayName', 'Department', 'JobTitle', 'EmployeeId', 'EmployeeHireDate', 'EmployeeLeaveDateTime', 'AccountEnabled'

$rows = foreach ($u in (Import-Csv "$PSScriptRoot\users.csv")) {
    $x = Get-MgUser -UserId "$($u.UserName)@$domain" -Property $props -ErrorAction SilentlyContinue
    if ($x) {
        [pscustomobject]@{
            Name       = $x.DisplayName
            Department = $x.Department
            JobTitle   = $x.JobTitle
            EmpId      = $x.EmployeeId
            Hire       = if ($x.EmployeeHireDate) { '{0:yyyy-MM-dd}' -f $x.EmployeeHireDate } else { '' }
            Leave      = if ($x.EmployeeLeaveDateTime) { '{0:yyyy-MM-dd HH:mm}' -f $x.EmployeeLeaveDateTime } else { '' }
            Enabled    = $x.AccountEnabled
        }
    }
}
$rows | Format-Table -AutoSize

if ($Groups) {
    foreach ($g in (Get-MgGroup -All | Where-Object { $_.DisplayName -like 'GRP-*' -or $_.DisplayName -like 'APP-*' } | Sort-Object DisplayName)) {
        $members = Get-MgGroupMember -GroupId $g.Id -All | ForEach-Object { $_.AdditionalProperties['displayName'] }
        $list = if ($members) { ($members | Sort-Object) -join ', ' } else { '(none yet)' }
        Write-Host ("{0,-36} {1}" -f $g.DisplayName, $list)
    }
}
