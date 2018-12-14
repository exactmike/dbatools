$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 3
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Get-DbaDetachedDatabaseInfo).Parameters.Keys
        $knownParameters = 'SqlInstance', 'Path', 'SqlCredential'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $server = Connect-DbaInstance -SqlInstance $script:instance2
        $random = Get-Random
        $dbname = "dbatoolsci_detatch_$random"
        $server.Query("CREATE DATABASE $dbname")
        $path = (Get-DbadbFile -SqlInstance $script:instance2 -Database $dbname | Where-object {$_.PhysicalName -like '*.mdf'}).physicalname
        Detach-DbaDatabase -SqlInstance $script:instance2 -Database $dbname -Force
    }

    AfterAll {
        $server.Query("CREATE DATABASE $dbname
            ON (FILENAME = '$path')
            FOR ATTACH")
        Remove-DbaDatabase -SqlInstance $script:Instance2 -Database $dbname -Confirm:$false
    }

    Context "Command actually works" {
        $results = Get-DbaDetachedDatabaseInfo -SqlInstance $script:Instance2 -Path $path
        it "Gets Results" {
            $results | Should Not Be $null
        }
        It "Should be created database" {
            $results.name | Should Be $dbname
        }
        It "Should be 2016" {
            $results.version | Should Be 'SQL Server 2016'
        }
        It "Should have Data files" {
            $results.DataFiles | Should Not Be $null
        }
        It "Should have Log files" {
            $results.LogFiles | Should Not Be $null
        }
    }
}