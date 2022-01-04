#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

[CmdletBinding()]
param (
    [string]$Domain = ""
)

process {
    $paramsEmailAddress = @{
        # Column name
        Column = "Current Email Address"
        # Reference column name
        SecondColumn = "Expected Email Address"
        # Test criteria.
        ScriptBlock = {[string]$args[1] -ne [string]$args[0]}
        # CSS attribute to add if ScriptBlock is true
        CSSAttribute = "style"
    }

    # Create an empty array to hold User Objects
    $Users = @()

    # Get user information and use calculated properties to display headers with friendlier names and create a new column for "Full Name Format"
    $Users = Get-ADUser -Filter * -Properties GivenName, SurName, EmailAddress | Select-Object @{Name = "Display Name";Expression = {$_.Name}}, @{Name = "First Name";Expression = {$_.GivenName}}, @{Name = "Last Name";Expression = {$_.SurName}}, @{Name = "Expected Email Address";Expression = {"$($_.GivenName).$($_.SurName)@$Domain"}}, @{Name = "Current Email Address";Expression = {$_.EmailAddress}}

    # Create HTML document
    $HTML = New-HTMLHead
    $HTML += "<h3>Email Address Validation Report</h3>"
    $HTML += "<h4>Last Updated: $(Get-Date)</h4>"

    # Create HTML Table
    $HTMLTable = $Users | New-HTMLTable -HTMLDecode -SetAlternating

    # Color entire row red if value of "Email Address" is not in the format of First.Last@domain.com". Use -Domain to specify "domain.com"
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -CSSAttributeValue "background-color:#ed5e3c;" @paramsEmailAddress -HighlightRow

    # Add HTML Table to HTML
    $HTML += $HTMLTable
    $HTML = $HTML | Close-HTML -Validate

    $HTML
}