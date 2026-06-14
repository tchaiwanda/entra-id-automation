param(
    [string]$FirstName, 
    [string]$LastName,
    [string]$Department
)
$DisplayName = "$FirstName $LastName"
$MailNickname = "$FirstName.$LastName".ToLower()

$TenantDomain = "m4n5.onmicrosoft.com"

$UPN = "$MailNickname@$TenantDomain"

$PasswordProfile = @{
    Password = "P@ssword123!"
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

if ($Department -eq "HR")
{
    $HRGroupId = "a09c9258-b90e-4516-889d-7015d01e0b3e"

    New-MgGroupMember `
        -GroupId $HRGroupId `
        -DirectoryObjectId $NewUser.Id

    Write-Host "Added user to HR group."
}