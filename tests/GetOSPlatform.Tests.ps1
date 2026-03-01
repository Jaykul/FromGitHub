Describe "GetOSPlatform" {
    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'GetOSPlatform' }
    }

    Context "When Pattern switch is not specified" {
        It "Returns 'windows' when running on Windows" {
            $result = & $CommandUnderTest -IsOsPlatform {
                "WINDOWS" -eq $args[0]
            }
            $result | Should -Be "windows"
        }
        It "Returns 'linux' when running on Linux" {
            $result = & $CommandUnderTest -IsOsPlatform {
                "LINUX" -eq $args[0]
            }
            $result | Should -Be "linux"
        }
        It "Returns 'darwin' when running on macOS" {
            $result = & $CommandUnderTest -IsOsPlatform {
                "OSX" -eq $args[0]
            }
            $result | Should -Be "darwin"
        }
        It "Returns 'freebsd' when running on FreeBSD" {
            $result = & $CommandUnderTest -IsOsPlatform {
                "FREEBSD" -eq $args[0]
            }
            $result | Should -Be "freebsd"
        }

        It "Returns 'windows' on Windows systems" {
            # This will pass on Windows, skip on others
            if ($IsWindows -or (-not $IsLinux -and -not $IsMacOS)) {
                $result = & $CommandUnderTest
                $result | Should -Be "windows"
            } else {
                Set-ItResult -Skipped -Because "Not running on Windows"
            }
        }

        It "Returns 'linux' on Linux systems" {
            if ($IsLinux) {
                $result = & $CommandUnderTest
                $result | Should -Be "linux"
            } else {
                Set-ItResult -Skipped -Because "Not running on Linux"
            }
        }

        It "Returns 'darwin' on macOS systems" {
            if ($IsMacOS) {
                $result = & $CommandUnderTest
                $result | Should -Be "darwin"
            } else {
                Set-ItResult -Skipped -Because "Not running on macOS"
            }
        }
    }

    Context "When Pattern switch is specified" {
        It "Returns regex pattern for win|windows that doesn't match 'darwin'" {
            # Windows pattern should match windows variants
            & $CommandUnderTest -Pattern -IsOsPlatform {
                "WINDOWS" -eq $args[0]
            } | Should -Be "windows|(?<!dar)win"
        }

        It "Returns regex pattern for linux" {
            # Linux pattern should match unix variants
            $result = & $CommandUnderTest -Pattern -IsOsPlatform {
                "LINUX" -eq $args[0]
            } | Should -Match "linux|unix"
        }

        It "Returns regex pattern for darwin" {
            # Darwin pattern should match osx variants
            $result = & $CommandUnderTest -Pattern -IsOsPlatform {
                "OSX" -eq $args[0]
            } | Should -Match "darwin|osx"
        }

        It "Returns freebsd for freebsd" {
            # FreeBSD pattern should match freebsd variants
            $result = & $CommandUnderTest -Pattern -IsOsPlatform {
                "FREEBSD" -eq $args[0]
            } | Should -Match "freebsd"
        }
    }

    Context "Error handling" {
        It "Throws on unsupported platforms" {
            {
                & $CommandUnderTest -IsOsPlatform {
                    "UNSUPPORTED" -eq $args[0]
                }
            } | Should -Throw "unsupported platform"
        }
    }
}
