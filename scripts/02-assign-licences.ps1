<#
  Phase 1: give every lab user the trial licences (Entra ID P2 and, if you have it,
  Entra ID Governance). Governance features only process users who hold a licence.

  Run from this folder:  .\02-assign-licences.ps1
#>
# Sign in first (see README):  Connect-MgGraph -TenantId <your-tenant>.onmicrosoft.com -Scopes "User.ReadWrite.All", "Organization.Read.All", "Domain.Read.All" -UseDeviceCode

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { throw "Not signed in to Microsoft Graph. Run Connect-MgGraph first (see the lab guide)." }
Write-Host "Signed in as $((Get-MgContext).Account) to tenant $((Get-MgContext).TenantId)" -ForegroundColor DarkGray

$domain = (Get-MgDomain | Where-Object IsDefault).Id
$skus   = Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq 'Enabled' }

Write-Host "Licences in this tenant:" -ForegroundColor Cyan
$skus | Select-Object SkuPartNumber,
    @{ n = 'Available'; e = { $_.PrepaidUnits.Enabled - $_.ConsumedUnits } } | Format-Table -AutoSize

if (-not $skus) {
    Write-Host "No licences found. Finish Phase 0 (P2 trial) first." -ForegroundColor Red
    return
}

$add = @($skus | ForEach-Object { @{ SkuId = $_.SkuId } })
foreach ($u in (Import-Csv "$PSScriptRoot\users.csv")) {
    $upn = "$($u.UserName)@$domain"
    try {
        Set-MgUserLicense -UserId $upn -AddLicenses $add -RemoveLicenses @() -ErrorAction Stop | Out-Null
        Write-Host "  Licensed $upn" -ForegroundColor Green
    } catch {
        Write-Host "  Failed $upn : $($_.Exception.Message)" -ForegroundColor Red
    }
}
