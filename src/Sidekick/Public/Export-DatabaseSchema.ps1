<#
.SYNOPSIS
    Export Database Schema to SideKick Scripts

.DESCRIPTION
    Export Database Schema to SideKick Scripts

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
    Export-DatabaseJson
#>
function Export-DatabaseSchema {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [string]$instance,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
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

        if (-not $instance){
            #$instance = "(local)"
            $instances = Get-Instances
            foreach($instance in $instances)
            {
                Export-DatabaseSchema $instance
            }
        }
        else
        {
            if (-not $database)
            {
                $databases = Get-Databases $instance
                foreach($database in $database)
                {
                    Export-DatabaseSchema $instance $database
                }
            }
            else
            {
                Write-Information "$(get-date) instance:$instance" -InformationAction Continue
                Write-Information "$(get-date) database:$database" -InformationAction Continue
                Write-Information "$(get-date) appdata:$env:APPDATA" -InformationAction Continue
        
                $connectionString = "Server=$instance;Database=$database;Integrated Security=True;"
        
                Write-Information "$(get-date) connectionString:$connectionString" -InformationAction Continue
 
                $connection = New-Object System.Data.SqlClient.SqlConnection
                $connection.ConnectionString = $connectionString 
 
                $connection.Open()
                $command = $connection.CreateCommand()

    
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
    
                $SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $instance

                $db = $SMOserver.databases[$database]
     

                $Objects = $db.Tables
    
                $Objects += $db.Views

                $Objects += $db.StoredProcedures

                $Objects += $db.UserDefinedFunctions

 

                #Build this portion of the directory structure out here in case scripting takes more than one minute.

                $SavePath = $destination;
                if (-not $SavePath)
                {
                    $SavePath = "$(Get-Location)\.SideKick\$instance\$database"
                }
                #some day add/allow tokens? $env:APPDATA

                Write-Information "$(get-date) SavePath:$SavePath" -InformationAction Continue

                $DateFolder = get-date -format yyyyMMddHHmm

                new-item -type directory -name "$DateFolder"-path "$SavePath"

 

                foreach ($ScriptThis in $Objects | where {!($_.IsSystemObject)}) {
                    Write-Information "$startTime Scripting $ScriptThis started" -InformationAction Continue

                    #Need to Add Some mkDirs for the different $Fldr=$ScriptThis.GetType().Name

                    $scriptr = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)

                    $scriptr.Options.AppendToFile = $True

                    $scriptr.Options.AllowSystemObjects = $False

                    $scriptr.Options.ClusteredIndexes = $True

                    $scriptr.Options.DriAll = $True

                    $scriptr.Options.ScriptDrops = $False

                    $scriptr.Options.IncludeHeaders = $True

                    $scriptr.Options.ToFileOnly = $True

                    $scriptr.Options.Indexes = $True

                    $scriptr.Options.Permissions = $True

                    $scriptr.Options.WithDependencies = $False

                    <#Script the Drop too#>

                    $ScriptDrop = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)

                    $ScriptDrop.Options.AppendToFile = $True

                    $ScriptDrop.Options.AllowSystemObjects = $False

                    $ScriptDrop.Options.ClusteredIndexes = $True

                    $ScriptDrop.Options.DriAll = $True

                    $ScriptDrop.Options.ScriptDrops = $True

                    $ScriptDrop.Options.IncludeHeaders = $True

                    $ScriptDrop.Options.ToFileOnly = $True

                    $ScriptDrop.Options.Indexes = $True

                    $ScriptDrop.Options.WithDependencies = $False

 

                    <#This section builds folder structures.  Remove the date folder if you want to overwrite#>

                    # if $ScriptThis == null ... invalid database?
                    $TypeFolder = $ScriptThis.GetType().Name

                    if ((Test-Path -Path "$SavePath\$DateFolder\$TypeFolder") -eq "true")
                    {
                        "Scripting Out $TypeFolder $ScriptThis"
                    }
                    else {new-item -type directory -name "$TypeFolder"-path "$SavePath\$DateFolder"}

                    $ScriptFile = $ScriptThis -replace "\[|\]"

                    $ScriptDrop.Options.FileName = "" + $($SavePath) + "\" + $($DateFolder) + "\" + $($TypeFolder) + "\" + $($ScriptFile) + ".SQL"

                    $scriptr.Options.FileName = "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL"

 

                    #This is where each object actually gets scripted one at a time.

                    $ScriptDrop.Script($ScriptThis)

                    $scriptr.Script($ScriptThis)

                    if ($TypeFolder -eq "Table")
                    {            
                        $query = "SELECT * FROM $ScriptThis"
 
                        $command.CommandText = $query
 
                        $result = $command.ExecuteReader()
 
                        $table = new-object "System.Data.DataTable"
 
                        $table.Load($result)
 
                
                        if ((Test-Path -Path "$SavePath\$DateFolder\data") -eq "true")
                        {
                            "Scripting Out data $ScriptThis"
                        }
                        else {new-item -type directory -name "data"-path "$SavePath\$DateFolder"}


                        #$table | select $table.Columns.ColumnName | ConvertTo-Json | Set-Content "$SavePath\$DateFolder\data\$ScriptFile.json"
                        $table | select $table.Columns.ColumnName | ConvertTo-Json -depth 100 | Out-File "$SavePath\$DateFolder\data\$ScriptFile.json"
                    }

                } #This ends the loop

        
                $connection.Close();
            } # databases
        } # instances

        $elapsedTime = $(get-date) - $startTime
        Write-Information "$(get-date) $($scriptName) ended:elapsed $($elapsedTime.ToString("hh\:mm\:ss"))" -InformationAction Continue
    }
}