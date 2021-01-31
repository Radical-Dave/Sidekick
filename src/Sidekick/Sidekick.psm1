# Sidekick
# Copyright (c) 2018 David Walker
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

$startTime = $(get-date)

$scriptName = $MyInvocation.MyCommand.Name
Write-Information "$startTime $scriptName started" -InformationAction Continue

Write-Information "$(get-date) $scriptName Parameter Values"
foreach($key in $PSBoundParameters.Keys)
{
        Write-Information "$(get-date) $scriptName $key = $($PSBoundParameters[$key])"
}
		

Write-Information "$(get-date) path:$PSScriptRoot" -InformationAction Continue

# public/private functions
$public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'public/*.ps1') -Recurse -ErrorAction Stop)
#$private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'private/*.ps1') -Recurse -ErrorAction Continue)
foreach ($import in @($public)) { # + $private)) {
    try {
        Write-Information "$(get-date) Importing:$($import.FullName)" -InformationAction Continue
        . $import.FullName
    }
    catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function $public.BaseName -Alias "*"

		
$endTime = $(get-date)
$elapsedTime = $endTime - $startTime
Write-Information "$endTime $scriptName completed: elapsed:$($elapsedTime.ToString("hh\:mm\:ss"))" -InformationAction Continue