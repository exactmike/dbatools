$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 5
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Get-DbaDbMailLog).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Since', 'Type', 'EnableException'
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
        $server = Connect-DbaInstance -SqlInstance $script:instance2
        $server.Query("INSERT INTO msdb.[dbo].[sysmail_log]
        ([event_type]
        ,[log_date]
        ,[description]
        ,[process_id]
        ,[mailitem_id]
        ,[account_id]
        ,[last_mod_date]
        ,[last_mod_user])
        VALUES
        (1,'2018-12-09 12:18:14.920','DatabaseMail process is started',4890,NULL,NULL,'2018-12-09 12:18:14.920','dbatools\dbatoolssci')")
    }
    AfterAll {
        $server.Query("DELETE FROM msdb.[dbo].[sysmail_log] WHERE last_mod_user = 'dbatools\dbatoolssci'")
    }

    Context "Gets Db Mail Log" {
        $results = Get-DbaDbMailLog -SqlInstance $script:instance2 | Where-Object {$_.Login -eq 'dbatools\dbatoolssci'}
        It "Gets results" {
            $results | Should Not Be $null
        }
        It "Should have created Description" {
            $results.description | Should be 'DatabaseMail process is started'
        }
        It "Should have last modified user of dbatools\dbatoolssci " {
            $results.lastmoduser | Should be 'dbatools\dbatoolssci'
        }
    }
    Context "Gets Db Mail Log using -Type" {
        $results = Get-DbaDbMailLog -SqlInstance $script:instance2 -Type Information
        It "Gets results" {
            $results | Should Not Be $null
        }
        It "Should have Log Id" {
            $results.logid | Should not be $null
        }
        It "Should have an Event Type of Information" {
            $results.eventtype | Should be 'Information'
        }
    }
    Context "Gets Db Mail History using -Since" {
        $results = Get-DbaDbMailLog -SqlInstance $script:instance2 -Since '2018-01-01'
        It "Gets results" {
            $results | Should Not Be $null
        }
        It "Should have a LogDate greater than 2018-01-01" {
            $results.LogDate | Should Begreaterthan '2018-01-01'
        }
        It "Should have a LastModDate greater than 2018-01-01" {
            $results.LastModDate | Should Begreaterthan '2018-01-01'
        }
    }
}