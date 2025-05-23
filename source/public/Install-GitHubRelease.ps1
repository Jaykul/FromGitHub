function Install-GitHubRelease {
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
        $OS,

        # A regex pattern to override selecting the right option from the assets on the release
        # The architecture is automatically detected, you do not need to pass this parameter
        $Architecture,

        # The location to install to.
        # Defaults to $Env:LocalAppData\Programs\Tools on Windows, /usr/local/bin on Linux/MacOS
        # There's normally no reason to pass this parameter
        [string]$BinDir
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
        # Update the $Repo (because we use it as a fallback name) after parsing argument handling
        $Repo = $release.Repo

        $asset = SelectAssetByPlatform -assets $release.assets @PSBoundParameters

        # Make a random folder to unpack in
        $workInTemp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        New-Item -Type Directory -Path $workInTemp | Out-Null
        Push-Location $workInTemp

        # Download into our workInTemp folder
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $asset.name -Verbose:$false

        # There might be a checksum file
        if ($asset.ChecksumUrl) {
            if (!(Test-FileHash -Target $asset.name -Checksum $asset.ChecksumUrl)) {
                throw "Checksum mismatch for $($asset.name)"
            }
        } else {
            Write-Warning "No checksum file found, skipping checksum validation for $($asset.name)"
        }

        # If it's an archive, expand it (inside our workInTemp folder)
        # We'll keep the folder the executable is in as $PackagePath either way.
        if ($asset.Extension -and $asset.Extension -ne ".exe") {
            $File = Get-Item $asset.name
            New-Item -Type Directory -Path $Repo |
                Convert-Path -OutVariable PackagePath |
                Set-Location

            Write-Verbose "Extracting $File to $PackagePath"
            if ($asset.Extension -eq ".zip") {
                Microsoft.PowerShell.Archive\Expand-Archive $File.FullName
            } else {
                if ($VerbosePreference -eq "Continue") {
                    tar -xzvf $File.FullName
                } else {
                    tar -xzf $File.FullName
                }
            }
            # Return to the workInTemp folder
            Set-Location $workInTemp
        } else {
            $PackagePath = $workInTemp
        }

        # Make sure there's a place to put the binary on the PATH
        $BinDir = InitializeBinDir $BinDir -Force:$Force

        Write-Verbose "Moving the exectuable(s) from $PackagePath to $BinDir"
        MoveExecutable -FromDir $PackagePath -ToDir $BinDir @PSBoundParameters

        Pop-Location

        Remove-Item $workInTemp -Recurse
    }
}
