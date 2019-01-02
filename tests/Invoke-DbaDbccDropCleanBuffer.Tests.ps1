$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command -Name $CommandName).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'NoInformationalMessages', 'EnableException'

        It "Should contain our specific parameters" {
            ((Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count) | Should Be $knownParameters.Count
        }
    }
}
Describe "$commandname Integration Test" -Tag "IntegrationTests" {
    $props = 'ComputerName', 'InstanceName', 'SqlInstance', 'Cmd', 'Output'
    $result = Invoke-DbaDbccDropCleanBuffer -SqlInstance $script:instance1 -Confirm:$false

    Context "Validate standard output" {
        foreach ($prop in $props) {
            $p = $result.PSObject.Properties[$prop]
            It "Should return property: $prop" {
                $p.Name | Should Be $prop
            }
        }
    }

    Context "Works correctly" {
        It "returns results" {
            $result.Output -match 'DBCC execution completed. If DBCC printed error messages, contact your system administrator.' | Should Be $true
        }

        It "returns the right results for -NoInformationalMessages" {
            $result = Invoke-DbaDbccDropCleanBuffer -SqlInstance $script:instance1 -NoInformationalMessages -Confirm:$false
            $result.Cmd -match 'DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS' | Should Be $true
            $result.Output -eq $null | Should Be $true
        }

    }

}