#Import-Module Pester

BeforeAll {
    . $PSScriptRoot/Cam2Web-Pwsh.ps1
    #Join-Path -Path $PSScriptRoot -ChildPath 'Cam2Web-Pwsh.ps1'
}

Describe "Try-GetLocalActiveEndPoint" {
    Context 'Try find internet-reachable route interface ip' {
        It 'Finds IP address' {
            $address = Try-GetLocalActiveEndPoint

            [IPAddress]::Parse($address) | Should -Not -Be $null
        }
    }
}

Describe "Start-Cam2Web" {
    Context "With AutoStart but not hidden." {
        It "Runs and terminates." {
            $process = Start-Cam2Web -AutoStart -ConfigFilePath "$Env:UserProfile\cam2web\cam2web.cfg";
            $process | Should -Not -Be $null
           # $net = Get-NetTCPConnection -OwningProcess $process.Id
            #$net | Should -Not -Be $null

            $uri = Get-Cam2WebUrl
            $uri | Should -Not -Be $null
            if ($process) {
                Start-Sleep -Seconds 7
                Stop-Cam2Web -Force
            }
        }
    }
}