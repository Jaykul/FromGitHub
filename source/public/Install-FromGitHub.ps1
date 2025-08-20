function Install-FromGitHub {
    <#
    .SYNOPSIS
        Install a binary from a github release.
    .DESCRIPTION
        An installer for single-binary tools released on GitHub.
        This cross-platform script will download, check the file hash,
        unpack and and make sure the binary is on your PATH.

        It uses the github API to get the details of the release and find the
        list of downloadable assets, and relies on the common naming convention
        to detect the right binary for your OS (and architecture).
    .EXAMPLE
        Install-GithubRelease FluxCD Flux2

        Install `Flux` from the https://github.com/FluxCD/Flux2 repository
    .EXAMPLE
        Install-GithubRelease earthly earthly

        Install `earthly` from the https://github.com/earthly/earthly repository
    .EXAMPLE
        Install-GithubRelease junegunn fzf

        Install `fzf` from the https://github.com/junegunn/fzf repository
    .EXAMPLE
        Install-GithubRelease BurntSushi ripgrep

        Install `rg` from the https://github.com/BurntSushi/ripgrep repository
    .EXAMPLE
        Install-GithubRelease opentofu opentofu

        Install `opentofu` from the https://github.com/opentofu/opentofu repository
    .EXAMPLE
        Install-GithubRelease twpayne chezmoi

        Install `chezmoi` from the https://github.com/twpayne/chezmoi repository
    .EXAMPLE
        Install-GitHubRelease https://github.com/mikefarah/yq/releases/tag/v4.44.6

        Install `yq` version v4.44.6 from it's release on github.com
    .EXAMPLE
        Install-GithubRelease sharkdp/bat
        Install-GithubRelease sharkdp/fd

        Install `bat` and `fd` from their repositories
    .NOTES
        All these examples are (only) tested on Windows and WSL Ubuntu
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
        [string]$BinDir,

        # Optionally, the file name for the executable (it will be renamed to this)
        [string]$ExecutableName
    )
    process {
        # Really this should just be a default value, but GetOSPlatform is private because it's weird, ok?
        if (!$OS) {
            $OS = GetOSPlatform -Pattern
            $PSBoundParameters["OS"] = $OS
        }
        if (!$Architecture) {
            $Architecture = GetOSArchitecture -Pattern
            $PSBoundParameters["Architecture"] = $Architecture
        }
        $release = GetGitHubRelease @PSBoundParameters

        $asset = SelectAssetByPlatform -assets $release.assets @PSBoundParameters

        # Make a random folder to unpack in
        $WorkingTemp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        New-Item -Type Directory -Path $WorkingTemp | Out-Null
        Push-Location $WorkingTemp

        $PackagePath = GetPackage $asset -WorkingName $release.Repo

        # Make sure there's a place to put the binary on the PATH
        $BinDir = InitializeBinDir $BinDir -Force:$Force

        Write-Verbose "Moving the executable(s) from $PackagePath to $BinDir"
        MoveExecutable -FromDir $PackagePath -ToDir $BinDir @PSBoundParameters

        Pop-Location

        Remove-Item $WorkingTemp -Recurse
    }
}
