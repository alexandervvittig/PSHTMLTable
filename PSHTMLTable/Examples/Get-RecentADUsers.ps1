#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

[CmdletBinding()]
param (
    [int]$NumberOfDays = 1,
    [switch]$SendEmail = $false,
    [string]$FromAddress = "First.Last@domain.com",
    [string]$RecipientAddress = "recipient@domain.com",
    [string]$SMTPServer = "",
    [int32]$SMTPPort = 25
)

process {
    # Loads Active Directory Module to Query AD Information
    Import-Module -Name ActiveDirectory

    # Convert NumberOfDays to an actual date
    [datetime]$StartDate = ((Get-Date).AddDays($NumberOfDays * -1)).Date

    # Create empty array to store objects found during active directory query
    $Users = @()

    # Retrieve list of users from Active Directory that were created on or after date
    $Users = Get-ADUser -Filter {whenCreated -ge $StartDate} -Properties whenCreated, Title, EmailAddress, DisplayName

    # Create HTML document if new users exist within specified time span
    if ($Users.Count -gt 0) {
        # Create HTML document
        $HTML = New-HTMLHead
        $HTML += "<h3>New Users Since $($StartDate.ToString("MM/dd/yyyy")) - ($($Users.Count))</h3>"
        $HTML += "<h4>Last Updated: $(Get-Date)</h4>"

        # Create HTML Table using calculated properties to change properties to a friendlier name
        $HTMLTable = $Users | Select-Object @{Name="Display Name"; Expression = {$_.DisplayName}}, @{Name="Username"; Expression = {$_.SamAccountName}}, Title, @{Name="Email Address"; Expression = {$_.emailAddress}}, @{Name="Creation Date"; Expression = {$_.whenCreated}} | Sort-Object "Display Name" | New-HTMLTable -HTMLDecode -SetAlternating

        # Add HTML Table to HTML
        $HTML += $HTMLTable
        $HTML = $HTML | Close-HTML -Validate

        if ($SendEmail) {
            # Send HTML to recipient(s)
            try {
                Send-MailMessage -From $FromAddress -To $RecipientAddress -Subject "$ComputerName - New User Report" -Body $HTML -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort
            } catch {
                throw $_
            }
        } else {
            $HTML
        }
    }
}