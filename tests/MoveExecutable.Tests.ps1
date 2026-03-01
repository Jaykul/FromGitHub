Describe MoveExecutable {
    BeforeDiscovery {
        $TestCases = @(
            @{ OS = "darwin|osx"; Architecture = "arm64"; Repo = "regal"; Binary = "regal_Darwin_arm64"; FileName = "regal"; IsPosix = $true }
            @{ OS = "darwin|osx"; Architecture = "amd64|x64|x86_64"; Repo = "regal"; Binary = "regal_Darwin_x86_64"; FileName = "regal"; IsPosix = $true }
            @{ OS = "linux|unix"; Architecture = "arm64"; Repo = "regal"; Binary = "regal_Linux_arm64"; FileName = "regal"; IsPosix = $true }
            @{ OS = "linux|unix"; Architecture = "amd64|x64|x86_64"; Repo = "regal"; Binary = "regal_Linux_x86_64"; FileName = "regal"; IsPosix = $true }
            @{ OS = "windows|(?<!dar)win"; Architecture = "amd64|x64|x86_64"; Repo = "regal"; Binary = "regal_Windows_x86_64.exe"; FileName = "regal.exe"; IsPosix = $false }

            @{ OS = "darwin|osx"; Architecture = "arm64"; Repo = "earthly"; Binary = "earthly-darwin-arm64"; FileName = "earthly"; IsPosix = $true }
            @{ OS = "darwin|osx"; Architecture = "amd64|x64|x86_64"; Repo = "earthly"; Binary = "earthly-darwin-amd64"; FileName = "earthly"; IsPosix = $true }
            @{ OS = "linux|unix"; Architecture = "arm64"; Repo = "earthly"; Binary = "earthly-linux-arm64"; FileName = "earthly"; IsPosix = $true }
            @{ OS = "linux|unix"; Architecture = "amd64|x64|x86_64"; Repo = "earthly"; Binary = "earthly-linux-amd64"; FileName = "earthly"; IsPosix = $true }
            @{ OS = "windows|(?<!dar)win"; Architecture = "amd64|x64|x86_64"; Repo = "earthly"; Binary = "earthly-windows-amd64.exe"; FileName = "earthly.exe"; IsPosix = $false }
        )
    }

    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'MoveExecutable' }
        $FromDir = Join-Path $TestDrive "Unpacked"
        $ToDir = Join-Path $TestDrive "Target"
        New-Item $FromDir -ItemType Directory -Force | Out-Null
        New-Item $ToDir -ItemType Directory -Force | Out-Null
    }

    It "Moves the executable to the correct directory" -ForEach $TestCases {
        # Make up the file that needs renaming
        New-Item (Join-Path $FromDir "$Binary") -ItemType File -Force | Out-Null

        function global:chmod {
        }

        &$CommandUnderTest -FromDir $FromDir -ToDir $ToDir -OS $OS -Architecture $Architecture -Repo $Repo -IsPosix:$IsPosix
        | Assert-All { $_.Name -eq $FileName }
    }
}
