# new-hire.ps1
#
# Creates a new Microsoft Entra ID user account
# Generates a temporary password
# Creates the user in Microsoft Graph
# Assigns the user to a department group
# Supports HR, IT, Managers, and Contractors

param(
    [string]$FirstName, 
    [string]$LastName,
    [string]$Department
)

function Write-AuditLog {
    param (
        [string]$Action,
        [string]$TargetUser,
        [string]$Details
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $LogEntry = "$Timestamp | $env:USERNAME | $Action | $TargetUser | $Details"

    Add-Content -Path ".\logs\audit.log" -Value $LogEntry
}

$DisplayName = "$FirstName $LastName"
$MailNickname = "$FirstName.$LastName".ToLower()

$TenantDomain = "m4n5.onmicrosoft.com"

$UPN = "$MailNickname@$TenantDomain"

$RandomPassword = -join (
    (65..90) +
    (97..122) +
    (48..57) |
    Get-Random -Count 12 |
    ForEach-Object {[char]$_}
)

$PasswordProfile = @{
    Password = $RandomPassword
}

Write-Host "Creating user: $DisplayName"

try {

$NewUser = New-MgUser `
-DisplayName $DisplayName `
-GivenName $FirstName `
-Surname $LastName `
-MailNickname $MailNickname `
-UserPrincipalName $UPN `
-AccountEnabled:$true `
-PasswordProfile $PasswordProfile

Write-Host "User Created Successfully."
}

catch {
    Write-Host "User Creation Failed:"
    Write-Host $_
}

Write-AuditLog -Action "User Created" -TargetUser $DisplayName -Details $Department

if ($Department -eq "HR")
{
    $HRGroupId = "a09c9258-b90e-4516-889d-7015d01e0b3e"

    New-MgGroupMember `
        -GroupId $HRGroupId `
        -DirectoryObjectId $NewUser.Id

    Write-Host "Added user to HR group."
}