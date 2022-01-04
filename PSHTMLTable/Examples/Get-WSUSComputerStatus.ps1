#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}
#Requires -PSEdition Desktop

[CmdletBinding()]
param (
    [string]$ComputerName = "$env:COMPUTERNAME",
    [int32]$WSUSPort = 8530,
    [switch]$UseSSL = $false,
    [switch]$SendEmail = $false,
    [string]$FromAddress = "First.Last@domain.com",
    [string]$RecipientAddress = "recipient@domain.com",
    [string]$SMTPServer = "",
    [int32]$SMTPPort = 25
)

process {
    function Get-LocalTime ($UTCTime) {
        $CurrentTimeZone = (Get-CimInstance -ClassWin32_TimeZone).StandardName
        $TimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($CurrentTimeZone)
        [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TimeZone)
    }

    # Test for connection
    if ($null -eq $WSUS) {
        # No connection detected, load assembly
        [void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
    }

    # Connect to WSUS server
    try {
        $WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($ComputerName, $UseSSL, $WSUSPort)
    } catch {
        throw $_
    }

    # Create empty array to store computer objects found during wsus query
    $Computers = @()

    $Group = $WSUS.GetComputerTargetGroups() | Where-Object {$_.Name -like "All Computers"}

    $Computers += $Group.GetTotalSummaryPerComputerTarget() | ForEach-Object {
        $Computer = $WSUS.GetComputerTarget($_.ComputerTargetId)
        [PSCustomObject]@{
            "Computer Name"         = $Computer.FullDomainName
            "IP Address"            = $Computer.IPAddress.ToString()
            "Not Installed"         = $_.NotInstalledCount
            "Failed"                = $_.FailedCount
            "Pending Reboot"        = $_.InstalledPendingRebootCount
            "Operating System"      = $Computer.OSDescription
            "Last Contact"          = $(Get-LocalTime($Computer.LastSyncTime)).ToString("MM/dd/yyyy hh:mm:ss tt")
            "Last Status Report"    = $(Get-LocalTime($Computer.LastReportedStatusTime)).ToString("MM/dd/yyyy hh:mm:ss tt")
        }
    }

    # Define parameters array for the "Not Installed" column
    $paramsNotInstalled = @{
        # Column name
        Column = "Not Installed"
        # Test criteria: Is value greater than or equal to Argument?
        ScriptBlock = {[double]$args[0] -ge [double]$args[1]}
        # CSS attribute to add if ScriptBlock is true
        CSSAttribute = "style"
    }
    $paramsFailed = @{
        # Column name
        Column = "Failed"
        # Test criteria: Is value greater than Argument?
        ScriptBlock = {[double]$args[0] -gt [double]$args[1]}
        # CSS attribute to add if ScriptBlock is true
        CSSAttribute = "style"
    }
    $paramsPendingReboot = @{
        # Column name
        Column = "Pending Reboot"
        # Test criteria: Is value greater than Argument?
        ScriptBlock = {[double]$args[0] -gt [double]$args[1]}
        # CSS attribute to add if ScriptBlock is true
        CSSAttribute = "style"
    }
    $paramsLastReportedStatusTime = @{
        # Column name
        Column = "Last Status Report"
        # Test criteria: Is date older than or equal to Argument?
        ScriptBlock = {[datetime]$args[0] -le [datetime]$args[1]}
        CSSAttribute = "style"
    }

    # Create HTML document
    $HTML = New-HTMLHead -Title "$ComputerName - WSUS Status Report"
    $HTML += "<h3>All Computers ($($Computers.Count))</h3>"

    # Order Columns and create HTML table
    $HTMLTable = $Computers | Sort-Object @{Expression = "Not Installed";Descending = $true},@{Expression = "Computer Name";Descending = $false} -Descending | New-HTMLTable -HTMLDecode -SetAlternating

    # Color Not Installed column red, orange, or yellow if their value is greater than or equal to 60, 40, or 15 respectively
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 15 -CSSAttributeValue "background-color:#f6ed60;" @paramsNotInstalled
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 40 -CSSAttributeValue "background-color:#feb74f;" @paramsNotInstalled
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 60 -CSSAttributeValue "background-color:#ed5e3c;" @paramsNotInstalled

    # Color Failed column if any updates failed
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 0 -CSSAttributeValue "background-color:#88AC76;" @paramsFailed

    # Color Pending Reboot column if any updates are pending reboot
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument 0 -CSSAttributeValue "background-color:#70c3ed;" @paramsPendingReboot

    # Color Last Status Report column if a computer hasn't reported status in more than 7 or 30 days
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument (Get-Date).AddDays(-7) -CSSAttributeValue "background-color:#9a6db0;" @paramsLastReportedStatusTime
    $HTMLTable = Add-HTMLTableColor -HTML $HTMLTable -Argument (Get-Date).AddDays(-30) -CSSAttributeValue "background-color:#c3add1;" @paramsLastReportedStatusTime

    # Add HTML Table to HTML and append legend
    $HTML += $HTMLTable
    $HTML += '<h4>Color Coding:</h4>'
    $HTML += '<ul>'
    $HTML += '<li>Not Installed greater than 60 is <span style="background-color:#ed5e3c;">red</span></li>'
    $HTML += '<li>Not Installed between 40 and 59 is <span style="background-color:#feb74f;">orange</span></li>'
    $HTML += '<li>Not Installed between 15 and 39 is <span style="background-color:#f6ed60;">yellow</span></li>'
    $HTML += '<li>Failed install is <span style="background-color:#8fc975;">green</span></li>'
    $HTML += '<li>Pending Reboot greater than 0 is <span style="background-color:#70c3ed;">blue</span></li>'
    $HTML += '<li>Last Reported Status Time more than 7 days ago is <span style="background-color:#9a6db0;">mauve</span></li>'
    $HTML += '<li>Last Reported Status Time more than 30 days ago is <span style="background-color:#c3add1;">light mauve</span></li>'
    $HTML += '</ul>'
    $HTML = $HTML | Close-HTML -Validate

    if ($SendEmail) {
        # Send HTML to recipient(s)
        try {
            Send-MailMessage –From $FromAddress –To $RecipientAddress –Subject "$ComputerName - WSUS Status Report" –Body $HTML -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort
        } catch {
            throw $_
        }
    } else {
        $HTML
    }
}