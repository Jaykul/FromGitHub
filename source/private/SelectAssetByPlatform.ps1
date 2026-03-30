function SelectAssetByPlatform {
    # DO NOT USE `[CmdletBinding()]` or [Parameter()]
    # We splat the parameters from Install-GitHubRelease and we need to ignore the extras
    param(
        $Assets,

        # A regex pattern to select the right asset for this OS
        [string]$OS,

        # A regex pattern to select the right asset for this architecture
        [string]$Architecture
    )
    # On Linux, we should prefer musl if it's available because the system is probably musl based
    $IsMusl = if ($IsLinux) {
        [bool](Get-ChildItem /usr/lib/ -Filter '*musl*.so*' -Recurse -ErrorAction Ignore | Select-Object -First 1)
    } else {
        $false
    }

    # Higher is better.
    # Sort the available assets in order of preference to choose an archive over an installer
    # If the extension is not in this list, we don't know how to handle it (for now)
    # TODO: Support for linux packages (deb, rpm, apk, etc)
    # TODO: Support for better archives (7z, etc)
    $assetExtension = ".zip", ".tgz", ".tar.gz", ".exe"
    $checksumExtension = ".sha", ".sha256", ".sha256sum", ".sha256sums", ".checksum", ".checksums", ".txt"
    $extension = $assetExtension + $checksumExtension
    $AllAssets = $assets |
        # I need both the Extension and the Priority on the final object for the logic below
        # I'll put the extension on, and then use that to calculate the priority
        # It would be faster (but ugly) to use a single Select-Object, but compared to downloading and unzipping, that's irrelevant
        Select-Object *, @{ Name = "Extension"; Expr = { $_.name -replace '^[^.]+$', '' -replace ".*?((?:\.tar)?\.[^.]+$)", '$1' } } |
        Select-Object *, @{ Name = "Priority"; Expr = {
                if (!$_.Extension -and $OS -notmatch "windows" ) {
                    if ($IsMusl) {
                        if ($name -match "musl") {
                            10
                        } else {
                            99
                        }
                    } else {
                        if ($name -match "musl") {
                            99
                        } else {
                            10
                        }
                    }
                } else {
                    $index = [array]::IndexOf($extension, $_.Extension)
                    if ($IsMusl) {
                        if ($name -match "musl") {
                            $index
                        } else {
                            $index + 10
                        }
                    } else {
                        if ($name -match "musl") {
                            $index + 10
                        } else {
                            $index
                        }
                    }
                }
            }
        } |
        Where-Object { $_.Priority -ge 0 } |
        Sort-Object Priority, { $_.Name.Length }, Name

    Write-Verbose "Found $($AllAssets.Count) (of $($assets.Count)) assets. Testing for $OS/$Architecture`n $($AllAssets| Format-Table name, b*url | Out-String)"

    $MatchedAssets = $AllAssets.where{ $_.name -match $OS -and $_.name -match $Architecture }
    Write-Verbose "Assets for $OS/$Architecture`n $($MatchedAssets| Format-Table name, Extension, b*url | Out-String)"

    if ($MatchedAssets.Count -eq 1) {
        $asset = $MatchedAssets[0]
    } elseif ($MatchedAssets.Count -gt 1) {
        # The patterns are expected to be | separated and in order of preference
        :top foreach ($o in $OS -split '\|') {
            foreach ($a in $Architecture -split '\|') {
                # Now that we're looking in order of preference, we can just stop when we find a match
                if ($asset = $AllAssets.Where({ $_.name -match $o -and $_.name -match $a -and ((-not $_.Extension -and $OS -notmatch "windows") -or $_.Extension -in $assetExtension) }, "First", 1)) {
                    Write-Verbose "Selected $($asset.name) for $o|$a"

                    # Check for a match-specific checksum file
                    if ($checksum = $AllAssets.Where({ $_.name -match $o -and $_.name -match $a -and ((-not $_.Extension -and $OS -notmatch "windows") -or $_.Extension -in $checksumExtension) }, "First", 1)) {
                        $asset | Add-Member -NotePropertyMember @{ ChecksumUrl = $checksum.browser_download_url }
                    }
                    break top
                } else {
                    Write-Verbose "No match for $o|$a"
                }
            }
        }

    } else {
        throw "No asset found for $OS/$Architecture`n $($AllAssets.name -join "`n")"
    }

    # Check for a single checksum file for all assets
    if (!$checksum) {
        $checksum = $assets.Where({ $_.name -match "checksum|sha256sums|sha" }, "First")
        Write-Verbose "Found checksum file $($checksum.browser_download_url) for $($asset.name)"
        # Add that url to the asset object
        $asset | Add-Member -NotePropertyMember @{ ChecksumUrl = $checksum.browser_download_url } -Force
    }
    $asset
}
