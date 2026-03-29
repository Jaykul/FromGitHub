Describe GetAsset {
    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'GetAsset' }
    }

    It "Downloads, validates, and expands zip assets" {
        $asset = [PSCustomObject]@{
            Name = 'gh_2.0.0_windows_amd64.zip'
            browser_download_url = 'https://example.invalid/gh.zip'
            Extension = '.zip'
            ChecksumUrl = 'https://example.invalid/gh.zip.sha256'
        }
        "" > (Join-Path $TestDrive $asset.Name)

        Mock Invoke-WebRequest {} -ModuleName FromGitHub
        Mock Test-FileHash { $true } -ModuleName FromGitHub
        Mock Microsoft.PowerShell.Archive\Expand-Archive {} -ModuleName FromGitHub

        Push-Location $TestDrive
        try {
            $result = & $CommandUnderTest -Asset $asset -Repo Something
        } finally {
            Pop-Location
        }

        $result | Should -Be (Join-Path $TestDrive 'Something')

        Assert-MockCalled Invoke-WebRequest -Exactly 1 -ModuleName FromGitHub -ParameterFilter {
            $Uri -eq 'https://example.invalid/gh.zip' -and $OutFile -eq 'gh_2.0.0_windows_amd64.zip'
        }
        Assert-MockCalled Test-FileHash -Exactly 1 -ModuleName FromGitHub -ParameterFilter {
            $Target -eq 'gh_2.0.0_windows_amd64.zip' -and $Checksum -eq 'https://example.invalid/gh.zip.sha256'
        }
        Assert-MockCalled Microsoft.PowerShell.Archive\Expand-Archive -Exactly 1 -ModuleName FromGitHub
    }

    It "Returns the current directory for executable assets and warns when no checksum is available" {
        $asset = [PSCustomObject]@{
            Name = 'gh.exe'
            browser_download_url = 'https://example.invalid/gh.exe'
            Extension = '.exe'
        }

        Mock Invoke-WebRequest {} -ModuleName FromGitHub
        Mock Test-FileHash {} -ModuleName FromGitHub

        Push-Location $TestDrive
        try {
            $result = & $CommandUnderTest -Asset $asset -WarningVariable warnings
        } finally {
            Pop-Location
        }

        $result | Should -Be $TestDrive
        $warnings | Should -Match 'No checksum file found'

        Assert-MockCalled Invoke-WebRequest -Exactly 1 -ModuleName FromGitHub
        Assert-MockCalled Test-FileHash -Exactly 0 -ModuleName FromGitHub
    }

    It "Throws when checksum validation fails" {
        $asset = [PSCustomObject]@{
            Name = 'gh.zip'
            browser_download_url = 'https://example.invalid/gh.zip'
            Extension = '.zip'
            ChecksumUrl = 'https://example.invalid/gh.zip.sha256'
        }

        Mock Invoke-WebRequest {} -ModuleName FromGitHub
        Mock Test-FileHash { $false } -ModuleName FromGitHub

        Push-Location $TestDrive
        try {
            { & $CommandUnderTest -Asset $asset -Repo gh } | Should -Throw '*Checksum mismatch*'
        } finally {
            Pop-Location
        }
    }
}
