$startTime = $(get-date)

$scriptName = $MyInvocation.MyCommand.Name
Write-Information "$startTime $scriptName started" -InformationAction Continue
Write-Information "$(get-date) path:$PSScriptRoot" -InformationAction Continue

Import-Module (Join-Path $PSScriptRoot ..\Sidekick\Sidekick.psd1) -Force

Describe "Get-Databases.tests" {

    It "Tests Get-Databases" {
        $server = "(local)"

        $databases = Get-Databases $server

        $databases | Should Not Be ''
        $databases | Should Not BeNullOrEmpty
        $databases.Length | Should Not Be 0
    }
} -Tags UnitTest

$endTime = $(get-date)
$elapsedTime = $endTime - $startTime
Write-Information "$endTime $scriptName completed: elapsed:$($elapsedTime.ToString("hh\:mm\:ss"))" -InformationAction Continue