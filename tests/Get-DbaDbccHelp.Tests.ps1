$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command -Name $CommandName).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Statement', 'IncludeUndocumented', 'EnableException'

        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $knownParameters.Count
        }
    }
}
Describe "$commandname Integration Test" -Tag "IntegrationTests" {
    $props = 'Operation', 'Cmd', 'Output'
    $result = Get-DbaDbccHelp -SqlInstance $script:instance2 -Statement FREESYSTEMCACHE

    Context "Validate standard output" {
        foreach ($prop in $props) {
            $p = $result.PSObject.Properties[$prop]
            It "Should return property: $prop" {
                $p.Name | Should Be $prop
            }
        }
    }

    Context "Works correctly" {
        It "returns the right results for FREESYSTEMCACHE" {
            $result.Operation | Should Be 'FREESYSTEMCACHE'
            $result.Cmd | Should Be 'DBCC HELP(FREESYSTEMCACHE)'
            $result.Output | Should Not Be $null
        }

        It "returns the right results for PAGE" {
            $result = Get-DbaDbccHelp -SqlInstance $script:instance2 -Statement PAGE -IncludeUndocumented
            $result.Operation | Should Be 'PAGE'
            $result.Cmd | Should Be 'DBCC HELP(PAGE)'
            $result.Output | Should Not Be $null
        }
    }
}