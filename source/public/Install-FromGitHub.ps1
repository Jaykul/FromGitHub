function Install-FromGitHub {
    <#
    .SYNOPSIS
        Install a binary from a github release.
    .DESCRIPTION
        An installer for single-binary tools released on GitHub.
        This cross-platform script will find the right binary, download it,
        check the file hash, unpack it, and make sure the binary is on your PATH.

        It uses the github API to get the details of the release and find the
        list of downloadable assets, and relies on the common naming convention
        to detect the right binary for your OS (and architecture).

        Although it's not required for casual use (e.g. installing a tool at a
        time), if you're using this in automation, such as build scripts, you
        may set GITHUB_TOKEN in your environment to avoid throttling.
    .EXAMPLE
        Install-FromGitHub FluxCD Flux2

        Install `Flux` from the https://github.com/FluxCD/Flux2 repository
    .EXAMPLE
        Install-FromGitHub EarthBuild/earthbuild

        Install `earth` from the https://github.com/EarthBuild/earthbuild repository
    .EXAMPLE
        Install-FromGitHub https://github.com/junegunn/fzf

        Install `fzf` from the https://github.com/junegunn/fzf repository
    .EXAMPLE
        Install-FromGitHub https://github.com/mikefarah/yq/releases/tag/v4.44.6

        Install the old `yq` version v4.44.6 from its release on github.com
    .EXAMPLE
        Install-FromGitHub BurntSushi ripgrep

        Install `rg` from the https://github.com/BurntSushi/ripgrep repository
    .EXAMPLE
        Install-FromGitHub opentofu opentofu

        Install `opentofu` from the https://github.com/opentofu/opentofu repository
    .EXAMPLE
        Install-FromGitHub twpayne chezmoi

        Install `chezmoi` from the https://github.com/twpayne/chezmoi repository
    .EXAMPLE
        Install-FromGitHub sharkdp/bat
        Install-FromGitHub sharkdp/fd

        Install `bat` and `fd` from their repositories
    .NOTES
        All these examples have (only) been tested on Windows and WSL Ubuntu
    #>
    [Alias("Install-GitHubRelease")]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The user or organization that owns the repository
        # Also supports pasting the org and repo as a single string: fluxcd/flux2
        # Or passing the full URL to the project: https://github.com/fluxcd/flux2
        # Or a specific release: https://github.com/fluxcd/flux2/releases/tag/v2.5.0
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("User")]
        [string]$Org,

        # The name of the repository or project to download from
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [string]$Repo,

        # The tag of the release to download. Defaults to 'latest'
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [Alias("Version")]
        [string]$Tag = 'latest',

        # Skip prompting to create the "BinDir" tool directory (on Windows)
        [switch]$Force,

        # A regex pattern to override selecting the right option from the assets on the release
        # The operating system is automatically detected, you do not need to pass this parameter
        [string]$OS,

        # A regex pattern to override selecting the right option from the assets on the release
        # The architecture is automatically detected, you do not need to pass this parameter
        [string]$Architecture,

        # The location to install to.
        # Defaults to $Env:LocalAppData\Programs\Tools on Windows, /usr/local/bin on Linux/MacOS
        # There's normally no reason to pass this parameter
        # If you want to change the default, set the FROMGITHUB_BINDIR environment variable
        [string]$BinDir,

        # Optionally, the file name for the executable (it will be renamed to this)
        [string]$ExecutableName
    )
    begin {
        $ErrorActionPreference = "Stop"

        # Really this should just be a default value, but GetOSPlatform is private because it's weird, ok?
        if (!$OS) {
            $OS = GetOSPlatform -Pattern
            $PSBoundParameters["OS"] = $OS
        }
        if (!$Architecture) {
            $Architecture = GetOSArchitecture -Pattern
            $PSBoundParameters["Architecture"] = $Architecture
        }

        # Make sure there's a place to put the binary on the PATH
        $BinDir = InitializeBinDir $BinDir -Force:$Force
    }
    process {

        $release = GetGitHubRelease @PSBoundParameters
        # Update the $Repo (because we use it as a fallback name) after parsing argument handling
        $PSBoundParameters["Repo"] = $Repo = $release.Repo
        $PSBoundParameters["Tag"] = $release.tag_name
        $null = $PSBoundParameters.Remove("Org")

        $asset = SelectAssetByPlatform -assets $release.assets -OS $OS -Architecture $Architecture

        # Make a random folder to unpack in
        $workInTemp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        New-Item -Type Directory -Path $workInTemp | Out-Null

        Push-Location $workInTemp
        $AssetDir = GetAsset $asset -Repo $Repo
        Pop-Location

        Write-Verbose "Moving the executable(s) from $AssetDir to $BinDir"
        MoveExecutable -AssetDir $AssetDir -BinDir $BinDir @PSBoundParameters -Force:$Force

        Remove-Item $workInTemp -Recurse
    }
}
