$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 4
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Resolve-DbaNetworkName).Parameters.Keys
        $knownParameters = 'ComputerName', 'Credential', 'Turbo', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
    Context "Testing basic name resolution" {
        It "should test env:computername" {
            $result = Resolve-DbaNetworkName $env:computername -EnableException
            $result.InputName | Should -Be $env:computername
            $result.ComputerName | Should -Be $env:computername
            $result.IPAddress | Should -Not -BeNullOrEmpty
            $result.DNSHostName | Should -Be $env:computername
            if ($result.DNSDomain) {
                $result.FullComputerName | Should -Be ($result.ComputerName + "." + $result.DNSDomain)
            }
        }
        It "should test localhost" {
            $result = Resolve-DbaNetworkName localhost -EnableException
            $result.InputName | Should -Be localhost
            $result.ComputerName | Should -Be $env:computername
            $result.IPAddress | Should -Not -BeNullOrEmpty
            $result.DNSHostName | Should -Be $env:computername
            if ($result.DNSDomain) {
                $result.FullComputerName | Should -Be ($result.ComputerName + "." + $result.DNSDomain)
            }
        }
        It "should test 127.0.0.1" {
            $result = Resolve-DbaNetworkName 127.0.0.1 -EnableException
            $result.InputName | Should -Be 127.0.0.1
            $result.ComputerName | Should -Be $env:computername
            $result.IPAddress | Should -Not -BeNullOrEmpty
            $result.DNSHostName | Should -Be $env:computername
            if ($result.DNSDomain) {
                $result.FullComputerName | Should -Be ($result.ComputerName + "." + $result.DNSDomain)
            }
        }
        foreach ($turbo in $true, $false) {
            It "should test 8.8.8.8 with Turbo = $turbo" {
                $result = Resolve-DbaNetworkName 8.8.8.8 -EnableException -Turbo:$turbo
                $result.InputName | Should -Be 8.8.8.8
                $result.ComputerName | Should -Be google-public-dns-a
                $result.IPAddress | Should -Be 8.8.8.8
                $result.DNSHostName | Should -Be google-public-dns-a
                $result.DNSDomain | Should -Be google.com
                $result.Domain | Should -Be google.com
                $result.DNSHostEntry | Should -Be google-public-dns-a.google.com
                $result.FQDN | Should -Be google-public-dns-a.google.com
                $result.FullComputerName | Should -Be google-public-dns-a.google.com
            }
        }
    }
}
<#
    Integration test should appear below and are custom to the command you are writing.
    Read https://github.com/sqlcollaborative/dbatools/blob/development/contributing.md#tests
    for more guidence.
#>