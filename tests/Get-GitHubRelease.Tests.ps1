Describe GetGitHubRelease {

    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'GetGitHubRelease' }
        Mock Invoke-RestMethod {
            [PSCustomObject]@{
                Tag = Split-Path -Leaf $uri.LocalPath
            }
        } -ModuleName FromGitHub
    }

    It "Converts -Org test -Repo project to https://api.github.com/repos/test/project/latest" {
        $result = & $CommandUnderTest -Org test -Repo project
        $result.Tag | Should -Be "latest"
        $result.Org | Should -Be "test"
        $result.Repo | Should -Be "project"

        Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $uri | Should -Be "https://api.github.com/repos/test/project/releases/latest"
            $true
        } -ModuleName FromGitHub
    }

    It "Converts -Org test -Repo project -Tag v1 to https://api.github.com/repos/test/project/releases/tags/v1" {
        $result = & $CommandUnderTest -Org test -Repo project -Tag v1
        $result.Tag | Should -Be "v1"
        $result.Org | Should -Be "test"
        $result.Repo | Should -Be "project"
        Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $uri | Should -Be "https://api.github.com/repos/test/project/releases/tags/v1"
            $true
        } -ModuleName FromGitHub
    }

    It "Converts -Org test/project to https://api.github.com/repos/test/project/latest" {
        $null = & $CommandUnderTest test/project
        Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $uri | Should -Be "https://api.github.com/repos/test/project/releases/latest"
            $true
        } -ModuleName FromGitHub
    }

    It "Converts -Org test/project/v1 to https://api.github.com/repos/test/project/tags/v1" {
        $result = & $CommandUnderTest test/project/v1
        $result.Tag | Should -Be "v1"
        Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $uri | Should -Be "https://api.github.com/repos/test/project/releases/tags/v1"
            $true
        } -ModuleName FromGitHub
    }

    It "Converts https://github.com/fluxcd/flux2 to https://api.github.com/repos/fluxcd/flux2/releases/latest" {
        $result = & $CommandUnderTest https://github.com/fluxcd/flux2
        $result.Tag | Should -Be "latest"
        $result.Org | Should -Be "fluxcd"
        $result.Repo | Should -Be "flux2"
        Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $uri | Should -Be "https://api.github.com/repos/fluxcd/flux2/releases/latest"
            $true
        } -ModuleName FromGitHub
    }

    It "Converts https://github.com/fluxcd/flux2/releases/tag/v2.5.0 to https://api.github.com/repos/fluxcd/flux2/releases/tags/v2.5.0" {
        $result = & $CommandUnderTest https://github.com/fluxcd/flux2/releases/tag/v2.5.0
        $result.Tag | Should -Be "v2.5.0"
        Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $uri | Should -Be "https://api.github.com/repos/fluxcd/flux2/releases/tags/v2.5.0"
            $true
        } -ModuleName FromGitHub
    }

    Context "Warns when" {
        It "The Repo is ignored because of a / separated string" {
            $result = & { [CmdletBinding()]param()
                InModuleScope -ModuleName 'FromGitHub' {
                    $WarningPreference = 'SilentlyContinue'
                    GetGitHubRelease test/project v2
                }
            } -WarningVariable warnings

            $result.Tag | Should -Be "v2"

            Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                $uri | Should -Be "https://api.github.com/repos/test/project/releases/tags/v2"
                $true
            } -ModuleName FromGitHub

            $warnings | Should -BeLike "Repo is ignored when passing a / separated string for Org"
        }

        It "The Repo is ignored when passing a project URL" {
            $null = & { [CmdletBinding()]param()
                InModuleScope -ModuleName 'FromGitHub' {
                    $WarningPreference = 'SilentlyContinue'
                    GetGitHubRelease https://github.com/fluxcd/flux2 v4
                }
            } -WarningVariable warnings

            Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                $uri | Should -Be "https://api.github.com/repos/fluxcd/flux2/releases/tags/v4"
                $true
            } -ModuleName FromGitHub

            $warnings | Should -BeLike "Repo is ignored when passing a project URL"
        }
    }
}
