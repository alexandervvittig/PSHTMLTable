#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

[CmdletBinding()]
param (
    [string]$ComputerName = "$env:COMPUTERNAME"
)

begin {
    # Define parameters array for the "% In Use" column
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
    # Define custom CSS
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
}
process {
    # Create blank array to hold objects
    $ScopesArray = @()

    $Scopes = Get-DHCPServerv4Scope -ComputerName $ComputerName
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
    # Create HTML document
    $HTML = New-HTMLHead -Style $MyCSS
    $HTML += "<h3>$ComputerName - DHCP Scopes ($($Scopes.Count))</h3>"

    # Create HTML Table
    $HTMLTable = $ScopesArray | Sort-Object Id | New-HTMLTable -HTMLDecode -SetAlternating

    # Color "% In Use" cell red if value is less than or equal to 80 %
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 80 -CSSAttributeValue "background:#ed5e3c;" @paramsPercentInUse -ApplyFormat

    # Add HTML Table to HTML
    $HTML += $HTMLTable
    $HTML = $HTML | Close-HTML -Validate

    $HTML
}