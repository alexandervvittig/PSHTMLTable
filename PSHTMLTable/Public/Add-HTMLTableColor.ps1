function Add-HTMLTableColor {
    <#
    .SYNOPSIS
    Colorize cells or rows in an HTML table, or add other inline CSS.

    .DESCRIPTION
    Colorize cells or rows in an HTML table, or add other inline CSS.

    .PARAMETER HTML
    HTML string to analyze.

    .PARAMETER Column
    If specified, the column you want to analyze. This is case sensitive.

    .PARAMETER SecondColumn
    If specified, the column you want to use as a reference column to analyze against Column. This is case sensitive.

    .PARAMETER Argument
    If Column is specified, argument is used as a comparison value for Column.

    .PARAMETER ScriptBlock
    If Column is specified, used to evaluate whether to add the CSS or not. If the ScriptBlock returns $true, the specified CSSAtribute and CSSAtributeValue will be added.

    $args[0] is the existing cell value
    $args[1] is the argument parameter

    Examples:
        {[string]$args[0] -eq [string]$args[1]} # specified Column value equals Argument. This is the default.
        {[double]$args[0] -gt [double]$args[1]} # specified Column value is greater than Argument.

    .PARAMETER  CSSAttribute
    If Column is specified, the attribute to change if the ScriptBlock returns true. Default: style

    .PARAMETER  CSSAttributeValue
    If Column is specified, the attribute value to change if the ScriptBlock returns true.

    Example: "background-color:#FFCC99;"

    .PARAMETER HighlightRow
    If specified, and Column is specified, and the ScriptsBlock returns true, CSSAttribute and CSSAttributeValue is applied to the entire row, not just the cell.

    .PARAMETER HighlightReferenceCell
    If specified, and Column and SecondColumn are specified, and the ScriptsBlock returns true, CSSAttribute and CSSAttributeValue is applied to both Column and SecondColumn cells.

	.PARAMETER ApplyFormat
    If specified, format the cell data post ScriptBlock evaluation. This should be added to the last evaluation as it will change the data and possibly make further evaluations fail.

	.PARAMETER StringFormat
    If specified, uses the -f parameter to format the cell data. For example, "{0:n2)" will format data as 2 decimal digits, 89.2349862972638476 will become 89.23.

	.PARAMETER CommandFormat
    If specified, passes a locally defined command to be used to format the cell data.

	Examples:
		${function:Format-Bytes}

		Where Format-Bytes is defined as:

		function Format-Bytes ($Bytes) {
			# Do Stuff
			return $results
		}

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
        [String]$Column = "Name",

        [Parameter(Mandatory = $false)]
        [String]$SecondColumn = "",

        [Parameter(Mandatory = $false)]
        $Argument = 0,

        [Parameter(Mandatory = $false)]
        [ScriptBlock]$ScriptBlock = {[string]$args[0] -eq [string]$args[1]},

        [Parameter(Mandatory = $false)]
		[Alias('Attr')]
        [String]$CSSAttribute = "style",

        [Parameter(Mandatory = $false)]
		[Alias('AttrValue')]
		[String]$CSSAttributeValue,

        [Parameter(Mandatory = $false)]
		[Alias('WholeRow')]
		[Switch]$HighlightRow = $false,

        [Parameter(Mandatory = $false)]
        [Switch]$HighlightReferenceCell = $false,

        [Parameter(Mandatory = $false)]
        [Switch]$ApplyFormat = $false,

        [Parameter(Mandatory = $false)]
        [String]$StringFormat = "",

        [Parameter(Mandatory = $false)]
		[ScriptBlock]$CommandFormat = {}
	)

	begin {
		#Requires -Version 2.0
		Add-Type -AssemblyName System.Xml.Linq | Out-Null
	}

	process {
		# Convert our data to x(ht)ml
		if ($HTML.StartsWith("<table>`r`n") -and $HTML.EndsWith("`r`n</table>")) {
			$Xml = [System.Xml.Linq.XDocument]::Parse($HTML)
		} else {
			$NestedTable = $true
			$HTML = "<table>$HTML</table>"
			$Xml = [System.Xml.Linq.XDocument]::Parse($HTML)
		}

		# Get Column index. Try th with no namespace first, then default namespace provided by ConvertTo-Html.
		try {
			$ColumnIndex = (($Xml.Descendants("th") | Where-Object { $_.Value -eq $Column }).NodesBeforeSelf() | Measure-Object).Count
		}
		catch {
			try {
				$ColumnIndex = (($Xml.Descendants("{http://www.w3.org/1999/xhtml}th") | Where-Object { $_.Value -eq $Column }).NodesBeforeSelf() | Measure-Object).Count
			}
			catch {
				throw "Error: Invalid Column Name ($Column)."
			}
		}
		# Get SecondColumn index. Try th with no namespace first, then default namespace provided by ConvertTo-Html.
		if ($SecondColumn -ne "") {
			try {
				$SecondColumnIndex = (($Xml.Descendants("th") | Where-Object { $_.Value -eq $SecondColumn }).NodesBeforeSelf() | Measure-Object).Count
			}
			catch {
				try {
					$SecondColumnIndex = (($Xml.Descendants("{http://www.w3.org/1999/xhtml}th") | Where-Object { $_.Value -eq $SecondColumn }).NodesBeforeSelf() | Measure-Object).Count
				}
				catch {
					throw "Error: Invalid Column Name ($SecondColumn)."
				}
			}
		}
		# If we found the specified column index and no second column exists
		if (($ColumnIndex -as [double] -ge 0) -and ($SecondColumnIndex -as [double] -eq 0)) {
			# Take action on td descendants matching that index
			switch ($Xml.Descendants("td") | Where-Object {($_.NodesBeforeSelf() | Measure-Object).Count -eq $ColumnIndex}) {
				# Run the script block. If it is true, set attributes
				{Invoke-Command $ScriptBlock -ArgumentList @($_.Value, $Argument)} {
					# Mark the whole row or just the column
					if ($HighlightRow)  {
						$_.Parent.SetAttributeValue($CSSAttribute, $CSSAttributeValue)
					} else {
						$_.SetAttributeValue($CSSAttribute, $CSSAttributeValue)
						if ($ApplyFormat) {
							if ($StringFormat -ne "") {
								$_.Value = $StringFormat -f $([double]$_.Value)
							} elseif ($CommandFormat -ne "") {
								$_.Value = Invoke-Command -ScriptBlock $CommandFormat -ArgumentList $_.Value
							}
						}
					}
				}
				default {
					if ($ApplyFormat) {
						if (-not ($StringFormat -ne "" -and $CommandFormat.Ast.Extent.Text -ne '{}')) {
							if ($StringFormat -ne "") {
								$_.Value = $StringFormat -f $([double]$_.Value)
							} elseif ($CommandFormat -ne "") {
								$_.Value = Invoke-Command -ScriptBlock $CommandFormat -ArgumentList $_.Value
							}
						} else {
							throw "Error: Multiple format methods specified on Column ($Column)."
						}
					}
				}
			}
		# If we found both column and second column indexes
		} else {
			# Iterate each table row
			foreach ($XmlTr in $($Xml.Descendants("tr"))) {
				# Take action on td descendants matching column index
				switch ($XmlTr.Descendants("td") | Where-Object {($_.NodesBeforeSelf() | Measure-Object).Count -eq $ColumnIndex}) {
					# Run the script block. If it is true, set attributes
					{$(Invoke-Command $ScriptBlock -ArgumentList @(@($($XmlTr.Descendants("td")))[$ColumnIndex].Value, @($($XmlTr.Descendants("td")))[$SecondColumnIndex].Value))} {
						# Mark the whole row or just the column
						if ($HighlightRow)  {
							$_.Parent.SetAttributeValue($CSSAttribute, $CSSAttributeValue)
							# Remove attribute if previously set by another condition
							$_.SetAttributeValue($CSSAttribute, $null)
						} else {
							$_.SetAttributeValue($CSSAttribute, $CSSAttributeValue)
							if ($HighlightReferenceCell) {
								@($($XmlTr.Descendants("td")))[$SecondColumnIndex].SetAttributeValue($CSSAttribute, $CSSAttributeValue)
							}
						}
					}
				}
			}
		}
		# Return the XML
		$XmlString = $Xml.Document.ToString()
		if ($NestedTable -and $XmlString.StartsWith("<table>`r`n") -and $XmlString.EndsWith("`r`n</table>")) {
			$XmlString.Substring(11, $XmlString.Length - 21)
		} else {
			$XmlString
		}
	}
}
