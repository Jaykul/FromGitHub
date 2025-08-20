function MoveExecutable {
    # Some teams (e.g. earthly/earthly), name the actual binary with the platform name
    # We do not want to type earthly_win64.exe every time, so rename to the base name...
    # DO NOT USE `[CmdletBinding()]` or [Parameter()]
    # We splat the parameters from Install-GitHubRelease and we need to ignore the extras
    param(
        [string]$FromDir,

        [Alias("TargetDirectory")]
        [string]$ToDir,

        # A regex pattern to select the right asset for this OS
        [string]$OS,

        # A regex pattern to select the right asset for this architecture
        [string]$Architecture,

        # An explicit user-supplied name for the executable
        [string]$ExecutableName,

        # The name of the repository, as a fallback for the executable name
        [string]$Repo,

        # For testing purposes, override OS detection
        [switch]$IsPosix = $IsLinux -or $IsMacOS
    )
    $AllFiles = Get-ChildItem $FromDir -File -Recurse
    if ($AllFiles.Count -eq 0) {
        Write-Warning "No executables found in $FromDir"
        return
    }

    foreach ($File in $AllFiles) {
        $null = $PSBoundParameters.Remove("ToDir")
        $File = FixName -File $File @PSBoundParameters

        Write-Verbose "Moving $File to $ToDir"
        # On non-Windows systems, we might need sudo to copy (if the folder is write protected)
        if ($IsPosix -and (Get-Item $ToDir -Force).Attributes -eq "ReadOnly,Directory") {
            sudo mv -f $File.FullName $ToDir
            sudo chmod +x "$ToDir/$($File.Name)"
        } else {
            if (Test-Path $ToDir/$($File.Name)) {
                Remove-Item $ToDir/$($File.Name) -Recurse -Force
            }
            $Executable = Move-Item $File.FullName -Destination $ToDir -Force -ErrorAction Stop -PassThru
            if ($IsPosix) {
                chmod +x $Executable.FullName
            }
        }
        # Output the moved item, because sometimes our "using someearthly_version_win64.zip" message is confusing
        Get-Item (Join-Path $ToDir $File.Name) -ErrorAction Ignore
    }
}
