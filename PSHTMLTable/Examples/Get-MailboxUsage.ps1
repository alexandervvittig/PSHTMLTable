#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

# Define parameters array for the "Total Size (GB)" column
$paramsTotalSize = @{
    # Column name
    Column = "Total Size (GB)"
    # Test criteria. Is value greater than or equal to Argument?
    ScriptBlock = {[double]$args[0] -ge [double]$args[1]}
    # CSS attribute to add if ScriptBlock is true
    CSSAttribute = "style"
}
# Create blank array to hold objects
$Mailboxes = @()

$Mailboxes += Get-Mailbox -ResultSize Unlimited | ForEach-Object {
    $MailboxStatistics = Get-MailboxStatistics $_.Identity.DistinguishedName
    [PSCustomObject]@{
        "Display Name"          = $_.DisplayName
        "Primary SMTP Address"  = $_.PrimarySmtpAddress
        "Total Size (GB)"       = ([math]::Round($MailboxStatistics.TotalItemSize.Value.ToBytes() / 1Gb, 2))
        "Items"                 = $MailboxStatistics.ItemCount
    }
}

# Create HTML document
$HTML = New-HTMLHead
$HTML += "<h3>Mailbox Usage</h3>"
$HTML += "<h4>Last Updated: $(Get-Date)</h4>"

# Create HTML Table
$HTMLTable = $Mailboxes | Sort-Object "Total Size (GB)" -Descending | New-HTMLTable -HTMLDecode -SetAlternating

# Color "Total Size (GB)" cell green if value is greater than 0 and less than 1.5
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 0 -CSSAttributeValue "background-color:#8fc975;" @paramsTotalSize

# Color "Total Size (GB)" cell orange if value is greater than 1.5 and less than 2.0
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 1.5 -CSSAttributeValue "background-color:#feb74f;" @paramsTotalSize

# Color "Total Size (GB)" cell red if value is greater than 2.0
$HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 2.0 -CSSAttributeValue "background-color:#ed5e3c;" @paramsTotalSize

# Add HTML Table to HTML
$HTML += $HTMLTable
$HTML += '<h4>Color Coding:</h4>'
$HTML += '<ul>'
$HTML += '<li>Total Size (GB) greater than 2.0 is <span style="background-color:#ed5e3c;">red</span></li>'
$HTML += '<li>Total Size (GB) between 1.5 and 2.0 is <span style="background-color:#feb74f;">orange</span></li>'
$HTML += '<li>Total Size (GB) betwee 0 and 1.5 is <span style="background-color:#8fc975;">green</span></li>'
$HTML += '<ul>'
$HTML = $HTML | Close-HTML -Validate

$HTML