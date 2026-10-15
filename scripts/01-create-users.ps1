<#
  Phase 1: create the Fenwick Valley lab users from users.csv.

  - Sets department, job title, employee ID and hire date (Lifecycle Workflows use these).
  - Amira Hassan is a future joiner: her hire date is 3 days from today and her account
    starts DISABLED, so she has no access before her first day.
  - Sets each person's manager in a second pass.
  - Saves the temporary passwords to lab-passwords.csv. Delete that file when the lab is done.

  Run from this folder:  .\01-create-users.ps1
#>
# Sign in first (see README):  Connect-MgGraph -TenantId <your-tenant>.onmicrosoft.com -Scopes "User.ReadWrite.All", "User-LifeCycleInfo.ReadWrite.All", "Domain.Read.All" -UseDeviceCode

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { throw "Not signed in to Microsoft Graph. Run Connect-MgGraph first (see the lab guide)." }
Write-Host "Signed in as $((Get-MgContext).Account) to tenant $((Get-MgContext).TenantId)" -ForegroundColor DarkGray

$domain  = (Get-MgDomain | Where-Object IsDefault).Id
$users   = Import-Csv "$PSScriptRoot\users.csv"
$created = @()
Write-Host "Creating users in $domain" -ForegroundColor Cyan

foreach ($u in $users) {
    $upn = "$($u.UserName)@$domain"
    if (Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue) {
        Write-Host "  Skipped $upn (already exists)" -ForegroundColor Yellow
        continue
    }

    if ($u.HireDate.StartsWith('+')) {
        $hire = (Get-Date).Date.AddDays([int]$u.HireDate.TrimStart('+'))   # future joiner
    } else {
        $hire = [datetime]::ParseExact($u.HireDate, 'yyyy-MM-dd', $null)
    }
    $password = "Fv-" + [guid]::NewGuid().ToString('N').Substring(0, 12) + "!"

    $params = @{
        AccountEnabled    = ($u.Enabled -eq 'yes')
        DisplayName       = "$($u.GivenName) $($u.Surname)"
        GivenName         = $u.GivenName
        Surname           = $u.Surname
        MailNickname      = $u.UserName.Replace('.', '')
        UserPrincipalName = $upn
        Department        = $u.Department
        JobTitle          = $u.JobTitle
        EmployeeId        = $u.EmployeeId
        UsageLocation     = 'GB'
        PasswordProfile   = @{ Password = $password; ForceChangePasswordNextSignIn = $true }
    }
    $new = New-MgUser @params
    # Lifecycle date set through the raw Graph property (needs User-LifeCycleInfo.ReadWrite.All)
    Update-MgUser -UserId $new.Id -BodyParameter @{ employeeHireDate = $hire.ToString("yyyy-MM-dd'T'00:00:00'Z'") }
    $created += [pscustomobject]@{
        User         = $upn
        Department   = $u.Department
        Enabled      = $params.AccountEnabled
        HireDate     = $hire.ToString('yyyy-MM-dd')
        TempPassword = $password
    }
    Write-Host "  Created $upn" -ForegroundColor Green
}

Write-Host "Setting managers" -ForegroundColor Cyan
foreach ($u in ($users | Where-Object { $_.Manager })) {
    $user = Get-MgUser -UserId "$($u.UserName)@$domain"
    $mgr  = Get-MgUser -UserId "$($u.Manager)@$domain"
    Set-MgUserManagerByRef -UserId $user.Id -BodyParameter @{ '@odata.id' = "https://graph.microsoft.com/v1.0/users/$($mgr.Id)" }
    Write-Host "  $($u.UserName) -> $($u.Manager)"
}

if ($created) {
    $created | Format-Table User, Department, Enabled, HireDate -AutoSize
    $created | Export-Csv "$PSScriptRoot\lab-passwords.csv" -NoTypeInformation
    Write-Host "Temporary passwords saved to lab-passwords.csv. Delete it when the lab is finished." -ForegroundColor Cyan
}
