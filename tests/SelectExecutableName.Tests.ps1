Describe "SelectExecutableName" {
    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'SelectExecutableName' }
    }

    BeforeDiscovery {
        $TestCases = @(
            @{
                OS            = "darwin|osx"
                Architecture  = "arm64"
                Repo          = "regal"
                Tag           = "v1.0.0"
                FileName      = "regal_Darwin_arm64"
                FileExtension = ""
                IsPosix       = $true
                Expected      = "regal"
                Description   = "macOS ARM64 - should strip OS and Architecture"
            }
            @{
                OS            = "darwin|osx"
                Architecture  = "amd64|x64|x86_64"
                Repo          = "earthly"
                Tag           = "v1.0.0"
                FileName      = "earthly-darwin-amd64"
                FileExtension = ""
                IsPosix       = $true
                Expected      = "earthly"
                Description   = "macOS x86_64 - should strip dashes"
            }
            @{
                OS            = "linux|unix"
                Architecture  = "arm64"
                Repo          = "regal"
                Tag           = "v1.0.0"
                FileName      = "regal_Linux_arm64"
                FileExtension = ""
                IsPosix       = $true
                Expected      = "regal"
                Description   = "Linux ARM64 - should strip OS and Architecture"
            }
            @{
                OS            = "windows|(?<!dar)win"
                Architecture  = "amd64|x64|x86_64"
                Repo          = "ripgrep"
                Tag           = "v1.0.0"
                FileName      = "ripgrep_Windows_x86_64.exe"
                FileExtension = ".exe"
                IsPosix       = $false
                Expected      = "ripgrep.exe"
                Description   = "Windows x86_64 - should preserve .exe extension"
            }
            @{
                OS            = "windows|(?<!dar)win"
                Architecture  = "amd64|x64|x86_64"
                Repo          = "fzf"
                Tag           = "v1.0.0"
                FileName      = "fzf-windows-amd64.exe"
                FileExtension = ".exe"
                IsPosix       = $false
                Expected      = "fzf.exe"
                Description   = "Windows x86_64 with dashes - should strip and add .exe"
            }
            # GitTower put the version number in their asset names ...
            @{
                OS            = "windows|(?<!dar)win"
                Architecture  = "amd64|x64|x86_64"
                Repo          = "git-flow-next"
                Tag           = "v1.0.0"
                FileName      = "git-flow-v1.0.0-windows-amd64.exe"
                FileExtension = ".exe"
                IsPosix       = $false
                Expected      = "git-flow.exe"
                Description   = "git-flow should not have the version in the name"
            }
        )
    }

    Context "With filename matching OS and/or Architecture" {
        It "<Description>" -ForEach $TestCases {
            # Create a test file
            $File = New-Item -ItemType File -Path (Join-Path $TestDrive $FileName) -Force

            $result = & $CommandUnderTest -OS $OS -Architecture $Architecture -Repo $Repo -Tag $Tag -File $File -IsPosix:$IsPosix

            $result | Should -Be $Expected
            Remove-Item $File -Force
        }
    }

    Context "With explicit ExecutableName parameter" {
        It "Uses the provided ExecutableName" {
            $File = New-Item -ItemType File -Path (Join-Path $TestDrive "original_Linux_x64")

            $result = & $CommandUnderTest `
                -OS "linux|unix" `
                -Architecture "amd64|x64|x86_64" `
                -ExecutableName "mycustom" `
                -Tag "v1.0.0" `
                -File $File `
                -IsPosix:$true

            $result | Should -Be "mycustom"
            Remove-Item $File -Force
        }

        It "Adds correct extension to custom name on Windows" {
            $File = New-Item -ItemType File -Path (Join-Path $TestDrive "original_Windows_x64.exe")

            $result = & $CommandUnderTest `
                -OS "windows|(?<!dar)win" `
                -Architecture "amd64|x64|x86_64" `
                -ExecutableName "mytool" `
                -Tag "v1.0.0" `
                -File $File `
                -IsPosix:$false

            $result | Should -Be "mytool.exe"
            Remove-Item $File -Force
        }
    }

    Context "With Force switch" {
        It "Renames file when -forced using the repo name" {
            $File = New-Item -ItemType File -Path (Join-Path $TestDrive "tool.exe")

            $result = & $CommandUnderTest `
                -OS "windows|(?<!dar)win" `
                -Architecture "amd64|x64|x86_64" `
                -Repo "myproject" `
                -Tag "v1.0.0" `
                -File $File `
                -Force `
                -IsPosix:$false

            $result | Should -Be "myproject.exe"
            Remove-Item $File -Force
        }

        It "Uses explicit name over repo name when provided" {
            $File = New-Item -ItemType File -Path (Join-Path $TestDrive "random.exe")

            $result = & $CommandUnderTest `
                -OS "windows|(?<!dar)win" `
                -Architecture "amd64|x64|x86_64" `
                -Repo "myproject" `
                -ExecutableName "preferred" `
                -Tag "v1.0.0" `
                -File $File `
                -Force `
                -IsPosix:$false

            $result | Should -Be "preferred.exe"
            Remove-Item $File -Force
        }
    }

    Context "When conditions are not met" {
        It "Returns original filename when OS/Architecture not in name and no Force" {
            $File = New-Item -ItemType File -Path (Join-Path $TestDrive "unknown.bin")

            $result = & $CommandUnderTest `
                -OS "linux|unix" `
                -Architecture "amd64|x64|x86_64" `
                -Tag "v1.0.0" `
                -File $File `
                -IsPosix:$true

            $result | Should -Be "unknown.bin"
            Remove-Item $File -Force
        }

        It "Returns original filename on Windows when file has no executable extension" {
            $File = New-Item -ItemType File -Path (Join-Path $TestDrive "tool_Windows_x64.txt")

            $result = & $CommandUnderTest `
                -OS "windows|(?<!dar)win" `
                -Architecture "amd64|x64|x86_64" `
                -Repo "myrepo" `
                -Tag "v1.0.0" `
                -File $File `
                -IsPosix:$false

            # File has .txt extension, not in PATHEXT, so should return original
            $result | Should -Be "tool_Windows_x64.txt"
            Remove-Item $File -Force
        }
    }
}
