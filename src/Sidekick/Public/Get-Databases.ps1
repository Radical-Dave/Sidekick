<#
.SYNOPSIS
    Get Azure DevOps WorkItem

.DESCRIPTION
    Get Azure DevOps WorkItem

.PARAMETER server
    The server Id to Get.

.OUTPUTS
    The WorkItem details.

.EXAMPLE
    Get the WorkItem Id 9746 and store the result in a variable

    $result = Get-AzureDevOpsWokItem "Organization" "Project" "Token" "WorkItemId"

.LINK
    ConvertFrom-Base64
#>
function Get-Databases {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$server
    )
    Process {
        $startTime = $(get-date)

        $scriptName = $MyInvocation.MyCommand.Name
        Write-Information "$startTime $scriptName started" -InformationAction Continue

        Write-Information "$(get-date) $scriptName Parameter Values"
        foreach($key in $PSBoundParameters.Keys)
        {
             Write-Information "$(get-date) $scriptName $key = $($PSBoundParameters[$key])"
        }
		
		#Connect and run a command using SMO 
		[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

		#$sqlServer = new-object ("Microsoft.SqlServer.Management.Smo.Server") "servername\instancename"
		$sqlServer = new-object ("Microsoft.SqlServer.Management.Smo.Server") "$server"

		foreach($sqlDatabase in $sqlServer.databases) {$sqlDatabase.name}
		
		#$sqlServer | get-member | more
		
        $endTime = $(get-date)
        $elapsedTime = $endTime - $startTime
        Write-Information "$endTime $scriptName completed: elapsed:$($elapsedTime.ToString("hh\:mm\:ss"))" -InformationAction Continue
    }
}