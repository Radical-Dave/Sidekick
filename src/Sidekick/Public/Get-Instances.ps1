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
function Get-Instances {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false,ValueFromPipelineByPropertyName)]
        [string[]]$servers
    )
    Process {
        $startTime = $(get-date)

        $scriptName = $MyInvocation.MyCommand.Name
        Write-Information "$startTime $scriptName started" -InformationAction Continue

        Write-Information "$(get-date) $scriptName Parameter Values"
        foreach($key in $PSBoundParameters.Keys)
        {
             Write-Information "$(get-date) $scriptName $key = $($PSBoundParameters[$key])" -InformationAction Continue
        }

        if (-not $servers)
        {
            #$servers = Hostname #populated correctly, but Invoke-Command wouldnt connect
            #$servers = "localhost"
		    #Write-Information "$(get-date) servers:$servers" -InformationAction Continue

		    #Invoke-Command -ComputerName $servers {
			    $list = Get-Service -Name MSSQL* |
			    Where-Object Status -eq 'Running' | Select-Object @{label='InstanceName';expression={$_.Name -replace '^.*\$'}}# | foreach {$_.Name}            
		    #} | Select-Object -Property PSComputerName, @{label='InstanceName';expression={$_.Name -replace '^.*\$'}}

            $local = $list | where {$_.InstanceName -eq "MSSQLSERVER"}
            $local.InstanceName = "."

            $list
        }
        else
        {
		    Invoke-Command -ComputerName $servers {
			    Get-Service -Name MSSQL* |
			    Where-Object Status -eq 'Running'
		    } | Select-Object -Property PSComputerName, @{label='InstanceName';expression={$_.Name -replace '^.*\$'}}
		}
        $endTime = $(get-date)
        $elapsedTime = $endTime - $startTime
        Write-Information "$endTime $scriptName completed: elapsed:$($elapsedTime.ToString("hh\:mm\:ss"))" -InformationAction Continue
    }
}