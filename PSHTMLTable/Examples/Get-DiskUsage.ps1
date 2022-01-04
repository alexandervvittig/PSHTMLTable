#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

[CmdletBinding()]
param (
    [string[]]$ComputerName = "$env:COMPUTERNAME"
)

begin {
    function Format-Bytes {
        <#
        .SYNOPSIS
        Formats an integer size into a user friendly byte size.

        .DESCRIPTION
        Formats an integer size into a user friendly Bytes, KB, MB, GB, TB, PB size. For Example, 259471491072 returns 241.65 GB.

        .PARAMETER Bytes
        The number of bytes to convert.

        .EXAMPLE
        Format-Bytes -Bytes 134217728
        128.00 MB

        .EXAMPLE
        Format-Bytes -Bytes 259471491072
        241.65 GB
        #>
        #Requires -version 2.0

        param (
            [Parameter(Mandatory = $true, Position = 0)][int64]$Bytes,
            [int]$Precision = 2,
            [string]$Prefix,
            [string]$Suffix
        )

        switch ($Bytes) {
            {$Bytes -ge 1PB} {
                $result = "$Prefix{0:$("N$Precision")} PB$Suffix" -f [math]::Round(($Bytes / 1PB), $Precision)
                break
            }
            {$Bytes -ge 1TB} {
                $result = "$Prefix{0:$("N$Precision")} TB$Suffix" -f [math]::Round(($Bytes / 1TB), $Precision)
                break
            }
            {$Bytes -ge 1GB} {
                $result = "$Prefix{0:$("N$Precision")} GB$Suffix" -f [math]::Round(($Bytes / 1GB), $Precision)
                break
            }
            {$Bytes -ge 1MB} {
                $result = "$Prefix{0:$("N$Precision")} MB$Suffix" -f [math]::Round(($Bytes / 1MB), $Precision)
                break
            }
            {$Bytes -ge 1KB} {
                $result = "$Prefix{0:$("N$Precision")} KB$Suffix" -f [math]::Round(($Bytes / 1KB), $Precision)
                break
            } default {
                $result = "$Prefix$Bytes B$Suffix"
                break
            }
        }
        return $result
    }
    # Define parameters array for the "Size" column
    $paramsSize = @{
        # Column name
        Column = "Size"
        # Test criteria: None. Used only for Formatting.
        CommandFormat = ${function:Format-Bytes}
    }

    # Define parameters array for the "Free Space" column
    $paramsFreeSpace = @{
        # Column name
        Column = "Free Space"
        # Test criteria: Is value less than or equal to Argument?
        ScriptBlock = {[double]$args[0] -le [double]$args[1]}
        # CSS attribute to add if ScriptBlock is true
        CSSAttribute = "style"
        # Format column with Format-Bytes function.
        CommandFormat = ${function:Format-Bytes}
    }
    # Define parameters array for the "Utilization" column
    $paramsUtilization = @{
        # Column name
        Column = "Utilization"
        # Test criteria: Is value greater than or equal to Argument?
        ScriptBlock = {[double]$args[0] -ge [double]$args[1]}
        # CSS attribute to add if ScriptBlock is true
        CSSAttribute = "style"
        # Format column with 2 decimal places and add a percent symbol
        StringFormat = "{0:N2} %"
    }
    $paramsErrorMessage = @{
        # Column name
        Column = "Error Message"
        # Test criteria: always highlight cell
        ScriptBlock = {$true}
        # CSS attribute to add if ScriptBlock is true
        CSSAttribute = "style"
    }
}
process {
    $CimInstances = @(Get-CimInstance -ComputerName $ComputerName -Class CIM_LogicalDisk -ErrorAction SilentlyContinue -ErrorVariable ErrorInstances | Where-Object DriveType -eq '3' | Select-Object SystemName, DeviceId, VolumeName, Description, Size, FreeSpace)
    if ($CimInstances.Count -gt 0 -or $ErrorInstances.Count -gt 0) {
        # Create HTML document
        $HTML = New-HTMLHead
        $HTML += "<h3>Disk Usage by Server</h3>"
        $HTML += "<h4>Last Updated: $(Get-Date)</h4>"
        $HTML += '<table id="container" cellpadding="0" cellspacing="0" border="0">'

        $CimInstances | Sort-Object SystemName, DeviceID | Group-Object SystemName | ForEach-Object {
            $HTML += "<tr><td style=""border: none;text-align: left;"" colspan=""6""><h3>$($_.Name) ($($_.Group.Count))</h3></td></tr>"
            $HTMLTable = $_.Group | Select-Object @{Name = "Drive Letter";Expression = {$_.DeviceId}}, @{Name = "Drive Label";Expression = {$_.VolumeName}}, @{Name = "Description";Expression = {$_.Description}}, @{Name = "Size";Expression = {$_.Size}}, @{Name = "Free Space";Expression = {$_.FreeSpace}}, @{Name = "Utilization";Expression = {($_.Size - $_.FreeSpace) / $_.Size * 100}} | New-HTMLTable -HTMLDecode -SetAlternating -NestedTable -RemoveColumnGroup
            # Color "Utilization" cell yellow if value is greater than or equal to 60%
            $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 60 -CSSAttributeValue "background-color:#f6ed60;" @paramsUtilization
            # Color "Utilization" cell orange if value is greater than or equal to 75%
            $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 75 -CSSAttributeValue "background-color:#feb74f;" @paramsUtilization
            # Color "Utilization" cell red if value is greater than or equal to 90%
            $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 90 -CSSAttributeValue "background-color:#ed5e3c;" @paramsUtilization -ApplyFormat
            # Color "Free Space" text red if value is less than or equal to 80 Gigabytes
            $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 80GB -CSSAttributeValue "color:#ed5e3c;" @paramsFreeSpace -ApplyFormat
            # Format Size column
            $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable @paramsSize -ApplyFormat
            $HTML += $HTMLTable
        }
        $ErrorInstances | Sort-Object OriginInfo | ForEach-Object {
            $HTML += "<tr><td style=""border: none;text-align: left;padding: 0px;"" colspan=""6""><h3 style=""padding: 5px 10px 5px 10px;"">$($_.OriginInfo)</h3>"
            $HTMLTable = $_ | Select-Object @{Name = "Error Message";Expression = {$_.Exception.Message}} | New-HTMLTable -HTMLDecode -SetAlternating -TableAttributes @{"width" = "100%"} -RemoveColumnGroup -ColumnClass "align-left"
            # Color "Error Message" red
            $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -CSSAttributeValue "background-color:#ed5e3c;" @paramsErrorMessage
            $HTML += $HTMLTable
            $HTML += "</td>"
            $HTML += "</tr>"
        }
        $HTML += "</table>"
        $HTML = $HTML | Close-HTML -Validate
    }
    $HTML
}