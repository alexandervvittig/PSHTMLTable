#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

# Define parameters array for the "Processor Time Threshold" and "Processor Time" columns
$paramsProcessorTime70 = @{
    # Column name
    Column = "Processor Time"
    # Reference column name
    SecondColumn = "Processor Time Threshold"
    # Test criteria. Is value greater than or equal to 70% of Processor Time Threshold?
    ScriptBlock = {[double]$args[1] -ge [Math]::Ceiling(([double]$args[0] * .70))}
    # CSS atribute to add if ScriptBlock is true
    CSSAttribute = "style"
}

$paramsProcessorTime80 = @{
    # Column name
    Column = "Processor Time"
    # Reference column name
    SecondColumn = "Processor Time Threshold"
    # Test criteria. Is value greater than or equal to 70% of Processor Time Threshold?
    ScriptBlock = {[double]$args[1] -ge [Math]::Ceiling(([double]$args[0] * .80))}
    # CSS attribute to add if ScriptBlock is true
    CSSAttribute = "style"
}

$paramsProcessorTime90 = @{
    # Column name
    Column = "Processor Time"
    # Reference column name
    SecondColumn = "Processor Time Threshold"
    # Test criteria. Is value greater than or equal to 70% of Processor Time Threshold?
    ScriptBlock = {[double]$args[1] -ge [Math]::Ceiling(([double]$args[0] * .90))}
    # CSS atribute to add if ScriptBlock is true
    CSSAttribute = "style"
}

$Processes = @()
$Processes += Get-Process | Select-Object ProcessName, CPU | Where-Object {$_.CPU -gt 0} | Sort-Object CPU -Descending | ForEach-Object {
        [PSCustomObject]@{
            "Process Name"              = $_.ProcessName
            "Processor Time Threshold"  = ([math]::Round((Get-Random -Minimum 0 -Maximum $_.CPU), 2))
            "Processor Time"            = ([math]::Round($_.CPU, 2))
        }
}

# Create HTML document
$HTML = New-HTMLHead
$HTML += "<h3>Processor Time</h3>"
$HTML += "<h4>Last Updated: $(Get-Date)</h4>"

# Create HTML Table
$HTMLTable = $Processes | New-HTMLTable -HTMLDecode -SetAlternating

# Color "Processor Time Threshold" cell yellow if value is greater than 70% of "Processor Time"
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable CSSAttributeValue "background-color:#f6ed60;" @paramsProcessorTime70

# Color "Processor Time Threshold" cell orange if value is greater than 80% of "Processor Time"
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -CSSAttributeValue "background-color:#feb74f;" @paramsProcessorTime80

# Color entire row red if value of "Processor Time Threshold" is greater than 90% of "Processor Time"
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -CSSAttributeValue "background-color:#ed5e3c;" @paramsProcessorTime90 -HighlightRow

# Add HTML Table to HTML
$HTML += $HTMLTable
$HTML = $HTML | Close-HTML -Validate

$HTML