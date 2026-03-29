Describe "Install-GitHubRelease" {
    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'Install-FromGitHub' }
    }

    It "Delegates download and extraction to GetAsset" {
        $asset = [PSCustomObject]@{
            Name                 = 'gh_2.0.0_windows_amd64.zip'
            browser_download_url = 'https://example.invalid/gh.zip'
            Extension            = '.zip'
        }

        Mock GetOSPlatform { 'windows|(?<!dar)win' } -ModuleName FromGitHub
        Mock GetOSArchitecture { 'amd64|x64|x86_64' } -ModuleName FromGitHub
        Mock GetGitHubRelease {
            [PSCustomObject]@{
                Org    = 'cli'
                Repo   = 'cli'
                Assets = @($asset)
            }
        } -ModuleName FromGitHub
        Mock SelectAssetByPlatform { $asset } -ModuleName FromGitHub
        Mock GetAsset { Join-Path $TestDrive 'unpacked' } -ModuleName FromGitHub
        Mock InitializeBinDir { Join-Path $TestDrive 'bin' } -ModuleName FromGitHub
        Mock MoveExecutable {
            param(
                $FromDir,
                $ToDir,
                [Parameter(ValueFromRemainingArguments)]
                $Extra
            )
            [PSCustomObject]@{ Name = 'gh.exe' }
        } -ModuleName FromGitHub
        Mock Invoke-WebRequest {} -ModuleName FromGitHub
        Mock Microsoft.PowerShell.Archive\Expand-Archive {} -ModuleName FromGitHub
        Mock Remove-Item {} -ModuleName FromGitHub

        $result = & $CommandUnderTest -Org cli -Repo cli -Force

        $result.Name | Should -Be 'gh.exe'

        Assert-MockCalled GetGitHubRelease -Exactly 1 -ModuleName FromGitHub
        Assert-MockCalled SelectAssetByPlatform -Exactly 1 -ModuleName FromGitHub -ParameterFilter {
            $assets.Count -eq 1 -and $assets[0].Name -eq 'gh_2.0.0_windows_amd64.zip'
        }
        Assert-MockCalled GetAsset -Exactly 1 -ModuleName FromGitHub -ParameterFilter {
            $Repo -eq 'cli' -and $Asset.Name -eq 'gh_2.0.0_windows_amd64.zip'
        }
        Assert-MockCalled InitializeBinDir -Exactly 1 -ModuleName FromGitHub
        Assert-MockCalled MoveExecutable -Exactly 1 -ModuleName FromGitHub -ParameterFilter {
            $FromDir -eq (Join-Path $TestDrive 'unpacked') -and $ToDir -eq (Join-Path $TestDrive 'bin')
        }

        # Downloading and archive extraction are now covered by GetAsset tests.
        Assert-MockCalled Invoke-WebRequest -Exactly 0 -ModuleName FromGitHub
        Assert-MockCalled Microsoft.PowerShell.Archive\Expand-Archive -Exactly 0 -ModuleName FromGitHub
    }
}
