# Connect to Azure (Connect-MgGraph)
## Variables
$NUDGE_GROUP = "MicrosoftAuthenticator"


# Get all users from the MFA report
$allUsers = Get-MgBetaReportAuthenticationMethodUserRegistrationDetail -All


# Select those who have mobilePhone or 'officePhone' as DefaultMFAMethod
$filteredUsers = $allUsers | Where-Object {$_.DefaultMFAMethod -eq "mobilePhone" -or $_.DefaultMFAMethod -eq "officePhone"} | Select-Object Id, UserPrincipalName, DefaultMFAMethod

# Get the MicrosoftAuthenticator group members
# First we need to get the Group ID of the MicrosoftAuthenticator group
$MFANudgeGroup = Get-MgGroup -Filter "DisplayName eq '$NUDGE_GROUP'"
$nudgeGroupMembers = Get-MgGroupMember -GroupId $MFANudgeGroup.Id


# Compare the members of the $NUDGE_GROUP to the list of users who have mobilePhone as DefaultMFAMethod
# The goal is to add anyone who has mobilePhone as a default method, that is not already
# in the group


# Here we check to see if the user is already in the MicrosoftAuthenticator group
# If they are, we remove them from the list of users to add by filtering them out
# of the $filteredUsers list (which is our Get-MgBetaReportAuthenticationMethodUserRegistrationDetail report)

$filteredUsers = $filteredUsers | Where-Object {$nudgeGroupMembers.Id -notcontains $_.Id}
$filteredUsers | Out-GridView

# Add the filtered users to the MicrosoftAuthenticator group
$filteredUsers | ForEach-Object {
    New-MgGroupMember -GroupId $MFANudgeGroup.Id -DirectoryObjectId $_.Id
    Write-Host "Added $($_.UserPrincipalName) to $NUDGE_GROUP" -ForegroundColor Yellow
}


### REPORTING ###

# Get the MicrosoftAuthenticator group members before add
Write-Host "Retrieved $($nudgeGroupMembers.Count) members from $NUDGE_GROUP" -ForegroundColor Green

Write-Host "Members added to $($Nudge_Group): $($filteredUsers.Count)" -ForegroundColor Green

Write-Host "Breakdown of Internal vs External users added to $($Nudge_Group):" -ForegroundColor Green
# Here we create a table, with two columns, one for external users, one for internal users
# Get the external users added to the group
$externalUsers = $filteredUsers | Where-Object {$_.UserPrincipalName -like "*#EXT#*"}

# Get the internal users added to the group
$internalUsers = $filteredUsers | Where-Object {$_.UserPrincipalName -notlike "*#EXT#*"}

# Create a table with two columns, one for external users, one for internal users
$table = New-Object psobject
Add-Member -InputObject $table -MemberType NoteProperty -Name "External Users" -Value $externalUsers.Count
Add-Member -InputObject $table -MemberType NoteProperty -Name "Internal Users" -Value $internalUsers.Count
$table | Format-Table -AutoSize

