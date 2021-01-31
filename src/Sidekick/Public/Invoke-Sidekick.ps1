function Invoke-Sidekick {
    <#
        .SYNOPSIS
        Runs a Sidekick script.

        .DESCRIPTION
        This function runs Sidekick script

        .PARAMETER task
        The path to the Sidekick build script to execute

        .PARAMETER server
        A comma-separated list of task names to execute
		
        .PARAMETER database
        A comma-separated list of task names to execute
		
        .PARAMETER destination
        A comma-separated list of task names to execute
		
        .EXAMPLE
        Invoke-Sidekick

        Runs the 'default' task in the '.build.ps1' build script

        .EXAMPLE
        Invoke-Sidekick '.\build.ps1' Tests,Package

        Runs the 'Tests' and 'Package' tasks in the '.build.ps1' build script

        .EXAMPLE
        Invoke-Sidekick Tests

        This example will run the 'Tests' tasks in the 'Sidekickfile.ps1' build script. The 'Sidekickfile.ps1' is assumed to be in the current directory.

        .EXAMPLE
        Invoke-Sidekick 'Tests, Package'

        This example will run the 'Tests' and 'Package' tasks in the 'Sidekickfile.ps1' build script. The 'Sidekickfile.ps1' is assumed to be in the current directory.

        .EXAMPLE
        Invoke-Sidekick .\build.ps1 -docs

        Prints a report of all the tasks and their dependencies and descriptions and then exits

        .EXAMPLE
        Invoke-Sidekick .\parameters.ps1 -parameters @{"p1"="v1";"p2"="v2"}

        Runs the build script called 'parameters.ps1' and passes in parameters 'p1' and 'p2' with values 'v1' and 'v2'

        Here's the .\parameters.ps1 build script:

        properties {
            $my_property = $p1 + $p2
        }

        task default -depends TestParams

        task TestParams {
            Assert ($my_property -ne $null) '$my_property should not be null'
        }

        Notice how you can refer to the parameters that were passed into the script from within the "properties" function.
        The value of the $p1 variable should be the string "v1" and the value of the $p2 variable should be "v2".

        .EXAMPLE
        Invoke-Sidekick .\properties.ps1 -properties @{"x"="1";"y"="2"}

        Runs the build script called 'properties.ps1' and passes in parameters 'x' and 'y' with values '1' and '2'

        This feature allows you to override existing properties in your build script.

        Here's the .\properties.ps1 build script:

        properties {
            $x = $null
            $y = $null
            $z = $null
        }

        task default -depends TestProperties

        task TestProperties {
            Assert ($x -ne $null) "x should not be null"
            Assert ($y -ne $null) "y should not be null"
            Assert ($z -eq $null) "z should be null"
        }

        .NOTES
        ---- Exceptions ----

        If there is an exception thrown during the running of a build script Sidekick will set the '$Sidekick.build_success' variable to $false.
        To detect failue outside PowerShell (for example by build server), finish PowerShell process with non-zero exit code when '$Sidekick.build_success' is $false.
        Calling Sidekick from 'cmd.exe' with 'Sidekick.cmd' will give you that behaviour.

        ---- $Sidekick variable ----

        When the Sidekick module is loaded a variable called $Sidekick is created which is a hashtable
        containing some variables:

        $Sidekick.version                      # contains the current version of Sidekick
        $Sidekick.context                      # holds onto the current state of all variables
        $Sidekick.run_by_Sidekick_build_tester    # indicates that build is being run by Sidekick-BuildTester
        $Sidekick.config_default               # contains default configuration
                                            # can be overriden in Sidekick-config.ps1 in directory with Sidekick.psm1 or in directory with current build script
        $Sidekick.build_success                # indicates that the current build was successful
        $Sidekick.build_script_file            # contains a System.IO.FileInfo for the current build script
        $Sidekick.build_script_dir             # contains the fully qualified path to the current build script
        $Sidekick.error_message                # contains the error message which caused the script to fail

        You should see the following when you display the contents of the $Sidekick variable right after importing Sidekick

        PS projects:\Sidekick\> Import-Module .\Sidekick.psm1
        PS projects:\Sidekick\> $Sidekick

        Name                           Value
        ----                           -----
        run_by_Sidekick_build_tester      False
        version                        4.2
        build_success                  False
        build_script_file
        build_script_dir
        config_default                 @{framework=3.5; ...
        context                        {}
        error_message

        After a build is executed the following $Sidekick values are updated: build_script_file, build_script_dir, build_success

        PS projects:\Sidekick\> Invoke-Sidekick .\examples\Sidekickfile.ps1
        Executing task: Clean
        Executed Clean!
        Executing task: Compile
        Executed Compile!
        Executing task: Test
        Executed Test!

        Build Succeeded!

        ----------------------------------------------------------------------
        Build Time Report
        ----------------------------------------------------------------------
        Name    Duration
        ----    --------
        Clean   00:00:00.0798486
        Compile 00:00:00.0869948
        Test    00:00:00.0958225
        Total:  00:00:00.2712414

        PS projects:\Sidekick\> $Sidekick

        Name                           Value
        ----                           -----
        build_script_file              YOUR_PATH\examples\Sidekickfile.ps1
        run_by_Sidekick_build_tester      False
        build_script_dir               YOUR_PATH\examples
        context                        {}
        version                        4.2
        build_success                  True
        config_default                 @{framework=3.5; ...
        error_message

        .LINK
        Assert
        .LINK
        Exec
        .LINK
        FormatTaskName
        .LINK
        Framework
        .LINK
        Get-SidekickScriptTasks
        .LINK
        Include
        .LINK
        Properties
        .LINK
        Task
        .LINK
        TaskSetup
        .LINK
        TaskTearDown
        .LINK
        Properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$task,

        [Parameter(Position = 1, Mandatory = $false)]
        [string]$server,

        [Parameter(Position = 2, Mandatory = $false)]
        [string]$database,

        [Parameter(Position = 3, Mandatory = $false)]
        [string]$destination
    )

    try {
        if (-not $nologo) {
            "Sidekick version {0}`nCopyright (c) 2018 David Walker`n" -f $Sidekick.version
        }
        if (!$buildFile) {
           $buildFile = Get-DefaultBuildFile
        }
        elseif (!(Test-Path $buildFile -PathType Leaf) -and ($null -ne (Get-DefaultBuildFile -UseDefaultIfNoneExist $false))) {
            # If the default file exists and the given "buildfile" isn't found assume that the given
            # $buildFile is actually the target Tasks to execute in the $config.buildFileName script.
            $taskList = $buildFile.Split(', ')
            $buildFile = Get-DefaultBuildFile
        }

        ExecuteInBuildFileScope $buildFile $MyInvocation.MyCommand.Module {
            param($currentContext, $module)

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            if ($docs -or $detailedDocs) {
                WriteDocumentation($detailedDocs)
                return
            }

            try {
                foreach ($key in $parameters.keys) {
                    if (test-path "variable:\$key") {
                        set-item -path "variable:\$key" -value $parameters.$key -WhatIf:$false -Confirm:$false | out-null
                    } else {
                        new-item -path "variable:\$key" -value $parameters.$key -WhatIf:$false -Confirm:$false | out-null
                    }
                }
            } catch {
                WriteColoredOutput "Parameter '$key' is null" -foregroundcolor Red
                throw
            }

            # The initial dot (.) indicates that variables initialized/modified in the propertyBlock are available in the parent scope.
            foreach ($propertyBlock in $currentContext.properties) {
                . $propertyBlock
            }

            foreach ($key in $properties.keys) {
                if (test-path "variable:\$key") {
                    set-item -path "variable:\$key" -value $properties.$key -WhatIf:$false -Confirm:$false | out-null
                }
            }

            # Simple dot sourcing will not work. We have to force the script block into our
            # module's scope in order to initialize variables properly.
            . $module $initialization

            # Execute the list of tasks or the default task
            if ($taskList) {
                foreach ($task in $taskList) {
                    invoke-task $task
                }
            } elseif ($currentContext.tasks.default) {
                invoke-task default
            } else {
                throw $msgs.error_no_default_task
            }

            $successMsg = $msgs.Sidekick_success -f $buildFile
            WriteColoredOutput ("`n${successMsg}`n") -foregroundcolor Green
            $Sidekick.error_message = $null

            $stopwatch.Stop()
            if (-not $notr) {
                WriteTaskTimeSummary $stopwatch.Elapsed
            }
        }

        $Sidekick.build_success = $true

    } catch {
        $currentConfig = GetCurrentConfigurationOrDefault
        if ($currentConfig.verboseError) {
            $error_message = "{0}: An Error Occurred. See Error Details Below: `n" -f (Get-Date)
            $error_message += ("-" * 70) + "`n"
            $error_message += "Error: {0}`n" -f (ResolveError $_ -Short)
            $error_message += ("-" * 70) + "`n"
            $error_message += ResolveError $_
            $error_message += ("-" * 70) + "`n"
            $error_message += "Script Variables" + "`n"
            $error_message += ("-" * 70) + "`n"
            $error_message += get-variable -scope script | format-table | out-string
        } else {
            # ($_ | Out-String) gets error messages with source information included.
            $error_message = "Error: {0}: `n{1}" -f (Get-Date), (ResolveError $_ -Short)
        }

        $Sidekick.build_success = $false
        $Sidekick.error_message = $error_message

        # if we are running in a nested scope (i.e. running a Sidekick script from a Sidekick script) then we need to re-throw the exception
        # so that the parent script will fail otherwise the parent script will report a successful build
        $inNestedScope = ($Sidekick.context.count -gt 1)
        if ( $inNestedScope ) {
            throw $_
        } else {
            if (!$Sidekick.run_by_Sidekick_build_tester) {
                WriteColoredOutput $error_message -foregroundcolor Red
            }
        }
    } finally {
        CleanupEnvironment
    }
}