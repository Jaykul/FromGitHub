<#
.SYNOPSIS
    ./Build.build.ps1
.EXAMPLE
    Invoke-Build
.NOTES
    0.5.0 - Parameterize
    Add parameters to this script to control the build
#>
[CmdletBinding()]
param(
    # dotnet build configuration parameter (Debug or Release)
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    # Add the clean task before the default build
    [switch]$Clean,

    # Collect code coverage when tests are run
    [switch]$CollectCoverage
)
$InformationPreference = "Continue"
$ErrorView = 'DetailedView'

# The name of the module to build and publish
$script:PSModuleName = "FromGitHub"
$script:RequiredCodeCoverage = 0.70

# Use Env because Earthly can override it
$Env:OUTPUT_ROOT ??= Join-Path $BuildRoot Modules

$SharedTasks = "../Tasks", "../../Tasks" | Convert-Path -ErrorAction Ignore | Select-Object -First 1
Write-Information "$($PSStyle.Foreground.BrightCyan)Found shared tasks in $SharedTasks" -Tag "InvokeBuild"

## Self-contained build script - can be invoked directly or via Invoke-Build
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
    & "$SharedTasks/_Bootstrap.ps1"
    Write-Host Build $MyInvocation.ScriptName -ForegroundColor Green
    Invoke-Build -File $MyInvocation.MyCommand.Path @PSBoundParameters -Result Result

    if ($Result.Error) {
        $Error[-1].ScriptStackTrace | Out-String
        exit 1
    }
    exit 0
}

Add-BuildTask . PSModuleBuild, RenameScript

Add-BuildTask RenameScript {
    $ScriptName = "Install-GitHubRelease.ps1"
    Get-ChildItem -Path $Env:OUTPUT_ROOT -Filter "*.ps1" -Directory -ErrorAction Ignore
    | Rename-Item -NewName $ScriptName
}

## Initialize the build variables, and import shared tasks, including DotNet tasks
. "$SharedTasks/_Initialize.ps1"
