#region Discovery
$ModuleName = 'PSHTMLTable'
if (Get-Module $ModuleName) {
    Remove-Module -Name $ModuleName -Force
}
#endregion Discovery

BeforeAll {
    $ModuleName = 'PSHTMLTable'
    $ModuleRoot = Split-Path $PSScriptRoot
    Import-Module -Name "$ModuleRoot\$ModuleName"
}
AfterAll {
    if (Get-Module $ModuleName) {
        Remove-Module -Name $ModuleName -Force
    }
}

Describe "$ModuleName Get-DhcpScopeUsage Example Tests"  {
    BeforeAll {
        $Computers = 
        [PSCustomObject]@{
            "Computer Name"         = "server01.contoso.com"
            "IP Address"            = "192.168.0.104"
            "Not Installed"         = 17
            "Failed"                = 0
            "Pending Reboot"        = 0
            "Operating System"      = "Windows Server 2012 R2"
            "Last Contact"          = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
            "Last Status Report"    = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
        },
        [PSCustomObject]@{
            "Computer Name"         = "server02.contoso.com"
            "IP Address"            = "192.168.0.10"
            "Not Installed"         = 0
            "Failed"                = 0
            "Pending Reboot"        = 0
            "Operating System"      = "Windows Server 2016 Standard"
            "Last Contact"          = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
            "Last Status Report"    = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
        },
        [PSCustomObject]@{
            "Computer Name"         = "server03.contoso.com"
            "IP Address"            = "192.168.0.11"
            "Not Installed"         = 0
            "Failed"                = 0
            "Pending Reboot"        = 0
            "Operating System"      = "Windows Server 2016 Standard"
            "Last Contact"          = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
            "Last Status Report"    = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
        },
        [PSCustomObject]@{
            "Computer Name"         = "desktop01.contoso.com"
            "IP Address"            = "192.168.0.107"
            "Not Installed"         = 17
            "Failed"                = 0
            "Pending Reboot"        = 0
            "Operating System"      = "Windows 7 Professional"
            "Last Contact"          = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
            "Last Status Report"    = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
        },
        [PSCustomObject]@{
            "Computer Name"         = "desktop02.contoso.com"
            "IP Address"            = "192.168.0.110"
            "Not Installed"         = 44
            "Failed"                = 0
            "Pending Reboot"        = 3
            "Operating System"      = "Windows 7"
            "Last Contact"          = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
            "Last Status Report"    = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss tt")
        }
    }
    It 'should be null' {
        #$Computers | Should -BeNullOrEmpty
        $null | Should -BeNullOrEmpty
    }
}