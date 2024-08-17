#
# RunPester.ps1
#

Import-Module Pester -PassThru
<#
$LogCommandHealthEvent = $True
$LogCommandLifecycleEvent = $True
$PSModuleAutoloadingPreference = 'All'
# SILENTLYCONTINUE, STOP, CONTINUE, INQUIRE, IGNORE, SUSPEND, or BREAK.
$DebugPreference = 'Continue'
$ErrorActionPreference = 'Continue'
$InformationPreference = 'Continue'
$ProgressPreference = 'Continue'
$VerbosePreference = 'Continue'
$WhatIfPreference = $False
$WarningPreference = 'Continue' # Enquire

$PSDefaultParameterValues += @{"*:Debug"=$True}
$PSDefaultParameterValues += @{"*:Verbose"=$True}
$PSDefaultParameterValues += @{"*:Confirm"=$False}
#>

if ( "RunPester" -like $args) {
    $transcript = Join-Path -Path $PSScriptRoot -ChildPath 'Cam2Web-pwsh-transcript.txt'
    if (Test-Path $transcript) {
        Remove-Item $transcript 
    }
    Start-Transcript -Path "$transcript"

    $config = New-PesterConfiguration
    $config.Run.Path = ".\Cam2Web-Pwsh.Tests.ps1"
    $config.CodeCoverage.Enabled = $true
    $config.Output.Verbosity = 'Diagnostic'
    $config.Debug.WriteDebugMessages = $true
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = "NUnit3"

    # Optional to scope the coverage to the list of files or directories in this path
    $config.CodeCoverage.Path = ".\Cam2Web-Pwsh.ps1"

    Invoke-Pester -Configuration $config

}
else {
    Write-Verbose -Message "=========Cam2Web-Pwsh.ps1 is sourced."
}