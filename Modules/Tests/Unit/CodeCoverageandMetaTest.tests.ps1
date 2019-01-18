[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$rootPath = Split-Path -Parent (Split-path -parent $PSScriptRoot)

$CodeCoverage = (Join-Path $rootPath 'CodeCoverageandMetaTest.psm1')

Import-module $CodeCoverage -Force

InModuleScope CodeCoverageandMetaTest {

    <#
    .SYNOPSIS
        Pester tests for Get-CodeCoverageResults
    #>

    $Goodpath = @{
        Modulepath = "$Env:Temp"
    }

    $badPath = (Get-Random).ToString()

    $scriptnamereturn = @{
        Name = 'meta.Tests.ps1'
    }

    $pesternopsm1 = @{
        totalCount   = 2
        passedCount  = 2
        failedCount  = 2
        skippedCount = 2
    }

    $pesterwpsm1 = @{
        totalCount   = 2
        passedCount  = 2
        failedCount  = 2
        skippedCount = 2
        codeCoverage = @{
            numberOfCommandsAnalyzed = 2
            numberOfCommandsExecuted = 2
            numberOfCommandsMissed   = 1
            HitCommands              = @{
                Function = 'get-targetresource'
            }
            MissedCommands           = @{
                Function = 'get-targetresource'
            }
        }
    }

    $NoCodeCoverage = 'Code Coverage not analyzed'

    $scriptpsm = @{
        Name = "meta.psm1"
    }

    Describe 'Get-CodeCoverageResults' {

        Context "Parameter Values validation" {

            It "Should error when folder doesn't exist" {
                Mock Test-Path { $false }
                {Get-CodeCoverageResult -Modulepath $badPath} |should throw
            }
        }

        Context "No tests.ps1 files found should throw" {


            It "Should error when folder does not contain any tests.ps1 files" {
                Mock Get-ChildItem { return $Null } -ParameterFilter { $filter -eq '*.tests.ps1'}
                {Get-CodeCoverageResult @Goodpath} |should throw

            }
        }

        Context 'Can not find assoicated modulemodule' {

            It 'Should return good data and no PSM1 file' {
                Mock Get-ChildItem {return $scriptnamereturn} -ParameterFilter {$filter -eq '*.tests.ps1'}
                Mock Get-ChildItem {$null} -ParameterFilter {$filter -eq $psm}
                Mock Invoke-Pester {return $pesternopsm1}

                $result = Get-CodeCoverageResult @Goodpath
                $result.FailedCount |should -be 2
                $result.TotalCount |should -be 2
                $result.Module |Should -Be 'Unable to find the associated psm1'
                $result.'Test Script' |should -be $scriptnamereturn.name
                $result.CommandsAnalyzed |Should -Be $NoCodeCoverage
                $result.CommandsExecuted |Should -Be $NoCodeCoverage
                $result.'Hit Commands' | Should -Be $NoCodeCoverage
                $result.CommandsMissed |Should -Be $NoCodeCoverage
                $result.'Missed Commands' |Should -Be $NoCodeCoverage
            }
        }

        Context 'Found assoicated module' {

            It 'Should return good data and no PSM1 file' {
                Mock Get-ChildItem {return $scriptnamereturn} -ParameterFilter {$filter -eq '*.tests.ps1'}
                Mock Get-ChildItem {return $scriptpsm} -ParameterFilter {$filter -eq $psm}
                Mock Invoke-Pester {return $pesterwpsm1}

                $result = Get-CodeCoverageResult @Goodpath
                $result.FailedCount |should -be 2
                $result.TotalCount |should -be 2
                $result.Module |Should -Be $scriptpsm.name
                $result.'Test Script' |should -be $scriptnamereturn.name
                $result.CommandsAnalyzed |Should -Be 2
                $result.CommandsExecuted |Should -Be 2
                $result.'Hit Commands'.count | Should -Be 1
                $result.CommandsMissed |Should -Be 1
                $result.'Missed Commands'.count |Should -Be 1
            }
        }

        Context "found assoicated module assert-mockcalled" {

            It 'Should call the assoicated commands' {
                Mock -CommandName Get-ChildItem -MockWith {return $scriptnamereturn} -ParameterFilter {$filter -eq '*.tests.ps1'}
                Mock -CommandName Get-ChildItem -Mockwith {return $scriptpsm} -ParameterFilter {$filter -eq $psm}
                Mock -CommandName Invoke-Pester -Mockwith {return $pesterwpsm1}
                Get-CodeCoverageResult @Goodpath
                Assert-MockCalled -CommandName 'Get-ChildItem' -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName 'Invoke-Pester' -Exactly -Times 1 -Scope It

            }
        }
    }

    <#
    .SYNOPSIS
        Pester tests for Get-MetaTestResults
    #>

    $badPath = (Get-Random).ToString()

    $Goodpath = @{
        RepoPath     = "$Env:Temp"
        TempLocation = $badpath
        ModifiedRepo = 'folder'
        RemoveTempFolder = $true
    }

    $GoodPathNoRemove = @{
        RepoPath         = "$Env:Temp"
        TempLocation     = $badpath
        ModifiedRepo     = 'folder'
        RemoveTempFolder = $false
    }

    $ItemProperty = @{
        Name       = 'temp'
        Attributes = 'Directory'
    }

    $ItemPropertyFile = @{
        Name       = 'file'
        Attributes = 'Archive'
    }

    Describe 'Get-MetaTestResults' {

        Context "Testing all Throws" {

            It "Should error when Repo folder doesn't exist" {

                {Get-MetaTestResult -RepoPath $badPath} |should throw
            }

            It "Should throw when folder Temp Folder already exist" {

                {Get-MetaTestResult -RepoPath $env:temp -TempLocation $env:temp} |should throw
            }

            It "Should throw if Tests folder isn't in the repo" {
                Mock Test-Path -Mockwith { $false } -ParameterFilter {$path -eq "$RepoPath\tests"}

                {Get-MetaTestResult @Goodpath} |should throw
            }

            It 'Should throw if MN_AnalyzerRules is not in the repo' {
                Mock -CommandName Remove-Item {0}
                Mock -CommandName Copy-Item {0}
                Mock Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\tests"}
                Mock Test-Path -Mockwith { $false } -ParameterFilter {$path -eq "$RepoPath\src\Modules\CustomModules\MN-ANalyzerRules"}

                {Get-MetaTestResult @goodPath} |should throw
            }

            It 'Should throw if Item in ModulePath is not found' {
                Mock -CommandName Remove-Item {0}
                Mock -CommandName Copy-Item {0} -ParameterFilter {$path -eq "$RepoPath\tests"}
                Mock -CommandName Copy-Item {0} -ParameterFilter {$path -eq "$RepoPath\src\Modules\CustomModules\MN-ANalyzerRules"}
                Mock -CommandName Test-Path -MockWith {$false} -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\tests"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\src\Modules\CustomModules\MN-ANalyzerRules"}

                {Get-MetaTestResult @goodPath} |should throw
            }

            It 'Should throw if Meta.tests.ps1 is not found' {
                Mock -CommandName Remove-Item {0}
                Mock -CommandName Copy-Item {0} -ParameterFilter {$path -eq "$RepoPath\tests"}
                Mock -CommandName Copy-Item {0} -ParameterFilter {$path -eq "$RepoPath\src\Modules\CustomModules\MN-ANalyzerRules"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\tests"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\src\Modules\CustomModules\MN-ANalyzerRules"}
                Mock -CommandName Test-Path -MockWith {$true} -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Get-ItemProperty -MockWith { return $ItemProperty } -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Copy-Item -Mockwith {0} -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Test-Path {$true} -ParameterFilter {$path -eq "$TempLocation\src\DSC\CustomModules"}
                Mock -CommandName Test-Path {$true} -ParameterFilter {$path -eq "$TempLocation\src\Modules\CustomModules"}
                Mock -CommandName Test-Path {$false} -ParameterFilter {$path -eq "$TempLocation\tests\Unit\Meta.tests.ps1"}

                {Get-MetaTestResult @goodPath} |should throw
            }
        }

        Context 'Assert Mocks' {
            It 'checking assert-mocks for specified Directory' {
                Mock -CommandName Copy-Item {0}
                Mock -CommandName Test-Path {$false} -ParameterFilter {$path -eq "$TempLocation\src\DSC\CustomModules"}
                Mock -CommandName Test-Path {$false} -ParameterFilter {$path -eq "$TempLocation\src\Modules\CustomModules"}
                Mock -CommandName Test-Path {$true} -ParameterFilter {$path -eq "$TempLocation\tests\Unit\Meta.tests.ps1"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\tests"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\src\Modules\CustomModules\MN-ANalyzerRules"}
                Mock -CommandName Test-Path -MockWith {$true} -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Invoke-Pester {0}
                Mock -CommandName Get-Content {return 'test'}
                Mock -CommandName New-Item {0}
                Mock -CommandName Set-Content {0}
                Mock -CommandName Get-ItemProperty -MockWith { return $ItemProperty } -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Remove-Item {0}

                Get-MetaTestResult @goodPath
                Assert-MockCalled -CommandName Get-Content -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Set-Content -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Copy-Item -Exactly -Times 3 -Scope It
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 6 -Scope It
                Assert-MockCalled -CommandName Invoke-Pester -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName New-Item -Exactly -Times 2 -Scope It
            }

            It 'checking assert-mocks for a spcified file' {
                Mock -CommandName Copy-Item {0}
                Mock -CommandName Test-Path {$false} -ParameterFilter {$path -eq "$TempLocation\src\DSC\CustomModules"}
                Mock -CommandName Test-Path {$false} -ParameterFilter {$path -eq "$TempLocation\src\Modules\CustomModules"}
                Mock -CommandName Test-Path {$true} -ParameterFilter {$path -eq "$TempLocation\tests\Unit\Meta.tests.ps1"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\tests"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\src\Modules\CustomModules\MN-ANalyzerRules"}
                Mock -CommandName Test-Path -MockWith {$true} -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Invoke-Pester {0}
                Mock -CommandName New-Item {0}
                Mock -CommandName Get-Content {return 'test'}
                Mock -CommandName Set-Content {0}
                Mock -CommandName Get-ItemProperty -MockWith { return $ItemPropertyFile } -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Remove-Item {0}

                Get-MetaTestResult @goodPath
                Assert-MockCalled -CommandName Get-Content -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Set-Content -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Copy-Item -Exactly -Times 3 -Scope It
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 6 -Scope It
                Assert-MockCalled -CommandName Invoke-Pester -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName New-Item -Exactly -Times 3 -Scope It
            }

            It 'checking assert-mocks for specified Directory and no Temp folder removal' {
                Mock -CommandName Copy-Item {0}
                Mock -CommandName Test-Path {$false} -ParameterFilter {$path -eq "$TempLocation\src\DSC\CustomModules"}
                Mock -CommandName Test-Path {$false} -ParameterFilter {$path -eq "$TempLocation\src\Modules\CustomModules"}
                Mock -CommandName Test-Path {$true} -ParameterFilter {$path -eq "$TempLocation\tests\Unit\Meta.tests.ps1"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\tests"}
                Mock -CommandName Test-Path -Mockwith { $true } -ParameterFilter {$path -eq "$RepoPath\src\Modules\CustomModules\MN-ANalyzerRules"}
                Mock -CommandName Test-Path -MockWith {$true} -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Invoke-Pester {0}
                Mock -CommandName Get-Content {return 'test'}
                Mock -CommandName New-Item {0}
                Mock -CommandName Set-Content {0}
                Mock -CommandName Get-ItemProperty -MockWith { return $ItemProperty } -ParameterFilter {$path -eq "$RepoPath\$item"}
                Mock -CommandName Remove-Item {0}

                Get-MetaTestResult @GoodPathNoRemove
                Assert-MockCalled -CommandName Get-Content -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Set-Content -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Copy-Item -Exactly -Times 3 -Scope It
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 6 -Scope It
                Assert-MockCalled -CommandName Invoke-Pester -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled -CommandName New-Item -Exactly -Times 2 -Scope It
            }
        }
    }
}
