$Users = Get-MgUser -All -Property DisplayName,UserPrincipalName,AccountEnabled

foreach ($User in $Users)
{
    if ($User.AccountEnabled -eq $false)
    {
        Write-Host "Disabled User Found:"
        Write-Host $User.DisplayName
        Write-Host ""

            #Is User still consuming licenses?
$Licenses = Get-MgUserLicenseDetail -UserId $User.UserPrincipalName

    if ($Licenses)
{
    Write-Host "Disabled Licensed User Found:"
    Write-Host $User.DisplayName
    Write-Host ""

    foreach ($License in $Licenses)
    {
        Write-Host "- $($License.SkuPartNumber)"
    }

    Write-Host ""
}
    }
}