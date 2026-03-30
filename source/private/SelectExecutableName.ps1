function SelectExecutableName {
    <#
        .SYNOPSIS
            Selects a name for the executable that doesn't include the OS/Architecture/Version in the name
    #>
    [CmdletBinding()]
    param(
        # A regex pattern to select the right asset for this OS
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string]$OS,

        # A regex pattern to select the right asset for this architecture
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string]$Architecture,

        # An explicit user-supplied name for the executable
        [string]$ExecutableName,

        # The name of the repository, as a fallback for the executable name
        [string]$Repo,

        # The tag of the release we downloaded, in case we need to trim it from the name
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string]$Tag,

        # For testing purposes, override OS detection
        [switch]$IsPosix = $IsLinux -or $IsMacOS,

        # The file to pick a name for
        [System.IO.FileInfo]$File,

        # If set, forces picking a new file name
        [switch]$Force,

        # A list of file extensions to consider executable
        # By default, empty on Linux/MacOS, and $Env:PATHEXT on Windows
        $FilterExtensions = @(if (-not $IsPosix) {
                # On Windows, only rename it if  has an executable extension
                @($ENV:PATHEXT -split ';') + '.EXE'
            })
    )
    $Tag = [Regex]::Escape($Tag)

    # If the file has the OS and/or Architecture in the name (and an executable extension if we're on Windows)
    $PlatformSpecific = $File.BaseName -match $OS -or $File.BaseName -match $Architecture
    if ($Force -or ($PlatformSpecific -and ($FilterExtensions.Count -eq 0 -or $File.Extension -in $FilterExtensions))) {
        # When there is a manually specified executable name, we use that
        if ($ExecutableName) {
            # Make sure the executable name has the right extension
            if ($File.Extension) {
                [IO.Path]::ChangeExtension($ExecutableName, $File.Extension)
            } else {
                $ExecutableName
            }
            # Try just removing the OS, Architecture, and Tag from the name
        } elseif ($PlatformSpecific -and ($NewName = ($File.BaseName -replace "[-_. ]*(?:$Tag)[-_. ]*" -replace "[-_. ]*(?:$OS)[-_. ]*" -replace "[-_. ]*(?:$Architecture)[-_. ]*"))) {
            $NewName.Trim("-_. ") + $File.Extension
        } else {
            # Otherwise, fall back to the repo name
            $Repo.Trim("-_. ") + $File.Extension
        }
    } else {
        $File.Name
    }
}
