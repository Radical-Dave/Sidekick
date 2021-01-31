Describe 'Testing against PSSA rules' {
    Context 'PSSA Standard Rules' {
        $folder = Get-ChildItem ..\Public -Recurse -Directory
        $analysis = Invoke-ScriptAnalyzer -Path ("$folder\*.ps1")
        $scriptAnalyzerRules = Get-ScriptAnalyzerRule

        forEach ($rule in $scriptAnalyzerRules) {
            It "Should pass $rule" {
                If ($analysis.RuleName -contains $rule) {
                    $analysis |
                        Where-Object RuleName -EQ $rule -outvariable failures |
                        Out-Default
                    $failures.Count | Should Be 0
                }
            }
        }
    }
} -Tags PSSA