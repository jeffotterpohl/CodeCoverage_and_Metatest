<#
    .SYNOPSIS
        Scans the specified module for all *.tests.ps1 files and looks for the specified module and runs Pester tests
        and also looks at code coverage.  Assumption is the test.ps1 has the same first name as the module.
        example: Pester test name: script.test.ps1 PSM1 name: script.psm1

    .PARAMETER ModulePath
        Specify the full root path to the module module to be evaluated for Script Analyzer.

    .Example
        $ModulePath = "C:\Source\repos\DSC_Images\src\DSC\CustomModules\OcspDsc"
        Get-CodeCoverageResults -ModulePath $ModulePath
#>

Function Get-CodeCoverageResults
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ModulePath
    )

    if ((Test-Path $ModulePath))
    {
        $ptCoverage = New-Object System.Collections.ArrayList
        $testsPS1 = Get-ChildItem -Path $ModulePath -Filter *.tests.ps1 -Exclude *.Integration.Tests.ps1 -Recurse | where-object { $_.FullName -inotmatch 'DscResource.Tests' }

        if (($testsPS1))
        {
            foreach ($testPS1 in $testsPS1)
            {
                $pto = New-Object PSObject

                $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'Test Script' -Value $($testPS1.Name) -PassThru
                $psm = ($testPS1.name).split('.')
                $psm = $psm[0] + '*.psm1'
                $psmChild = Get-ChildItem -Path $ModulePath -Filter $psm -Recurse
                if ($Null -ne $psmChild)
                {
                    $pester = Invoke-Pester -script $testPS1.FullName -CodeCoverage $psmChild.FullName -Verbose -PassThru

                    $hitCommandCount = $pester.CodeCoverage.HitCommands | Group-object -Property Function| Select-Object Name, Count
                    $missedCommandCount = $pester.CodeCoverage.MissedCommands | Group-object -Property Function| Select-Object Name, Count

                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'Module' -Value $psmChild.Name -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'TotalCount' -Value $pester.TotalCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'PassCount' -Value $pester.passedCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'FailedCount' -Value $pester.FailedCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'SkippedCount' -Value $pester.SkippedCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'CommandsAnalyzed' -Value $pester.CodeCoverage.NumberOfCommandsAnalyzed -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'CommandsExecuted' -Value $pester.CodeCoverage.NumberOfCommandsExecuted -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'Hit Commands' -Value $hitCommandCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'CommandsMissed' -Value $pester.CodeCoverage.NumberOfCommandsMissed -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'Missed Commands' -Value $missedCommandCount -PassThru
                }
                else
                {
                    $pester = Invoke-Pester -script $testPS1.FullName -Verbose -PassThru

                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'Module' -Value 'Unable to find the associated psm1' -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'TotalCount' -Value $pester.TotalCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'PassCount' -Value $pester.passedCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'FailedCount' -Value $pester.FailedCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'SkippedCount' -Value $pester.SkippedCount -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'CommandsAnalyzed' -Value 'Code Coverage not analyzed' -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'CommandsExecuted' -Value 'Code Coverage not analyzed' -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'Hit Commands' -Value 'Code Coverage not analyzed' -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'CommandsMissed' -Value 'Code Coverage not analyzed' -PassThru
                    $pt = Add-Member -InputObject $pto -MemberType NoteProperty -Name 'Missed Commands' -Value 'Code Coverage Not Analyzed' -PassThru
                }
                $ptCoverage.Add($pt) |Out-Null
            }
            $ptCoverage
        }
        else
        {
            write-error "Unable to find any .tests.ps1 files in the specified directory"
        }
    }
    else
    {
        write-error "Path does not exist $ModulePath"
    }
}

<#
    .SYNOPSIS
        Provides the capability to run the Meta.Tests.ps1 on your modified folder\files residing in the Repo prior
        to submitted a Pull Requestion. This will assist with ensuring a successful build.

    .PARAMETER RepoPath
        Specifies the location of the source repo upto and including DSC_Images example: C:\source\Repos\DSC_Images.

    .PARAMETER TempLocation
        Specifies the temp location where folder(s)\file(s) will be copied to allow modifications and scan only the required files.
        The temp location should not exist prior to running this script.

    .PARAMETER ModifiedRepo
        Specifies the folder(s)\file(s) will be copied to allow modifications and scan only the required files.
        Specifies the path after DSC_Images and name (example: src\DSC\CustomModules\MN_ActiveDirectoryCSDsc)
        of your modified resource to be copied to the TempLocation for evaluation

    .PARAMETER RemoveTempFolder
        Specifies if the temporary locations should be deleted after running the tests. Default value is $true

    .Example
        $repoPath = 'C:\Source\repos\DSC_Images'
        $tempLocation = "$env:temp\folder"
        $modifiedRepo = @("src\DSC\CustomModules\MN_ActiveDirectoryCSDsc")
        Get-MetatestResults -RepoPath $RepoPath -TempLocation $TempLocation -ModifiedRepo $Modifiedrepo -RemoveTempFolder $true

    .Example
        $repoPath = 'C:\Source\repos\DSC_Images'
        $tempLocation = "$env:temp\folder"
        $modifiedRepo = @("src\DSC\CustomModules\MN_ActiveDirectoryCSDsc","src\DSC\CustomModules\AppInstall\ActivClient.psd1")
        Get-MetatestResults -RepoPath $RepoPath -TempLocation $TempLocation -ModifiedRepo $Modifiedrepo -RemoveTempFolder $true
