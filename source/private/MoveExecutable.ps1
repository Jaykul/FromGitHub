function MoveExecutable {
    # Some teams (e.g. earthly/earthly), name the actual binary with the platform name
    # We do not want to type earthly_win64.exe every time, so rename to the base name...
    # DO NOT USE `[CmdletBinding()]` or [Parameter()]
    # We splat the parameters from Install-GitHubRelease and we need to ignore the extras
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The directory where the asset was extracted to (i.e. the output of GetAsset)
        [string]$AssetDir,

        # The directory to move the executable(s) to (i.e. the output of InitializeBinDir)
        [Alias("TargetDirectory")]
        [string]$BinDir,

        # A regex pattern to select the right asset for this OS
        [string]$OS,

        # A regex pattern to select the right asset for this architecture
        [string]$Architecture,

        # An explicit user-supplied name for the executable
        [string]$ExecutableName,

        # The name of the repository, as a fallback for the executable name
        [string]$Repo,

        # The tag of the release we downloaded, in case we need to trim it from the name
        [string]$Tag,

        # For testing purposes, override OS detection
        [switch]$IsPosix = $IsLinux -or $IsMacOS,

        # Skip ShouldProcess confirmation when moving files
        [switch]$Force
    )
    $AllFiles = Get-ChildItem $AssetDir -File -Recurse
    if ($AllFiles.Count -eq 0) {
        Write-Warning "No executables found in $AssetDir"
        return
    }
    foreach ($File in $AllFiles) {
        $null = $PSBoundParameters.Remove("BinDir")
        $null = $PSBoundParameters.Remove("AssetDir")
        # I added a -Force switch to SelectExecutableName to allow forcing the selection of a new name for the file ...
        # But it tends to produce unexpected results, like the `Flux2` produces flux.exe which if you -Force will get renamed to flux2.exe
        $NewName = SelectExecutableName -File $File @PSBoundParameters

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

        Write-Verbose "Moving $File to $BinDir"

        # On non-Windows systems, we might need sudo to copy (if the folder is write protected)
        if ($IsPosix -and (Get-Item $BinDir -Force).Attributes -eq "ReadOnly,Directory") {
            if ($Force -or $PSCmdlet.ShouldProcess("Moving $File requires elevated permissions. Do you want to continue?", "$BinDir")) {
                sudo mv -f $File.FullName $BinDir
                sudo chmod +x "$BinDir/$($File.Name)"
            }
        } else {
            if (Test-Path $BinDir/$($File.Name)) {
                Remove-Item $BinDir/$($File.Name) -Recurse -Force
            }
            $Executable = Move-Item $File.FullName -Destination $BinDir -Force -ErrorAction Stop -PassThru
            if ($IsPosix -and ($Force -or $PSCmdlet.ShouldProcess("Setting eXecute bit", $Executable.FullName))) {
                chmod +x $Executable.FullName
            }
        }
        # Output the moved item, because sometimes our "using someearthly_version_win64.zip" message is confusing
        Get-Item (Join-Path $BinDir $File.Name) -ErrorAction Ignore
    }
}
