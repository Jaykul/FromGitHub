function New-ImageFromGithub {
    <#
    .SYNOPSIS
        Creates a new cross-platform Docker image from the binaries in a GitHub release.

    .DESCRIPTION
        This function takes a GitHub release and builds Windows and Linux images from the binaries found in the release assets.

        Then it creates a multi-architecture manifest that points to the appropriate images for each platform.

        Then it creates an application-only manifest that points to the layers with the binaries.
    #>
    [CmdletBinding()]
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

        # Optionally, the file name for the executable (the binary will be renamed to this)
        [string]$ExecutableName
    )

    # First make sure we can find that release
    $release = GetGitHubRelease @PSBoundParameters

    # Make a random folder to unpack in
    $WorkingTemp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -Type Directory -Path $WorkingTemp | Out-Null
    Push-Location $WorkingTemp

    # Then, build a Linux AMD64 image
    $linux = SelectAssetByPlatform -Assets $release.assets -Architecture "amd64|x64|x86_64" -OS "linux|unix"

    # Results in a Push-Location to a temp folder
    $PackagePath = GetPackage $linux -WorkingName $release.Repo

    # Make sure there's a place to put the binary on the PATH
    $BinDir = New-Item -Type Directory -Path (Join-Path $WorkingTemp "bin") -Force | Convert-Path

    Write-Verbose "Moving the executable(s) from $PackagePath to $BinDir"
    Get-ChildItem $PackagePath -File
    | FixName -Architecture "amd64|x64|x86_64" -OS "linux|unix" -Repo $release.Repo
    | Move-Item -Destination $BinDir -Force -ErrorAction Stop -PassThru -OutVariable executable
    | ForEach-Object {
        if ($IsLinux -or $IsMacOS) {
            chmod +x $_.FullName
        }
    }

    # Now copy it into our base image.
    @(
    "FROM gcr.io/distroless/static-debian12"
    "COPY bin/ /"
    "CMD [`"/$($Executable[0].Name)`"]"
    ) | Set-Content "$($release.Repo)-linux.Dockerfile" -Encoding utf8 -Force
    docker buildx build --platform linux/amd64 -t "$($release.Repo)-linux" -f "$($release.Repo)-linux.Dockerfile" .


    $windows = SelectAssetByPlatform -assets $release.assets  -Architecture "amd64|x64|x86_64" -OS "windows|(?<!dar)win"
    # Results in a Push-Location to a temp folder
    $PackagePath = GetPackage $windows -WorkingName $release.Repo

    # Make sure there's a place to put the binary on the PATH
    $WinDir = New-Item -Type Directory -Path (Join-Path $WorkingTemp "win") -Force | Convert-Path

    Write-Verbose "Moving the executable(s) from $PackagePath to $WinDir"
    Get-ChildItem $PackagePath -File
    | FixName -Architecture "amd64|x64|x86_64" -OS "linux|unix" -Repo $release.Repo
    | Move-Item -Destination $WinDir -Force -ErrorAction Stop -PassThru -OutVariable executable
    | ForEach-Object {
        if ($IsLinux -or $IsMacOS) {
            chmod +x $_.FullName
        }
    }


    # Now copy it into our base image.
    @(
        "FROM mcr.microsoft.com/windows/nanoserver:ltsc2025"
        "COPY win/ C:/"
        "CMD [`"C:/$($Executable[0].Name)`"]"
    ) | Set-Content "$($release.Repo)-windows.Dockerfile" -Encoding utf8 -Force
    docker buildx build --platform windows/amd64 -t "$($release.Repo)-windows" -f "$($release.Repo)-windows.Dockerfile" .

    Pop-Location
}
