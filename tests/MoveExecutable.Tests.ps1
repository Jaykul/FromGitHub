Describe MoveExecutable {
    BeforeDiscovery {
        $TestCases = @(
            @{ OS = "darwin|osx"; Architecture = "arm64"; Repo = "regal"; Tag = "v1.0.0"; Binary = "regal_Darwin_arm64"; FileName = "regal"; IsPosix = $true }
            @{ OS = "darwin|osx"; Architecture = "amd64|x64|x86_64"; Repo = "regal"; Tag = "v1.0.0"; Binary = "regal_Darwin_x86_64"; FileName = "regal"; IsPosix = $true }
            @{ OS = "linux|unix"; Architecture = "arm64"; Repo = "regal"; Tag = "v1.0.0"; Binary = "regal_Linux_arm64"; FileName = "regal"; IsPosix = $true }
            @{ OS = "linux|unix"; Architecture = "amd64|x64|x86_64"; Repo = "regal"; Tag = "v1.0.0"; Binary = "regal_Linux_x86_64"; FileName = "regal"; IsPosix = $true }
            @{ OS = "windows|(?<!dar)win"; Architecture = "amd64|x64|x86_64"; Repo = "regal"; Tag = "v1.0.0"; Binary = "regal_Windows_x86_64.exe"; FileName = "regal.exe"; IsPosix = $false }

            @{ OS = "darwin|osx"; Architecture = "arm64"; Repo = "earthly"; Tag = "v1.0.0"; Binary = "earthly-darwin-arm64"; FileName = "earthly"; IsPosix = $true }
            @{ OS = "darwin|osx"; Architecture = "amd64|x64|x86_64"; Repo = "earthly"; Tag = "v1.0.0"; Binary = "earthly-darwin-amd64"; FileName = "earthly"; IsPosix = $true }
            @{ OS = "linux|unix"; Architecture = "arm64"; Repo = "earthly"; Tag = "v1.0.0"; Binary = "earthly-linux-arm64"; FileName = "earthly"; IsPosix = $true }
            @{ OS = "linux|unix"; Architecture = "amd64|x64|x86_64"; Repo = "earthly"; Tag = "v1.0.0"; Binary = "earthly-linux-amd64"; FileName = "earthly"; IsPosix = $true }
            @{ OS = "windows|(?<!dar)win"; Architecture = "amd64|x64|x86_64"; Repo = "earthly"; Tag = "v1.0.0"; Binary = "earthly-windows-amd64.exe"; FileName = "earthly.exe"; IsPosix = $false }
            @{ OS = "windows|(?<!dar)win"; Architecture = "amd64|x64|x86_64"; Repo = "git-flow-next"; Tag = "v1.0.0"; Binary = "git-flow-v1.0.0-windows-amd64.exe"; FileName = "git-flow.exe"; IsPosix = $false }
        )
    }

    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'MoveExecutable' }
        $AssetDir = Join-Path $TestDrive "Unpacked"
        $BinDir = Join-Path $TestDrive "Target"
        New-Item $AssetDir -ItemType Directory -Force | Out-Null
        New-Item $BinDir -ItemType Directory -Force | Out-Null
    }

    It "Moves the executable to the correct directory" -ForEach $TestCases {
        # Make up the file that needs renaming
        New-Item (Join-Path $AssetDir "$Binary") -ItemType File -Force | Out-Null

        function global:chmod {
        }

        &$CommandUnderTest -AssetDir $AssetDir -BinDir $BinDir -OS $OS -Architecture $Architecture -Repo $Repo -Tag $Tag -IsPosix:$IsPosix -WarningAction SilentlyContinue
        | Assert-All { $_.Name -eq $FileName }
    }
}
