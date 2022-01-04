#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

# Retrieve all processes
$Processes = Get-Process

# Create HTML document
$HTML = New-HTMLHead -title "Process Details"

# Add CPU time section with top 10 PrivateMemorySize processes.  This example does not highlight any particular cells.
$HTML += "<h3>Process Private Memory Size</h3>"
$HTML += New-HTMLTable $($Processes | Sort-Object PrivateMemorySize -Descending | Select-Object Name, PrivateMemorySize -First 10)

# Add Handles section with top 10 Handle usage.
$HTMLTable = New-HTMLTable $($Processes | Sort-Object Handles -Descending | Select-Object Name, Handles -First 10)

# Add highlighted colors for Handle count

# Define parameters array for the "Handles" column
$params = @{
    # Column name
    Column = "Handles"
    # Test criteria. Is value greater than to Argument?
    ScriptBlock = {[double]$args[0] -gt [double]$args[1]}
    # CSS attribute to add if ScriptBlock is true
    CSSAttribute = "style"
}

# Add yellow, orange and red shading.
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 1500 -CSSAttributeValue "background-color:#FFFF99;" @params
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 2000 -CSSAttributeValue "background-color:#FFCC66;" @params
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 3000 -CSSAttributeValue "background-color:#FFCC99;" @params

# Add title and table
$HTML += "<h3>Process Handles</h3>"
$HTML += $HTMLTable

# Add process list containing first 10 processes listed by get-process. This example does not highlight any particular cells.
$HTML += "<h3>Random Process Names As List</h3>"
$HTML += New-HTMLTable $($Processes | Select-Object Name -First 10) -ListTableHead "Random Process Names"

# Add property value table showing details for PowerShell
$HTML += "<h3>PowerShell Process Details PropertyValue Table</h3>"
$ProcessDetails = Get-Process powershell | Select-Object Name, Id, CPU, Handles, WorkingSet, PrivateMemorySize, Path -First 1
$HTML += New-HTMLTable $(ConvertTo-PropertyValue $ProcessDetails)

# Add same PowerShell details but not in property value form. Close the HTML.
$HTML += "<h3>PowerShell Process Details Object</h3>"
$HTML += New-HTMLTable $ProcessDetails
$HTML = $HTML | Close-HTML -Validate

$HTML