function MoveExecutable {
    # Some teams (e.g. earthly/earthly), name the actual binary with the platform name
    # We do not want to type earthly_win64.exe every time, so rename to the base name...
    # DO NOT USE `[CmdletBinding()]` or [Parameter()]
    # We splat the parameters from Install-GitHubRelease and we need to ignore the extras
    [CmdletBinding(SupportsShouldProcess)]
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
        [switch]$IsPosix = $IsLinux -or $IsMacOS,

        # Skip ShouldProcess confirmation when moving files
        [switch]$Force
    )
    $AllFiles = Get-ChildItem $FromDir -File -Recurse
    if ($AllFiles.Count -eq 0) {
        Write-Warning "No executables found in $FromDir"
        return
    }
    foreach ($File in $AllFiles) {
        $null = $PSBoundParameters.Remove("ToDir")
        $null = $PSBoundParameters.Remove("FromDir")
        $NewName = SelectExecutableName -File $File -Force:($AllFiles.Count -eq 1) @PSBoundParameters

        if ($NewName -ne $File.Name) {
            Write-Warning "Renaming $File to $NewName"
            $File = Rename-Item $File.FullName -NewName $NewName -PassThru
        }

        # Some few projects include the docs with their package (e.g. opentofu)
        # And I want the user to know these files were available, but not move them
        if ($File.BaseName -match "README|LICENSE|CHANGELOG" -or $File.Extension -in ".md", ".rst", ".txt", ".asc", ".doc" ) {
            Write-Verbose "Skipping doc $File"
            continue
        }

        Write-Verbose "Moving $File to $ToDir"

        # On non-Windows systems, we might need sudo to copy (if the folder is write protected)
        if ($IsPosix -and (Get-Item $ToDir -Force).Attributes -eq "ReadOnly,Directory") {
            if ($Force -or $PSCmdlet.ShouldProcess("Moving $File requires elevated permissions. Do you want to continue?", "$ToDir")) {
                sudo mv -f $File.FullName $ToDir
                sudo chmod +x "$ToDir/$($File.Name)"
            }
        } else {
            if (Test-Path $ToDir/$($File.Name)) {
                Remove-Item $ToDir/$($File.Name) -Recurse -Force
            }
            $Executable = Move-Item $File.FullName -Destination $ToDir -Force -ErrorAction Stop -PassThru
            if ($IsPosix -and ($Force -or $PSCmdlet.ShouldProcess("Setting eXecute bit", $Executable.FullName))) {
                chmod +x $Executable.FullName
            }
        }
        # Output the moved item, because sometimes our "using someearthly_version_win64.zip" message is confusing
        Get-Item (Join-Path $ToDir $File.Name) -ErrorAction Ignore
    }
}
