function InitializeBinDir {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The location to install to.
        # Defaults to $Env:LocalAppData\Programs\Tools on Windows, /usr/local/bin on Linux/MacOS
        # Passthrough from Install-FromGitHub
        [string]$BinDir,
        # Skip ShouldProcess confirmation
        [switch]$Force,
        # A mock override exposed for testing only
        [switch]$IsPosix = $IsLinux -or $IsMacOS
    )

    if (!$BinDir) {
        $BinDir = $(
            if ($Env:FROMGITHUB_BINDIR) {
                $Env:FROMGITHUB_BINDIR
            } elseif ($IsPosix) {
                '/usr/local/bin'
            } elseif ($Env:LocalAppData) {
                "$Env:LocalAppData", "Programs", "Tools" -join [IO.Path]::DirectorySeparatorChar
            } else {
                "$HOME/.tools"
            }
        )
    }

    if (!(Test-Path $BinDir)) {
        # First time use of $BinDir
        if ($Force -or $PSCmdlet.ShouldProcess($BinDir, "create directory and add to PATH")) {
            New-Item -Type Directory -Path $BinDir | Out-Null
            if ($Env:PATH -split [IO.Path]::PathSeparator -notcontains $BinDir) {
                $Env:PATH += [IO.Path]::PathSeparator + $BinDir

                # If it's *not* Windows, $BinDir would be /usr/local/bin or something already in your PATH
                if (!$IsLinux -and !$IsMacOS) {
                    # But if it is Windows, we need to make the PATH change permanent
                    $PATH = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
                    $PATH += [IO.Path]::PathSeparator + $BinDir
                    [Environment]::SetEnvironmentVariable("PATH", $PATH, [EnvironmentVariableTarget]::User)
                }
            }
        }
        # else {
        #     throw "Cannot install $Repo to $BinDir"
        # }
    }
    $BinDir
}
