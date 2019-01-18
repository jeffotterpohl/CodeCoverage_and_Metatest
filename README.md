# CodeCoverage_and_Metatest

The **CodeCoverage_and_MetaTest** is a module that was created to assist with running CodeCoverage and Meta.Test for individual module(s).  This has been tested using Pester version 4.4.2

## Resources
**Get-CodeCoverageResult**: This function is used to search a path for all .tests.ps1 files and then try and find the assoicated PS Module and run Invoke-Pester with the CodeCoverage option pointing to the found psm module.  If the psm is not found Pester is still ran but the data returned after the test is reduced.

**Get-MetaTestResult**:  This function is used to run Meta.Test.ps1 on folder(s) or files(s).  It copies the specified modules from your branch and moves to a temporary location.  Copies the needed files for Meta.Test to run and the asscoiated Analayzer Rules.  Modifies the Meta.Tests.ps1 file to point to a new location for the custom Analyzer Rules to ensure they are not scanned as part of the Meta.Test.ps1 scan. 
### Get-CodeCoverageResult

This function can be used to run Invoke-Pester on an assoicated path.  Gather information and then after running the Pester Tests returns a summary of at the end of the tests to give an overview of the results from Pester Tests.

 - **`[string]` ModulePath** (_Required_):  This specifies the location to which to look for the tests.ps1 and the psm files.
 
 ####  Get-CodeCoverageResult Examples
 - [Get-CodeCoverageResult -ModulePath C:\temp]
 
 ### Get-MetaTestResult
 
 This function can be used to speed up Meta.Tests.ps1 if you currently have a lot of items in your branch and only want to scan a small subset of module(s) or file(s). 
 
 -  **`[string]` RepoPath** (_Required_):  Specifies the location of the source repo.
 -  **`[string]` TempLocation** (_Required_):  Specifies the location that does not currently exist and this will be the staging area for the scan.
 -  **`[string[]]` ModifiedRepo** (_Required_):  Specifies the path to the module (the path that follows RepoPath)
 -  **`[Boolean]` RemoveTempFolder** (_write_): Specifies if the TempLocation specified above should be deleted after running the test.  Default value is $true
  
  #### Get-MetaTestResult Examples
  Get-MetaTestResult -RepoPath 'C:\Source' -TempLocation $env:temp\folder -ModifiedRepo Modules\CustomModules\One -RemoveTempFolder $false
  
  ## Versions
  
  ### Unreleased
  
  
  
