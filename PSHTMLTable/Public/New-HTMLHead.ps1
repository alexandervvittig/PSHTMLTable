function New-HTMLHead {
    <#
    .SYNOPSIS
    Creates new HTML data stream with header and body entities.

    .DESCRIPTION
    Creates new HTML data stream with header and body entities.

    .PARAMETER CSSFile
    If specified, contents of this file are embedded into the HTML data stream via <style></style> tags

    Note: If you include your own CSS, you will need to include "odd" and "even" class names. If SetAlternating is set to true and they don't exist, there will be no visible difference when viewing HTML via email or browser.

    .PARAMETER Style
    If specified, the value is embedded into the HTML data stream via <style></style> tags

    Note: If you specify your own CSS, you will need to include "odd" and "even" class names. If SetAlternating is set to true and they don't exist, there will be no visible difference when viewing HTML via email or browser.

    Example:
    $MyCSS = @'
        tr.odd {
			background-color:#ffffff;
		}
        tr.even {
			background-color:#dddddd;
		}
    '@
    New-HTMLHead -Style $MyCSS

    .PARAMETER Theme
    If specified, uses the CSS file from within the Themes folder off of the module root folder.

    .PARAMETER AppendCSS
    If specified, adds additional CSS to the currently selected theme.

    .PARAMETER Title
    If specified, title to add in the head section.

    .EXAMPLE
    Sample scripts can be found in the "Examples" folder off of the module's root path.

	.NOTES
	Author: brandon said
    #>
    [CmdletBinding(DefaultParameterSetName = "String")]
    param (
        [Parameter(ParameterSetName = 'File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [Alias('CSSPath')]
		$CSSFile = $null,
        
        [Parameter(ParameterSetName = 'Theme')]
        [ValidateScript({Test-Path "$(Split-Path $PSScriptRoot)\Themes\$_.css"})]
		$Theme = $null,

        [Parameter(ParameterSetName = 'String')]
        [String]$Style = "
            <style>
                body {
                    color: #333333;
                    font-family: Calibri,Tahoma,Arial,Verdana;
                    font-size: 11pt;
                }
                h3 {
                    margin-bottom: 5px;
                }
                h4 {
                    margin-top: 10px !important;
                    margin-bottom: 10px !important;
                }
                table {
                    border-collapse: collapse;
                }
                th {
                    text-align: center;
                    font-weight: bold;
                    color: #eeeeee;
                    background-color: #333333;
                    border: 1px solid black;
                    padding: 5px;
                    white-space: nowrap;
                }
                th.align-left {
                    text-align: left;
                    padding: 5px 10px 5px 10px;
                }
                td {
                    padding: 5px 10px 5px 10px;
                    border: 1px solid black;
                    text-align: center;
                    white-space: nowrap;
                }
                td.align-left {
                    text-align: left;
                }
                ul {
                    margin-top: 5px;
                }
                .odd {
                    background-color:#ffffff;
                }
                .even {
                    background-color:#dddddd;
                }
            </style>",
        [Parameter(ParameterSetName = 'Theme')]
        [String]$AppendCSS = "",
        [String]$Title = $null
    )

    # Add CSS from file if specified
    if ($CSSFile) {
		$Style = "$(Get-Content $CSSFile | Out-String)"
	}
    # Add CSS Theme File
    if ($Theme) {
		$Style = Get-Content "$(Split-Path $PSScriptRoot)\Themes\$Theme.css" | Out-String
        if ($AppendCSS) {
            #$Style = $($Style.Replace("<style>`r`n","")).Replace("</style>`r`n",$AppendCSS)
            $Style = "$Style`r`n$AppendCSS"
        }
	}
    if ($Style.Contains("<style>") -ne $true) {
        $Style = "<style>`r`n" + $Style
    }
    if ($Style.Contains("</style>") -ne $true) {
        $Style = $Style + "`r`n</style>"
    }

    @"
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            $(if ($Title) {"<title>$Title</title>"})
                $Style
        </head>
        <body>
"@
}