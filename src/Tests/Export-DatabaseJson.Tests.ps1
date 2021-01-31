$startTime = $(get-date)

$scriptName = $MyInvocation.MyCommand.Name
Write-Information "$startTime $scriptName started" -InformationAction Continue

Import-Module (Join-Path $PSScriptRoot ..\Sidekick\Sidekick.psd1) -Force

Describe "Export-DatabaseJson.Tests" {
# Test
$server = "(local)"
$database = "master"

It  "Tests it" {
        $result = Export-DatabaseJson $server $database

        $result | Should Not Be ''
        $result | Should Not BeNullOrEmpty
        $result.Length | Should Not Be 0

        #$result | Should be $expected
    }
}

$endTime = $(get-date)
$elapsedTime = $endTime - $startTime
Write-Information "$endTime $scriptName completed: elapsed:$($elapsedTime.ToString("hh\:mm\:ss"))" -InformationAction Continue

PSGallery key:
oy2korhzoanodrvmztza2adawdx2cg6ufnyo7wb5f7lile