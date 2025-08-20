function GetPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Asset,

        [string]$WorkingName
    )

    # Download into our WorkingTemp folder
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

    # If it's an archive, expand it (inside our WorkingTemp folder)
    # We'll keep the folder the executable is in as $PackagePath either way.
    if ($asset.Extension -and $asset.Extension -ne ".exe") {
        $File = Get-Item $asset.name
        New-Item -Type Directory -Path $Repo |
            Convert-Path -OutVariable PackagePath |
            Push-Location

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
        $PackagePath
        # Return to the WorkingTemp folder
        Pop-Location
    } else {
        $Pwd.Path
    }
}
