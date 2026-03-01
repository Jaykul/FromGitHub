function GetOSPlatform {
    [CmdletBinding()]
    param(
        # If set, returns a regex pattern (based on the OS) that usually matches the OS in asset names
        [switch]$Pattern,
        # A mock override exposed for testing only
        [scriptblock]$IsOsPlatform = {
            [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform( $args[0] )
        }
    )
    $platform = [System.Runtime.InteropServices.OSPlatform]
    # if $ri isn't defined, then we must be running in Powershell 5.1, which only works on Windows.
    $OS = if (& $IsOsPlatform $platform::Windows) {
        "windows"
    } elseif (& $IsOsPlatform $platform::Linux) {
        "linux"
    } elseif (& $IsOsPlatform $platform::OSX) {
        "darwin"
    } elseif (& $IsOsPlatform $platform::FreeBSD) {
        "freebsd"
    } else {
        throw "unsupported platform"
    }
    if ($Pattern) {
        Write-Information $OS
        switch ($OS) {
            "windows" { "windows|(?<!dar)win" }
            "linux" { "linux|unix" }
            "darwin" { "darwin|osx" }
            "freebsd" { "freebsd" }
        }
    } else {
        $OS
    }
}
