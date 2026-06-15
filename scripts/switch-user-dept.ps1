param(
    [string]$UserUPN,
    [string]$NewDepartment
)

$DepartmentGroups = @{
    HR          = "a09c9258-b90e-4516-889d-7015d01e0b3e"
    IT          = "ce5cb2cb-df7f-487e-bc0b-3d62fcb4017e"
    Managers    = "2a462717-d430-4717-a0ad-557e46172115"
    Contractors = "032c9d23-e453-43da-8fae-99d762ce8814"
}

$User = Get-MgUser -UserId $UserUPN

Write-Host "Found User:" $User.DisplayName

$CurrentGroups = Get-MgUserMemberOf -UserId $User.Id

Write-Host "Groups Found:"

foreach ($Group in $CurrentGroups)
{
    $GroupDetails = Get-MgGroup -GroupId $Group.Id

    Write-Host $GroupDetails.DisplayName
}

$TargetGroupID = $DepartmentGroups[$NewDepartment]

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
    }
}

Write-Host ""
Write-Host "Current Department Group ID: $CurrentDepartmentGroupId"

if ($CurrentDepartmentGroupId) 
{
    Write-Host ""
    Write-Host "Removing user from current department..."
    
    Remove-MgGroupMemberByRef -GroupId $CurrentDepartmentGroupId -DirectoryObjectId $User.Id
    
    Write-Host "User removed successfully!"
    Write-Host ""
    Write-Host "Adding user to new department..."

    New-MgGroupMember -GroupId $TargetGroupID -DirectoryObjectId -User.Id

    Write-Host "User added Successfully!"
}

Write-Host ""
Write-Host "Adding user to new department..."

New-MgGroupMember -GroupId $TargetGroupID -DirectoryObjectId $User.Id

Write-Host "User added successfully!"