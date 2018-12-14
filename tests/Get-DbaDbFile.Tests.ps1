$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Get-DbaDbFile).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'InputObject', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $knownParameters.Count
        }
        It "Should only contain $($knownParameters.Count) parameters" {
            $params.Count - $defaultParamCount | Should Be $knownParameters.Count
        }
    }
}

Describe "$CommandName Unit Tests" -Tag "Unit" {
    Context "Ensure array" {
        $results = Get-Command -Name Get-DbaDbFile | Select-Object -ExpandProperty ScriptBlock
        It "returns disks as an array" {
            $results -match '\$disks \= \@\(' | Should -Be $true
        }
    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    Context "Count system databases on localhost" {
        $results = Get-DbaDbFile -SqlInstance $script:instance1
        It "returns information about tempdb" {
            $results.Database -contains "tempdb" | Should -Be $true
        }
    }

    Context "Check that temppb database is in Simple recovery mode" {
        $results = Get-DbaDbFile -SqlInstance $script:instance1 -Database tempdb
        foreach ($result in $results) {
            It "returns only information about tempdb" {
                $result.Database | Should -Be "tempdb"
            }
        }
    }

    Context "Physical name is populated" {
        $results = Get-DbaDbFile -SqlInstance $script:instance1 -Database master
        It "master returns proper results" {
            $result = $results | Where-Object LogicalName -eq 'master'
            $result.PhysicalName -match 'master.mdf' | Should -Be $true
            $result = $results | Where-Object LogicalName -eq 'mastlog'
            $result.PhysicalName -match 'mastlog.ldf' | Should -Be $true
        }
    }
}