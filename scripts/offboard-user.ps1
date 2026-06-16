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

Write-Host "Found User: $($User.DisplayName)"
Write-Host ""
Write-Host "Disabling account..."

Update-MgUser -UserId $User.Id -AccountEnabled:$false

Write-Host "Account disabled!"

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
Write-Host "Department Group Found:"
Write-Host $CurrentDepartmentGroupId

if ($CurrentDepartmentGroupId) 
{
    Write-Host ""
    Write-Host "Removing department group..."
    
    Remove-MgGroupMemberByRef -GroupId $CurrentDepartmentGroupId -DirectoryObjectId $User.Id
    
    Write-Host "Department group removed!" <# Action to perform if the condition is true #>
}

