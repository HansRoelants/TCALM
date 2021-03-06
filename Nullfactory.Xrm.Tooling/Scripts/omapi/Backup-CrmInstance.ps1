<#
	.SYNOPSIS
		Backup a Dynamics 365 Customer Engagement instance.
	.DESCRIPTION
    	This scripts automatically connect to a remote Dynamics CRM instance using the provided credentials and deploys the specified solution. Works with both on-premises and online solutions.

	.NOTES
		Author: Shane Carvalho
		Version: generator-nullfactory-xrm@1.6.0
	.LINK
		https://nullfactory.net
	.PARAMETER serverUrl
		Mandatory parameter that specifies the server url of the Dynamics CRM instance being deployed to.
	.PARAMETER username
		Mandatory parameter is the username used to connect to Dynamics CRM.
	.PARAMETER password
		Mandatory parameter is the password of the user used to connect to Dynamics CRM.
	.PARAMETER instanceId
		Optional parameter. The name of the instance being backed up.
	.PARAMETER friendlyName
		Optional parameter that identifies the instance using the friendlyname.
	.PARAMETER uniqueName
		Optional parameter that identifies the instance using the organisation unique name.
	.PARAMETER backupLabel
		Mandatory parameter specifies the backup label to be associated.
	.PARAMETER backupNotes
		This optional switch tells the script that it should publish changes once deployed. Defaults to false.
	.EXAMPLE
		.\Backup-CrmInstance.ps1 -apiUrl "https://admin.services.crm6.dynamics.com" -username "admin@superinstance.onmicrosoft.com" -password "Pass@word1!" -friendlyName "indie" -backupLabel "prod-backup1" -backupNotes "Production Backup 1"
		Backup instance with friendly name "indie". Provide it a label called "prod-backup1" with notes "Production Backup 1"
	.EXAMPLE
		.\Backup-CrmInstance.ps1 -apiUrl "https://admin.services.crm6.dynamics.com" -username "admin@superinstance.onmicrosoft.com" -password "Pass@word1!" -uniqueName "indie" -backupLabel "prod-backup1" -backupNotes "Production Backup 1"
#>
[CmdletBinding(DefaultParameterSetName = "Internal")]
param(
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet('https://admin.services.crm.dynamics.com',
        'https://admin.services.crm9.dynamics.com',
        'https://admin.services.crm4.dynamics.com',
        'https://admin.services.crm5.dynamics.com',
        'https://admin.services.crm6.dynamics.com',
        'https://admin.services.crm7.dynamics.com',
        'https://admin.services.crm2.dynamics.com',
        'https://admin.services.crm8.dynamics.com',
        'https://admin.services.crm3.dynamics.com',
        'https://admin.services.crm11.dynamics.com')]
    [string]$apiUrl,
    [Parameter(Mandatory = $true, Position = 2)]
    [string]$username,
    [Parameter(Mandatory = $true, Position = 3)]
    [string]$password,
    [guid]$instanceId,
    [string]$friendlyName,
		[string]$uniqueName,
    [string]$backupLabel,
    [string]$backupNotes
)
$ErrorActionPreference = "Stop"

# Importing common functions
. .\CrmInstance.Common.ps1
$creds = Init-OmapiModule $username $password

# if a backup label is not provided, generate one
if (-Not $backupLabel) {
    $backupLabel = Get-Date -Format "G"
    Write-Verbose -Message "Backup label not provided, defaulting to $backupLabel"
}

# if an instance id is not provided then attempt to use the aliases
if(-Not $instanceId)
{
    $instanceId = Get-CrmInstanceByName $apiUrl $creds $friendlyName $uniqueName
}

Write-Verbose "Resolved InstanceId: $instanceId"

$backupInfoRequest = New-CrmBackupInfo -InstanceId $instanceId -Label $backupLabel -IsAzureBackup 0 -Notes $backupNotes
$backupJob = Backup-CrmInstance -ApiUrl $apiUrl -Credential $creds -BackupInfo $backupInfoRequest

Wait-CrmOperation -apiUrl $apiUrl -credentials $creds -sourceOperation $backupJob

Write-Host "Backup creation timed out."
exit 1
