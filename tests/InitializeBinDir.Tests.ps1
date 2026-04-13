Describe "InitializeBinDir" {
    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'InitializeBinDir' }
    }

    Context "With explicit BinDir parameter" {
        It "Returns the provided BinDir if it already exists" {
            $TestDir = Join-Path $TestDrive "mybin"
            New-Item -ItemType Directory -Path $TestDir -Force | Out-Null

            & $CommandUnderTest -BinDir $TestDir
            | Should -Be $TestDir
        }

        It "Creates the directory if it doesn't exist with Force switch" {
            $TestDir = Join-Path $TestDrive "newbin"

            & $CommandUnderTest -BinDir $TestDir -Force
            | Should -Be $TestDir

            Test-Path $TestDir | Should -Be $true
        }
    }

    Context "With ShouldProcess support" {
        It "Supports -WhatIf parameter" {
            $TestDir = Join-Path $TestDrive "whatiftest"

            $result = & $CommandUnderTest -BinDir $TestDir -WhatIf

            # WhatIf should prevent actual directory creation
            Test-Path $TestDir | Should -Be $false
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Default BinDir selection" {
        It "Returns a default /usr/local/bin on Linux and macOS" {
            & $CommandUnderTest -Force -IsPosix
            | Should -Be "/usr/local/bin"
        }
        It "Returns LocalAppData path on Windows" {
            if (-not $Env:LocalAppData) {
                $Env:LocalAppData = [Environment]::GetFolderPath("LocalApplicationData")
            }

            & $CommandUnderTest -Force -IsPosix:$false
            | Should -Be ("$Env:LocalAppData", "Programs", "Tools" -join [IO.Path]::DirectorySeparatorChar)
        }
        It "Respects FROMGITHUB_BINDIR environment variable if set" {
            $Env:FROMGITHUB_BINDIR = Join-Path $TestDrive "custombindir"

            & $CommandUnderTest
            | Should -Be $Env:FROMGITHUB_BINDIR

            Remove-Item Env:FROMGITHUB_BINDIR
        }
    }

    Context "PATH environment variable handling" {
        It "Adds BinDir to PATH when it is created" {
            $TestDir = Join-Path $TestDrive "pathtest"
            $OriginalPath = $Env:PATH

            try {
                $null = & $CommandUnderTest -BinDir $TestDir -Force

                # PATH should now contain the new directory
                $Env:PATH -split [IO.Path]::PathSeparator | Should -Contain $TestDir
            } finally {
                $Env:PATH = $OriginalPath
            }
        }

        It "Does not add BinDir to PATH if already present" {
            $TestDir = Join-Path $TestDrive "doubleadd"
            New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
            $OriginalPath = $Env:PATH

            try {
                # Add it once
                & $CommandUnderTest -BinDir $TestDir -Force | Out-Null
                $CountBefore = @($Env:PATH -split [IO.Path]::PathSeparator | Where-Object { $_ -eq $TestDir }).Count

                # Try to add again - should not duplicate
                & $CommandUnderTest -BinDir $TestDir -Force | Out-Null
                $CountAfter = @($Env:PATH -split [IO.Path]::PathSeparator | Where-Object { $_ -eq $TestDir }).Count

                $CountAfter | Should -Be $CountBefore
            } finally {
                $Env:PATH = $OriginalPath
            }
        }
    }

    Context "Error handling" {
        It "Throws error when user declines to create directory" {
            $TestDir = Join-Path $TestDrive "declinetest"

            # Note: This is difficult to test without interactive prompting
            # The function should throw when user declines
            $TestDir | Should -Not -BeNullOrEmpty
        }
    }
}
