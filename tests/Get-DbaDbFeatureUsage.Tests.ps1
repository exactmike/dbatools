$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 6
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Get-DbaDbFeatureUsage).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'InputObject', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $dbname = "dbatoolsci_test_$(get-random)"
        $server = Connect-DbaInstance -SqlInstance $script:instance2
        $server.Query("Create Database [$dbname]")
        $server.Query("Create Table [$dbname].dbo.TestCompression
            (Column1 nvarchar(10),
            Column2 int PRIMARY KEY,
            Column3 nvarchar(18));")
        $server.Query("ALTER TABLE [$dbname].dbo.TestCompression REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ROW);")
    }
    AfterAll {
        $server.Query("DROP Database [$dbname]")
    }
    Context "Gets Feature Usage" {
        $results = Get-DbaDbFeatureUsage -SqlInstance $script:instance2
        It "Gets results" {
            $results | Should Not Be $null
        }
    }
    Context "Gets Feature Usage using -Database" {
        $results = Get-DbaDbFeatureUsage -SqlInstance $script:instance2 -Database $dbname
        It "Gets results" {
            $results | Should Not Be $null
        }
        It "Has the Feature Compression" {
            $results.Feature | Should Be "Compression"
        }
    }
    Context "Gets Feature Usage using -ExcludeDatabase" {
        $results = Get-DbaDbFeatureUsage -SqlInstance $script:instance2 -ExcludeDatabase $dbname
        It "Gets results" {
            $results.database | Should Not Contain $dbname
        }
    }
}