# Import the required module
Import-Module ActiveDirectory

$thresholdDate = (Get-Date).AddDays(-60)
$inactiveUsers = Get-ADUser -Filter {(LastLogonDate -lt $thresholdDate) -or (Enabled -eq $false)} -Properties LastLogonDate, Enabled

# Output report
$inactiveUsers | Format-Table Name, LastLogonDate, Enabled

# Suggest remediation
Write-Host "The above users have been inactive for 60 days or more, or are disabled."
Write-Host "Consider following up with these users or their managers to determine if their accounts can be deleted or further action needs to be taken."

Write-Host "Press any key to continue..."