#>

Function Get-MetatestResults
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $RepoPath,

        [Parameter(Mandatory = $true)]
        [String]
        $TempLocation,

        [Parameter(Mandatory = $true)]
        [String[]]
        $ModifiedRepo,

        [Parameter()]
        [Bool]
        $RemoveTempFolder = $true
    )

    if ((Test-Path $RepoPath))
    {
        if (!(Test-Path $TempLocation))
        {
            #copies the required test folder from the repo
            if (Test-Path $RepoPath\tests)
            {
                Copy-Item $RepoPath\tests $TempLocation\tests -Recurse
            }
            else
            {
                write-error "The $RepoPath\Tests folder could not be found" -ErrorAction Stop
            }

            #copies the custom analyzer rules
            if (Test-path $RepoPath\src\Modules\CustomModules\MN-ANalyzerRules)
            {
                Copy-Item $RepoPath\src\Modules\CustomModules\MN-ANalyzerRules $TempLocation\tests\MN-AnalyzerRules -Recurse
            }
            else
            {
                if ($RemoveTempFolder)
                {
                    Remove-item $TempLocation -Recurse -Force
                }

                write-error "The MN_Analyzer Rules folder could not be found" -ErrorAction Stop
            }

            #copys the specified modified folder(s)\file(s)
            foreach ($item in $ModifiedRepo)
            {
                if (Test-Path $RepoPath\$item)
                {
                    $fileOrFolder = Get-ItemProperty $RepoPath\$item

                    if ($fileOrFolder.Attributes -eq 'Directory')
                    {
                        Copy-Item $RepoPath\$item $TempLocation\$item -Recurse
                    }
                    else
                    {
                        $fileLoc = ($item.Split('\'))[0..($item.Split('\').count - 2)] -join '\'
                        New-Item -ItemType Directory $TempLocation\$fileLoc |Out-Null
                        Copy-Item $RepoPath\$item $TempLocation\$fileLoc
                    }
                }
                else
                {
                    if ($RemoveTempFolder)
                    {
                        Remove-item $TempLocation -Recurse -Force
                    }

                    write-error "The specified path: $item could not be found in $RepoPath" -ErrorAction Stop
                }
            }

            #Creates the DSC\CustomModules folder as required by the Meta.Tests if not already exists
            if (!(Test-Path "$TempLocation\src\DSC\CustomModules"))
            {
                New-Item -ItemType Directory $TempLocation\src\DSC\CustomModules |Out-Null
            }

            #Creates the Modules\CustomModules folder as required by the Meta.Tests if not already exists
            if (!(Test-Path "$TempLocation\src\Modules\CustomModules"))
            {
                New-Item -ItemType Directory $TempLocation\src\Modules\CustomModules |Out-Null
            }

            #Modify the Meta.Tests.ps1 file to point to the new location for MN_AnalyzerRules as to ensure custom rules are not scanned by Meta.Tests
            if (Test-Path $TempLocation\tests\Unit\Meta.tests.ps1)
            {
                $mTest1 = "Join-Path -Path `$srcRoot -ChildPath 'Modules\CustomModules\MN-AnalyzerRules'"
                $mTest2 = "Join-Path -Path `$testsRoot -ChildPath 'MN-AnalyzerRules'"
                (Get-content $TempLocation\tests\Unit\Meta.tests.ps1).replace($mTest1, $mTest2) |set-Content $TempLocation\tests\Unit\Meta.tests.ps1

                Invoke-Pester -Script $TempLocation\Tests\Unit\Meta.Tests.ps1 -Verbose
            }
            else
            {
                if ($RemoveTempFolder)
                {
                    Remove-item $TempLocation -Recurse -Force
                }

                Write-Error "Unable to find the Meta.tests.ps1 file to make modifications to point to the custom AnalyzerRules." -ErrorAction Stop
            }

            #if specified deletes the Temporary location
            if ($RemoveTempFolder)
            {
                Remove-item $TempLocation -Recurse -Force
            }
        }
        else
        {
            Write-Error "The specified temp location: $TempLocation already exists. Please delete prior to launching." -ErrorAction Stop
        }
    }
    else
    {
        Write-Error "The specified Repo path is invalid." -ErrorAction Stop
    }
}
