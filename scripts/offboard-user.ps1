# offboard-user.ps1
#
# Finds a user by UPN
# Disables the user account
# Removes department group membership
# Prepares account for offboarding

param(
    [string]$UserUPN
)

$User = Get-MgUser -UserId $UserUPN

if (-not $User)
{
    Write-Host "User does not exist."
    return
}
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

Write-Host "Found User: $($User.DisplayName)"
Write-Host ""
Write-Host "Disabling account..."

Update-MgUser -UserId $User.Id -AccountEnabled:$false
Write-Host "Account disabled!"

Write-AuditLog -Action "Account Disabled" -TargetUser $User.DisplayName -Details "Account disabled"

Write-Host "Revoking active sessions..."
$null = Revoke-MgUserSignInSession -UserId $User.Id
Write-Host "Sessions revoked!"

Write-AuditLog -Action "Sessions revoked" -TargetUser $User.DisplayName -Details "All active sessions revoked!"


$DepartmentGroups = @{
    HR          = "a09c9258-b90e-4516-889d-7015d01e0b3e"
    IT          = "ce5cb2cb-df7f-487e-bc0b-3d62fcb4017e"
    Managers    = "2a462717-d430-4717-a0ad-557e46172115"
    Contractors = "032c9d23-e453-43da-8fae-99d762ce8814"
}

$CurrentGroups = Get-MgUserMemberOf -UserId $User.Id
$CurrentDepartmentGroupId = $null

foreach($Group in $CurrentGroups)
{
    if ($DepartmentGroups.Values -contains $Group.Id)
    {
        $CurrentDepartmentGroupId = $Group.Id
    }
}

Write-Host ""

if ($CurrentDepartmentGroupId)
{
    Write-Host "Department Group Found:"
    Write-Host $CurrentDepartmentGroupId

    Write-Host ""
    Write-Host "Removing department group..."

    Remove-MgGroupMemberByRef -GroupId $CurrentDepartmentGroupId -DirectoryObjectId $User.Id
    Write-Host "Department group removed!"

Write-AuditLog -Action "Group Removed" -TargetUser $User.DisplayName -Details "Removed group $CurrentDepartmentGroupId"
}
else
{
    Write-Host "No department group found."
}
Write-AuditLog -Action "Department Change" -TargetUser $User.DisplayName -Details "$OldDepartment -> $NewDepartment"
