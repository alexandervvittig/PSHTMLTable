#https://community.spiceworks.com/topic/2308332-powershell-send-email
#Requires -Modules @{ModuleName="PSHTMLTable";ModuleVersion="1.0.0.0"}

[CmdletBinding()]
param (
    [switch]$SendEmail,
    [string]$FromAddress = "First.Last@domain.com",
    [string]$RecipientAddress = "recipient@domain.com",
    [string]$SMTPServer = "",
    [uint16]$PasswordAge = 90,
    [uint16]$LastLogonAge = 14
)

begin {
    Import-Module ActiveDirectory
    function ConvertTo-UserObject ($User) {
        if ($null -eq $_.LastLogonDate -or $_.LastLogonDate -le (Get-Date).AddDays($LastLogonAge * -1).Date) {

            [PSCustomObject]@{
                "User"          =   "$($_.Name) ($($User.SamAccountName))"
                "Department"    =   $User.Department
                "Title"         =   $User.Title
                "Description"   =   $User.Description
                "Manager"       =   if ($PSVersionTable.PSVersion.Major -gt 5) {
                                        (($null -eq $User.Manager) ? "" : (Get-ADUser -Identity $_.Manager).Name)
                                    } else {
                                        if ($null -ne $User.Manager) {
                                            ""
                                        } else {
                                            (Get-ADUser -Identity $_.Manager).Name
                                        }
                                    }
                "Last Login"    =   if ($PSVersionTable.PSVersion.Major -gt 5) {
                                        (($null -eq $User.LastLogonDate) ? "Never" : $User.LastLogonDate.ToString("G"))
                                    } else {
                                        if ($null -ne $User.LastLogonDate) {
                                            "Never"
                                        } else {
                                            $User.LastLogonDate.ToString("G")
                                        }
                                    }
            }
        }
    }
    function ConvertTo-CustomHTML ($Array, $TableHeader) {
        $HTML = New-HTMLHead
        if ($Array.Count -gt 0) {
            # Create HTML document
            $HTML = New-HTMLHead
            $HTML += "<h3>$TableHeader</h3>"

            # Create HTML Table
            $HTMLTable = $Array | Sort-Object User | New-HTMLTable -HTMLDecode -SetAlternating

            # Add HTML Table to HTML
            $HTML += $HTMLTable
            $HTML = $HTML | Close-HTML -Validate
        }
        $HTML
    }
    $CutOffDate = (Get-Date).AddDays($PasswordAge * -1).Date
}

process {
    $Users = Get-ADUser -Filter "(Enabled -eq '$true') -and (PasswordLastSet -le '$CutOffDate')" -Properties PasswordLastSet, LastLogonDate, manager, department, title, description, mail

    $Users | Sort-Object Manager, Name | Group-Object Manager | ForEach-Object {
        if ($_.Name -ne "") {
            Write-Information "Analyzing employees for $((Get-ADUser -Identity $_.Name).Name)" -InformationAction Continue
            $InactiveUsers = @()
            $InactiveUsers += $_.Group | ForEach-Object {
                ConvertTo-UserObject -User $_
            }
            if ($InactiveUsers.Count -gt 0) {
                if ($SendEmail) {
                    try {
                        $HTML = ConvertTo-CustomHTML -Array $InactiveUsers -TableHeader "Inactive Users - ($($InactiveUsers.Count))"
                        Send-MailMessage -From $FromAddress -To $((Get-ADUser -Identity $_.Name -Properties mail).Mail) -Subject "Inactive User Report" -SmtpServer $SMTPServer -Body $HTML -BodyAsHtml
                    } catch {
                        throw $_
                    }
                } else {
                    $InactiveUsers | Format-Table -AutoSize
                }
            }
        } else {
            Write-Information "Analyzing employees without a Manager" -InformationAction Continue
            $InactiveUsers = @()
            $InactiveUsers += $_.Group | ForEach-Object {
                ConvertTo-UserObject -User $_
            }
            if ($InactiveUsers.Count -gt 0) {
                if ($SendEmail) {
                    try {
                        $HTML = ConvertTo-CustomHTML -Array $InactiveUsers -TableHeader "Inactive Users w/o a Manager - ($($InactiveUsers.Count))"
                        Send-MailMessage -From $FromAddress -To $RecipientAddress -Subject "Inactive User Report" -SmtpServer $SMTPServer -Body $HTML -BodyAsHtml
                    } catch {
                        throw $_
                    }
                } else {
                    $InactiveUsers | Format-Table -AutoSize
                }
            }
        }
    }
}