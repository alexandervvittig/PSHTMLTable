function Close-HTML {
    <#
    .SYNOPSIS
    Closes </body> and </html> entities to complete the HTML data stream.

    .DESCRIPTION
    Closes </body> and </html> entities to complete the HTML data stream.

    .PARAMETER HTML
    HTML string to analyze.

    .PARAMETER HTMLDecode
    If specified, sends HTML data to HtmlDecode to convert html specific characters like < or > to their character entity

    .PARAMETER Validate
    If specified, HTML data is parsed to look for malformed data. If HTML data is properly formed, results are indented accordlingly

    .EXAMPLE
    Sample scripts can be found in the "Examples" folder off of the module's root path

	.NOTES
	Author: brandon said
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]$HTML,

        [Parameter(Mandatory = $false)]
        [Alias('Decode')]
        [Switch]$HTMLDecode,

        [Parameter(Mandatory = $false)]
        [Alias('Format')]
        [Switch]$Validate
    )

    begin {
        #Requires -Version 2.0
        Add-Type -AssemblyName System.Xml.Linq | Out-Null
    }

    process {
        if ($HTMLDecode) {
            Add-Type -AssemblyName System.Web
            $HTML = [System.Web.HttpUtility]::HtmlDecode($HTML)
        }
        if ($Validate) {
            try {
                [System.Xml.Linq.XDocument]::Parse($HTML + "</body></html>").ToString()
            } catch {
                throw $_
            }
        } else {
            $HTML + "</body></html>"
        }
    }
}