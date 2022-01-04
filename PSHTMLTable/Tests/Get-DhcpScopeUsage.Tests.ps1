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
        $paramsPercentInUse = @{
            # Column name
            Column = "% In Use"
            # Test criteria: Is value greater than or equal to Argument?
            ScriptBlock = {[double]$args[0] -ge [double]$args[1]}
            # CSS attribute to add if ScriptBlock is true
            CSSAttribute = "style"
            # Format column with 2 decimal places and add a percent symbol
            StringFormat = "{0:N2} %"
        }
    
        $MyCSS = '
        body {
            color: #333333;
            font-family: Calibri,Tahoma,Arial,Verdana;
            font-size: 11pt;
            margin: 0px;
            padding: 0px;
        }
        h3 {
            margin: 0px 0px 5px 0px;
        }
        h4 {
            margin: 0px;
        }
        table {
            border-collapse: collapse;
            border-bottom: solid black 1px;
        }
        th {
            text-align: center;
            font-weight: bold;
            border-top: 1px solid black;
            border-bottom: 1px solid black;
            white-space: nowrap;
            padding: 0px 10px 0px 10px;
        }
        td {
            padding: 2px 10px 2px 10px;
            text-align: center;
            white-space: nowrap;
        }
        .odd {
            background-color: #ffffff;
        }
        .even {
            background-color: #dddddd;
        }'
        Mock -CommandName Get-DHCPServerv4Scope -MockWith {
            9..0 | ForEach-Object {
                [PSCustomObject]@{
                    ScopeId         =   "192.168.$_.0"
                    Name            =   "VLAN $_"
                    State           =   "Active"
                    LeaseDuration   =   New-TimeSpan -Days 8
                    SubnetMask      =   "255.255.255.0"
                    StartRange      =   "192.168.$_.1"
                    EndRange        =   "192.168.$_.254"
                }
            }
        }
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   197
                InUse           =   57
                PercentageInUse =   22.44094
            }
        } -ParameterFilter {$ScopeId -eq "192.168.0.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   14
                InUse           =   240
                PercentageInUse =   94.48818
            }
        } -ParameterFilter {$ScopeId -eq "192.168.1.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   242
                InUse           =   12
                PercentageInUse =   4.72440
            }
        } -ParameterFilter {$ScopeId -eq "192.168.2.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   249
                InUse           =   5
                PercentageInUse =   1.96850
            }
        } -ParameterFilter {$ScopeId -eq "192.168.3.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   197
                InUse           =   57
                PercentageInUse =   22.44094
            }
        } -ParameterFilter {$ScopeId -eq "192.168.4.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   204
                InUse           =   50
                PercentageInUse =   19.68503
            }
        } -ParameterFilter {$ScopeId -eq "192.168.5.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   253
                InUse           =   1
                PercentageInUse =   0.39370
            }
        } -ParameterFilter {$ScopeId -eq "192.168.6.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   217
                InUse           =   37
                PercentageInUse =   14.56692
            }
        } -ParameterFilter {$ScopeId -eq "192.168.7.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   253
                InUse           =   1
                PercentageInUse =   0.39370
            }
        } -ParameterFilter {$ScopeId -eq "192.168.8.0"}
        Mock -CommandName Get-DhcpServerv4ScopeStatistics -MockWith {
            [PSCustomObject]@{
                Free            =   212
                InUse           =   42
                PercentageInUse =   16.53543
            }
        } -ParameterFilter {$ScopeId -eq "192.168.9.0"}

        Mock -CommandName Get-DhcpServerv4Reservation -MockWith {
        } #-ParameterFilter {$ScopeId -eq "192.168.9.0"}
        Mock -CommandName Get-DhcpServerv4Reservation -MockWith {
            1..3 | ForEach-Object {
                [PSCustomObject]@{
                    Name = 'Value'
                }
            }
        } -ParameterFilter {$ScopeId -eq "192.168.2.0"}
        Mock -CommandName Get-DhcpServerv4Reservation -MockWith {
            1..2 | ForEach-Object {
                [PSCustomObject]@{
                    Name = 'Value'
                }
            }
        } -ParameterFilter {$ScopeId -eq "192.168.3.0"}
        Mock -CommandName Get-DhcpServerv4Reservation -MockWith {
            1..4 | ForEach-Object {
                [PSCustomObject]@{
                    Name = 'Value'
                }
            }
        } -ParameterFilter {$ScopeId -eq "192.168.7.0"}
        Mock -CommandName Get-DhcpServerv4Reservation -MockWith {
            1..4 | ForEach-Object {
                [PSCustomObject]@{
                    Name = 'Value'
                }
            }
        } -ParameterFilter {$ScopeId -eq "192.168.9.0"}
        $ScopesArray = @()
        $Scopes = Get-DHCPServerv4Scope -ComputerName $ComputerName
        #Assert-MockCalled –CommandName 'Get-DHCPServerv4Scope' –Times 1 –Scope It
        #$Scopes.Count | Should -Be 10
        foreach ($Scope in $Scopes) {
            $Statistics = Get-DhcpServerv4ScopeStatistics -ComputerName $ComputerName -ScopeId $Scope.ScopeId
            $ScopeObj = [PSCustomObject]@{
                "ID"                = $Scope.ScopeId
                "Name"              = $Scope.Name
                "State"             = $Scope.State
                "Lease Duration"    = $Scope.LeaseDuration
                "Subnet Mask"       = $Scope.SubnetMask
                "Start Range"       = $Scope.StartRange
                "End Range"         = $Scope.EndRange
                "Total Addresses"   = $($Statistics.Free + $Statistics.InUse)
                "Reserved"          = @(Get-DhcpServerv4Reservation -ComputerName $ComputerName -ScopeId $Scope.ScopeId).Count
                "In Use"            = $Statistics.InUse
                "Available"         = $Statistics.Free
                "% In Use"          = $([math]::Round($Statistics.PercentageInUse, 2))
            }
            $ScopesArray += $ScopeObj
        }
    }
    It 'validates example script output' {
        #Assert-MockCalled –CommandName 'Get-DhcpServerv4Reservation' –Times 10 –Scope It
        #$ScopesArray | Should -BeNullOrEmpty
        $HTML = New-HTMLHead -Style $MyCSS
        $HTMLTable = $ScopesArray | Sort-Object Id | New-HTMLTable -HTMLDecode -SetAlternating
        $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 80 -CSSAttributeValue "background:#ed5e3c;" @paramsPercentInUse -ApplyFormat
        $HTML += $HTMLTable
        $HTML = $HTML | Close-HTML -Validate
        $HTML | Should -BeExactly @'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"[]>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <style>

        body {
            color: #333333;
            font-family: Calibri,Tahoma,Arial,Verdana;
            font-size: 11pt;
            margin: 0px;
            padding: 0px;
        }
        h3 {
            margin: 0px 0px 5px 0px;
        }
        h4 {
            margin: 0px;
        }
        table {
            border-collapse: collapse;
            border-bottom: solid black 1px;
        }
        th {
            text-align: center;
            font-weight: bold;
            border-top: 1px solid black;
            border-bottom: 1px solid black;
            white-space: nowrap;
            padding: 0px 10px 0px 10px;
        }
        td {
            padding: 2px 10px 2px 10px;
            text-align: center;
            white-space: nowrap;
        }
        .odd {
            background-color: #ffffff;
        }
        .even {
            background-color: #dddddd;
        }
</style>
  </head>
  <body>
    <table>
      <colgroup>
        <col />
        <col />
        <col />
        <col />
        <col />
        <col />
        <col />
        <col />
        <col />
        <col />
        <col />
        <col />
      </colgroup>
      <tr>
        <th>ID</th>
        <th>Name</th>
        <th>State</th>
        <th>Lease Duration</th>
        <th>Subnet Mask</th>
        <th>Start Range</th>
        <th>End Range</th>
        <th>Total Addresses</th>
        <th>Reserved</th>
        <th>In Use</th>
        <th>Available</th>
        <th>% In Use</th>
      </tr>
      <tr class="even first-child">
        <td valign="top">192.168.0.0</td>
        <td valign="top">VLAN 0</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.0.1</td>
        <td valign="top">192.168.0.254</td>
        <td valign="top">254</td>
        <td valign="top">0</td>
        <td valign="top">57</td>
        <td valign="top">197</td>
        <td valign="top">22.44 %</td>
      </tr>
      <tr class="odd">
        <td valign="top">192.168.1.0</td>
        <td valign="top">VLAN 1</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.1.1</td>
        <td valign="top">192.168.1.254</td>
        <td valign="top">254</td>
        <td valign="top">0</td>
        <td valign="top">240</td>
        <td valign="top">14</td>
        <td valign="top" style="background:#ed5e3c;">94.49 %</td>
      </tr>
      <tr class="even">
        <td valign="top">192.168.2.0</td>
        <td valign="top">VLAN 2</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.2.1</td>
        <td valign="top">192.168.2.254</td>
        <td valign="top">254</td>
        <td valign="top">3</td>
        <td valign="top">12</td>
        <td valign="top">242</td>
        <td valign="top">4.72 %</td>
      </tr>
      <tr class="odd">
        <td valign="top">192.168.3.0</td>
        <td valign="top">VLAN 3</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.3.1</td>
        <td valign="top">192.168.3.254</td>
        <td valign="top">254</td>
        <td valign="top">2</td>
        <td valign="top">5</td>
        <td valign="top">249</td>
        <td valign="top">1.97 %</td>
      </tr>
      <tr class="even">
        <td valign="top">192.168.4.0</td>
        <td valign="top">VLAN 4</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.4.1</td>
        <td valign="top">192.168.4.254</td>
        <td valign="top">254</td>
        <td valign="top">0</td>
        <td valign="top">57</td>
        <td valign="top">197</td>
        <td valign="top">22.44 %</td>
      </tr>
      <tr class="odd">
        <td valign="top">192.168.5.0</td>
        <td valign="top">VLAN 5</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.5.1</td>
        <td valign="top">192.168.5.254</td>
        <td valign="top">254</td>
        <td valign="top">0</td>
        <td valign="top">50</td>
        <td valign="top">204</td>
        <td valign="top">19.69 %</td>
      </tr>
      <tr class="even">
        <td valign="top">192.168.6.0</td>
        <td valign="top">VLAN 6</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.6.1</td>
        <td valign="top">192.168.6.254</td>
        <td valign="top">254</td>
        <td valign="top">0</td>
        <td valign="top">1</td>
        <td valign="top">253</td>
        <td valign="top">0.39 %</td>
      </tr>
      <tr class="odd">
        <td valign="top">192.168.7.0</td>
        <td valign="top">VLAN 7</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.7.1</td>
        <td valign="top">192.168.7.254</td>
        <td valign="top">254</td>
        <td valign="top">4</td>
        <td valign="top">37</td>
        <td valign="top">217</td>
        <td valign="top">14.57 %</td>
      </tr>
      <tr class="even">
        <td valign="top">192.168.8.0</td>
        <td valign="top">VLAN 8</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.8.1</td>
        <td valign="top">192.168.8.254</td>
        <td valign="top">254</td>
        <td valign="top">0</td>
        <td valign="top">1</td>
        <td valign="top">253</td>
        <td valign="top">0.39 %</td>
      </tr>
      <tr class="odd last-child">
        <td valign="top">192.168.9.0</td>
        <td valign="top">VLAN 9</td>
        <td valign="top">Active</td>
        <td valign="top">8.00:00:00</td>
        <td valign="top">255.255.255.0</td>
        <td valign="top">192.168.9.1</td>
        <td valign="top">192.168.9.254</td>
        <td valign="top">254</td>
        <td valign="top">4</td>
        <td valign="top">42</td>
        <td valign="top">212</td>
        <td valign="top">16.54 %</td>
      </tr>
    </table>
  </body>
</html>
'@
    }
}