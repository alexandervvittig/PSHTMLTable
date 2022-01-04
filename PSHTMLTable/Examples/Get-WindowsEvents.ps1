#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

# Define parameters array for the "LevelDisplayName" column
$paramsLevelDisplayName = @{
    # Column name
    Column = "LevelDisplayName"
    # Test criteria. Is value equal to Argument?
    ScriptBlock = {[string]$args[0] -eq [string]$args[1]}
    # CSS attribute to add if ScriptBlock is true
    CSSAttribute = "style"
}

# Retrieve Windows events from the System log
$Events = Get-WinEvent -LogName 'System' | Select-Object -First 100 TimeCreated, ProviderName, LevelDisplayName, Message

# Create HTML document
$HTML = New-HTMLHead
$HTML += "<h3>Most Recent Windows Event Log Entries</h3>"

# Create HTML Table
$HTMLTable = $Events | Sort-Object TimeCreated -Descending | New-HTMLTable -HTMLDecode -SetAlternating

# Color LevelDisplayName cell green if value is "Information"
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument "Information" -CSSAttributeValue "background-color:#8fc975;" @paramsLevelDisplayName

# Color LevelDisplayName cell orange if value is "Warning"
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument "Warning" -CSSAttributeValue "background-color:#feb74f;" @paramsLevelDisplayName

# Color LevelDisplayName row red if value is "Error"
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument "Error" -CSSAttributeValue "background-color:#ed5e3c;" @paramsLevelDisplayName -HighlightRow

# Add HTML Table to HTML
$HTML += $HTMLTable
$HTML = $HTML | Close-HTML -Validate

$HTML