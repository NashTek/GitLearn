## Variables ##
$numUsersToAdd = 5
$NUDGE_GROUP = "MicrosoftAuthenticator"

# Check to see if connected
try{
    Get-MgUser -Top 1
    Write-Host "Connected to MgGraph"` -ForegroundColor Green
}catch{
    Write-Host "Not connected to MgGraph, connecting now..." -ForegroundColor Green
    Connect-MgGraph
    Write-Host $_.Exception.Message
}

$allUsers = Get-MgBetaReportAuthenticationMethodUserRegistrationDetail -All
Write-Host "Retrieved $($allUsers.Count) users from the report" -ForegroundColor Green

# Select those who have mobilePhone as DefaultMFAMethod
$filteredUsers = $allUsers | Where-Object {$_.DefaultMFAMethod -eq "MobilePhone"} | Select-Object Id, UserPrincipalName, DefaultMFAMethod
Write-Host "Retrieved $($filteredUsers.Count) users who have mobilePhone as DefaultMFAMethod" -ForegroundColor Green

$MFANudgeGroup = Get-MgGroup -Filter "DisplayName eq '$NUDGE_GROUP'"
Write-Host "Retrieved $NUDGE_GROUP group Id" -ForegroundColor Green


# Remove the users who are already in the $NUDGE_GROUP


 $nudgeGroupMembers = Get-MgGroupMember -GroupId $MFANudgeGroup.Id
 Write-Host "Retrieved $($nudgeGroupMembers.Count) members from $NUDGE_GROUP" -ForegroundColor Green

 # Compare the members of the $NUDGE_GROUP to the list of users who have mobilePhone as DefaultMFAMethod
 # - Remove the users who are already in the $NUDGE_GROUP from the list of users who have mobilePhone as DefaultMFAMethod

$filteredUsers = $filteredUsers | Where-Object {$_.DefaultMFAMethod -eq "MobilePhone" -and $nudgeGroupMembers.Id -notcontains $_.Id}
Write-Host "Retrieved $($filteredUsers.Count) users who have mobilePhone as DefaultMFAMethod and are not in $NUDGE_GROUP" -ForegroundColor Green


# Add in $numUsersToAdd to $NUDGE_GROUP
for ($counter = 0; $counter -lt $numUsersToAdd; $counter++) {
    $user = $filteredUsers[$counter]
    New-MgGroupMember -GroupId $MFANudgeGroup.Id -DirectoryObjectId $user.Id -WhatIf
    Write-Host "Added $($user.UserPrincipalName) to $NUDGE_GROUP" -ForegroundColor Green
}


# Remove users from $NUDGE_GROUP who no longer have mobilePhone as DefaultMFAMethod
# We can do this by checking the $allUsers list that do not have DefaultMFAMethod
# of "MobilePhone" and comparing it to the $nudgeGroupMembers list

Write-Host "Cleaning up $NUDGE_GROUP" -ForegroundColor Green

$usersToRemove = $allUsers | Where-Object {$_.DefaultMFAMethod -ne "MobilePhone" -and $nudgeGroupMembers.Id -contains $_.Id}
Write-Host "Retrieved $($usersToRemove.Count) users who no longer have mobilePhone as DefaultMFAMethod and are in $NUDGE_GROUP" -ForegroundColor Green
$usersToRemove | ForEach-Object {
    Remove-MgGroupMemberByRef -GroupId $MFANudgeGroup.Id -DirectoryObjectId $_.Id -WhatIf
    Write-Host "Removed $($_.UserPrincipalName) from $NUDGE_GROUP" -ForegroundColor Green
}

Write-Host "Script complete..." -ForegroundColor Green

