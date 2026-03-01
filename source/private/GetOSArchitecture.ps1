function GetOSArchitecture {
    [CmdletBinding()]
    param(
        # If set, returns a regex pattern (based on the OS) that usually matches the architecture in asset names
        [switch]$Pattern,
        # A mock override exposed for testing only -- API only available in PS6+
        [string]$OSArchitecture = ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture),
        # A mock override exposed for testing only
        [bool]$Is64Bit = ([Environment]::Is64BitOperatingSystem)
    )

    # PowerShell Core
    $Architecture = if ($OSArchitecture) {
        $OSArchitecture
        # Legacy Windows PowerShell
    } elseif ($Is64Bit) {
        "X64";
    } else {
        "X86";
    }

    # Optionally, turn this into a regex pattern that usually works
    if ($Pattern) {
        Write-Information $Architecture
        switch ($Architecture) {
            "Arm" { "arm(?!64)" }
            "Arm64" { "arm64" }
            "X86" { "x86|386" }
            "X64" { "amd64|x64|x86_64" }
        }
    } else {
        $Architecture
    }
}
