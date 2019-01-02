$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$commandname Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-ChildItem function:\Get-DbaAvailabilityGroup).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'AvailabilityGroup', 'IsPrimary', 'EnableException'
        it "Should contain our specific parameters" {
            ((Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count) | Should Be $knownParameters.Count
        }
    }
}

Describe "$commandname Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        $agname = "dbatoolsci_agroup"
        $null = New-DbaAvailabilityGroup -Primary $script:instance3 -Name $agname -ClusterType None -FailoverMode Manual -Confirm:$false -Certificate dbatoolsci_AGCert
    }
    AfterAll {
        Remove-DbaAvailabilityGroup -SqlInstance $script:instance3 -AvailabilityGroup $agname -Confirm:$false
    }
    Context "gets ags" {
        It "returns results with proper data" {
            $results = Get-DbaAvailabilityGroup -SqlInstance $script:instance3
            $results.AvailabilityGroup | Should -Contain $agname
        }

        It "returns a single result" {
            $results = Get-DbaAvailabilityGroup -SqlInstance $script:instance3 -AvailabilityGroup $agname
            $results.AvailabilityGroup | Should -Be $agname
        }
    }
} #$script:instance2 for appveyor