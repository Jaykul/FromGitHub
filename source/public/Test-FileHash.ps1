function Test-FileHash {
    <#
        .SYNOPSIS
            Test the hash of a file against one or more checksum files or strings
        .DESCRIPTION
            Checksum files are assumed to have one line per file name, with the hash (or multiple hashes) on the line following the file name.

            In order to support installing yq (which has a checksum file with multiple hashes), this function handles checksum files with an ARRAY of valid checksums for each file name by searching the array for any matching hash.

            This isn't great, but an accidental pass is almost inconceivable, and determining the hash order is too complicated (given only one weird project does this so far).
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        # The path to the file to check the hash of
        [string]$Target,

        # The hash(es) or checksum(s) to compare to (can be one or more urls, files, or hash strings)
        [string[]]$Checksum
    )
    $basename = [Regex]::Escape([IO.Path]::GetFileName($Target))

    # Supports checksum files with an ARRAY of valid checksums (for different hash algorithms)
    $Checksum = @(
        foreach($check in $Checksum) {
            # If Checksum is a URL, fetch the checksum(s) from the URL
            if ($Check -match "https?://") {
                Write-Debug "Checksum is a URL: $Check"
                if($Env:GITHUB_TOKEN) {
                    Invoke-RestMethod $Check -Headers @{ Authorization = "Bearer $($Env:GITHUB_TOKEN)" }
                } else {
                    Invoke-RestMethod $Check
                }
            } elseif (Test-Path $Check) {
                Write-Debug "Checksum is a file: $Check"
                Get-Content $Check
            }
        }
    ) -match $basename -split "\s+|=" -notmatch $basename

    $Actual = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash

    # ... by searching the array for any matching hash (an accidental pass is almost inconceivable).
    [bool]($Checksum -eq $Actual)
    if ($Checksum -eq $Actual) {
        Write-Verbose "Checksum matches $Actual"
    } else {
        Write-Error "Checksum mismatch!`nValid: $Checksum`nActual: $Actual"
    }
}
