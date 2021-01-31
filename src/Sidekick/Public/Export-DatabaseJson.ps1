<#
.SYNOPSIS
    Export Database Data to Json

.DESCRIPTION
    Export Database Data to Json

.PARAMETER server
    The server Id to copy.

.OUTPUTS
    The scripts that would create the database.

.EXAMPLE
    Create Azure DevOps Project and setup security / team groups, etc. with results in a variable

    $result = New-AzureDevOpsProject "Organization" "Project" "Token" "WorkItemId"

	#example:
    #https://blogs.msdn.microsoft.com/premier_developer/2018/04/21/using-vsts-api-with-powershell-to-scaffold-team-projects/
.LINK
    Get-Databases
#>
function Export-DatabaseJson {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$server,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$database,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [string]$destination
    )
    Process {
        $startTime = $(get-date)

        $scriptName = $MyInvocation.MyCommand.Name
        Write-Information "$startTime $scriptName started" -InformationAction Continue
       
        Write-Information "Parameter Values"
        foreach($key in $PSBoundParameters.Keys)
        {
            Write-Information "  $key = $($PSBoundParameters[$key])"
        }

        Write-Information "$(get-date) server:$server" -InformationAction Continue
        Write-Information "$(get-date) database:$database" -InformationAction Continue
        Write-Information "$(get-date) path:(Get-Location).Path" -InformationAction Continue
        #Write-Information "$(get-date) appdata:$env:APPDATA" -InformationAction Continue
    
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
    
        $SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $server

        $db = $SMOserver.databases[$database]
     

        $Objects = $db.Tables
 

        #Build this portion of the directory structure out here in case scripting takes more than one minute.

        $SavePath = $destination;
        if (-not $SavePath)
        {
            $SavePath = "$(Get-Location)\.SideKick\$server\$database"
        }
        #some day add/allow tokens? $env:APPDATA

        Write-Information "$(get-date) SavePath:$SavePath" -InformationAction Continue

        $DateFolder = get-date -format yyyyMMddHHmm

        new-item -type directory -name "$DateFolder"-path "$SavePath"

        $TypeFolder = "data"
                    
        if ((Test-Path -Path "$SavePath\$DateFolder\$TypeFolder") -eq "true")
        {
            "Scripting Out $TypeFolder $ScriptThis"
        }
        else {new-item -type directory -name "$TypeFolder"-path "$SavePath\$DateFolder"}

        $connectionString = "Server=$server;Database=$database;Integrated Security=True;"

        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
 
        $connection.Open()
        $command = $connection.CreateCommand()


        foreach ($ScriptThis in $Objects | where {!($_.IsSystemObject)}) {
            Write-Information "$startTime Exporting $ScriptThis started" -InformationAction Continue

            $ScriptFile = $ScriptThis -replace "\[|\]"
			
            $query = "SELECT * FROM $ScriptThis"
 
            $command.CommandText = $query
 
            $result = $command.ExecuteReader()
 
            $table = new-object "System.Data.DataTable"
 
            $table.Load($result)
 
			#$table | select $table.Columns.ColumnName | ConvertTo-Json | Set-Content "$SavePath\$DateFolder\data\$ScriptFile.json"
			$table | select $table.Columns.ColumnName | ConvertTo-Json -depth 100 | Out-File "$SavePath\$DateFolder\data\$ScriptFile.json" 

        } #This ends the loop

        
        $connection.Close()


        $elapsedTime = $(get-date) - $startTime
        Write-Information "$(get-date) $($scriptName) ended:elapsed $($elapsedTime.ToString("hh\:mm\:ss"))" -InformationAction Continue
    }
}