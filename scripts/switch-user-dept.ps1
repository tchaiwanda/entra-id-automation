# switch-user-dept.ps1
#
# Finds a user by UPN
# Detects current department group membership
# Removes the user from their current department group
# Adds the user to a new department group
# Supports HR, IT, Managers, and Contractors

param(
    [string]$UserUPN,
    [string]$NewDepartment
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

$DepartmentGroups = @{
    HR          = "a09c9258-b90e-4516-889d-7015d01e0b3e"
    IT          = "ce5cb2cb-df7f-487e-bc0b-3d62fcb4017e"
    Managers    = "2a462717-d430-4717-a0ad-557e46172115"
    Contractors = "032c9d23-e453-43da-8fae-99d762ce8814"
}

try
{
    $User = Get-MgUser -UserId $UserUPN -ErrorAction Stop
}
catch
{
    Write-Host "User does not exist."
    return
}
    Write-Host "Found User:" $User.DisplayName
    $CurrentGroups = Get-MgUserMemberOf -UserId $User.Id
    Write-Host "Groups Found:"

$CurrentDepartmentGroupId = $null
$OldDepartment = $null

foreach ($Group in $CurrentGroups)
{
    $GroupDetails = Get-MgGroup -GroupId $Group.Id
    Write-Host $GroupDetails.DisplayName
}

$TargetGroupID = $DepartmentGroups[$NewDepartment]
if (-not $TargetGroupID)
{
    Write-Host "Invalid department chosen."
    return
}

Write-Host ""
Write-Host "Target Department: $NewDepartment"
Write-Host "Target Group ID: $TargetGroupId"
Write-Host ""
Write-Host "Checking for existing department groups..."

foreach ($Group in $CurrentGroups)
{
    if ($DepartmentGroups.Values -contains $Group.Id)
    {
        $GroupDetails = Get-MgGroup -GroupId $Group.Id
        Write-Host "Department Group Found: $($GroupDetails.DisplayName)"
        $CurrentDepartmentGroupId = $Group.Id
        $OldDepartment = $GroupDetails.DisplayName
    }
}

if ($OldDepartment -eq $NewDepartment)
{
    Write-Host ""
    Write-Host "User is already in $NewDepartment."
    return
}

Write-Host ""
Write-Host "Current Department Group ID: $CurrentDepartmentGroupId"

if ($CurrentDepartmentGroupId) 
{
    Write-Host ""
    Write-Host "Removing user from current department..."
    
    Remove-MgGroupMemberByRef -GroupId $CurrentDepartmentGroupId -DirectoryObjectId $User.Id
    Write-Host "User removed successfully!"
}

Write-Host ""
Write-Host "Adding user to new department..."

New-MgGroupMember -GroupId $TargetGroupID -DirectoryObjectId $User.Id

Write-Host "User added successfully!"

if (-not $OldDepartment)
{
    $OldDepartment = "None"
}

Write-AuditLog -Action "Department Change" -TargetUser $User.DisplayName -Details "$OldDepartment -> $NewDepartment"
