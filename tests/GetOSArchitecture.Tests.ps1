Describe "GetOSArchitecture" {
    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'GetOSArchitecture' }
    }

    Context "When Pattern switch is not specified" {
        It "Returns the architecture string (not a pattern)" {
            & $CommandUnderTest -OSArchitecture "Arm64" -Is64Bit $true
            | Should -Be "Arm64"
        }

        It "Works with X64 architecture" {
            & $CommandUnderTest -OSArchitecture "X64" -Is64Bit $true
            | Should -Be "X64"
        }

        It "Handles Legacy Windows PowerShell via Is64Bit" {
            & $CommandUnderTest -OSArchitecture $null -Is64Bit $true
            | Should -Be "X64"
        }

        It "Hypothetically could handle 32Bit Windows" {
            & $CommandUnderTest -OSArchitecture $null -Is64Bit $false
            | Should -Be "X86"
        }
    }

    Context "When Pattern switch is specified" {
        It "Returns regex pattern for Arm64 architecture" {
            # Mock the architecture to be Arm64
            & $CommandUnderTest -Pattern -OSArchitecture "Arm64" -Is64Bit $true
            | Should -Be "arm64"
        }
        It "Returns regex pattern for (not 64bit) Arm architecture" {
            # Mock the architecture to be Arm
            & $CommandUnderTest -Pattern -OSArchitecture "Arm" -Is64Bit $false
            | Should -Be "arm(?!64)"
        }

        It "Returns regex pattern for X64 architecture" {
            # X64 pattern should match common variations
            & $CommandUnderTest -Pattern -OSArchitecture "X64" -Is64Bit $true
            | Should -Be "amd64|x64|x86_64"
        }

        It "Returns regex pattern for X86 architecture" {
            # X86 pattern should match variations
            & $CommandUnderTest -Pattern -OSArchitecture "X86" -Is64Bit $false
            | Should -Be "x86|386"
        }
    }
}
