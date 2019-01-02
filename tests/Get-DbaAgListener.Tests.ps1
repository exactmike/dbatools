$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-ChildItem function:\Get-DbaAgListener).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'AvailabilityGroup', 'Listener', 'InputObject', 'EnableException'
        It "Should contain our specific parameters" {
            ((Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count) | Should Be $knownParameters.Count
        }
    }
}

Describe "$commandname Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        $agname = "dbatoolsci_ag_listener"
        $ag = New-DbaAvailabilityGroup -Primary $script:instance3 -Name $agname -ClusterType None -FailoverMode Manual -Confirm:$false -Certificate dbatoolsci_AGCert |
            Add-DbaAgListener -IPAddress 127.0.20.1 -Confirm:$false
    }
    AfterAll {
        $null = Remove-DbaAvailabilityGroup -SqlInstance $server -AvailabilityGroup $agname -Confirm:$false
    }
    Context "gets ags" {
        It "returns results with proper data" {
            $results = Get-DbaAgListener -SqlInstance $script:instance3
            $results.PortNumber | Should -Contain 1433
        }
    }
} #$script:instance2 for appveyor