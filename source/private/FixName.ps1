filter FixName {
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [IO.FileInfo]$File,

    [Parameter(Mandatory)]
    [string]$Architecture,

    [Parameter(Mandatory)]
    [string]$OS,

    [Parameter(Mandatory)]
    [string]$Repo,

    [string]$ExecutableName,

    [string[]]$Extensions = @($ENV:PATHEXT -split ';')
)
$NewName = $File.Name
# When there is a manually specified executable name, we use that
if ($ExecutableName) {
    # Make sure the executable name has the right extension
    if ($File.Extension) {
        $ExecutableName = [IO.Path]::ChangeExtension($ExecutableName, $File.Extension)
    }
    # If there is only one file, definitely rename it even if it's unique
    if ($AllFiles.Count -eq 1) {
        $NewName = $ExecutableName
    }
}
# Normally, we only rename the file if it has the OS and/or Architecture in the name (and is executable)
if ($File.BaseName -match $OS -or $File.BaseName -match $Architecture -and ($Extensions.Count -eq 0 -or $File.Extension -in $Extensions)) {
    # Try just removing the OS and Architecture from the name
    if (($NewName = ($File.BaseName -replace "[-_. ]*(?:$OS)[-_. ]*" -replace "[-_. ]*(?:$Architecture)[-_. ]*"))) {
        $NewName = $NewName.Trim("-_. ") + $File.Extension
        # Otherwise, fall back to the repo name
    } elseif ($ExecutableName) {
        $NewName = $ExecutableName
    } else {
        $NewName = $Repo.Trim("-_. ") + $File.Extension
    }
}
if ($NewName -ne $File.Name) {
    Write-Warning "Renaming $File to $NewName"
    $File = Rename-Item $File.FullName -NewName $NewName -PassThru
}

# Some few teams include the docs with their package (e.g. opentofu)
# And I want the user to know these files were available, but not move them
if ($File.BaseName -match "README|LICENSE|CHANGELOG" -or $File.Extension -in ".md", ".rst", ".txt", ".asc", ".doc" ) {
    Write-Verbose "Skipping doc $File"
    continue
}

$File
}
