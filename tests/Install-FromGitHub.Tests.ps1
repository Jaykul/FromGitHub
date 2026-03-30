Describe "Install-GitHubRelease" {
    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'Install-FromGitHub' }
    }

    Context "Simple Install Flow" {
        BeforeAll {
            # To make the test controlled, force it to pretend it's on Windows
            Mock GetOSPlatform { 'windows|(?<!dar)win' } -ModuleName FromGitHub
            Mock GetOSArchitecture { 'amd64|x64|x86_64' } -ModuleName FromGitHub

            # First we go find the release on Github
            Mock GetGitHubRelease {
                [PSCustomObject]@{
                    org      = 'org'
                    repo     = 'repo'
                    tag_name = 'v1.0.0'
                    assets   = @(
                        [PSCustomObject]@{
                            Name                 = 'app_v1.0.0_windows_amd64.zip'
                            browser_download_url = 'https://example.invalid/gh.zip'
                        }
                    )
                }
            } -ModuleName FromGitHub

            # Then we select the right asset for our platform
            # Then we download it and extract it
            Mock GetAsset {
                New-Item -ItemType Directory -Path 'repo' -Force | Convert-Path
                "" > 'repo/app_v1.0.0_windows_amd64.exe'
            } -ModuleName FromGitHub

            # Then we move it to the BinDir
        }
        It "Installs the executable to the specified BinDir" {

            $result = & $CommandUnderTest -Org cli -Repo cli -BinDir $TestDrive/bin -Force

            $result.Name | Should -Be 'app.exe'

            Assert-MockCalled GetGitHubRelease -ModuleName FromGitHub
            Assert-MockCalled GetAsset -ModuleName FromGitHub

            # The executable should end up in BinDir
            Join-Path $TestDrive 'bin/app.exe' | Should -Exist
        }
    }
}
