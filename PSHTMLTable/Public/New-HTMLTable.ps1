function New-HTMLTable {
    <#
    .SYNOPSIS
    Creates an HTML table from an input object.

    .DESCRIPTION
    Creates an HTML table from an input object.

    .PARAMETER InputObject
    Object or array of objects as source data for HTML table.

    .PARAMETER Properties
    If specified, limit the table to these specific properties in the order specified.

    .PARAMETER SetAlternating
    Add CSS class = odd or even to each row. True by default. Be sure your CSS includes odd and even definitions.

    Example Output: <tr class="odd">

    .PARAMETER ListTableHeader
    If a list is provided, use this parameter to specify the list header (PowerShell uses * by default).

    .PARAMETER HTMLDecode
    If specified, sends HTML data to HtmlDecode to convert html specific characters like < or > to their character entity

    .PARAMETER ColumnIdPrefix
    Prefixes the id of td elements to the specified value and appends the column number.

    Example Output: <td id="value-0">

    .PARAMETER ColumnClass
    Sets the class of td elements to the specified value.

    Example Output: <td class="value">

    .PARAMETER ColumnClassPrefix
    Prefixes the class of td elements to the specified value and appends the column number.

    Example Output: <td class="value-0">

    .PARAMETER TableAttributes
    Adds any table attributes. Useful if you want to specify any additional CSS values for different tables in the same HTML data stream.

    .PARAMETER RemoveColumnGroup
    If specified, removes the <colgroup><col /></colgroup> tags from output.

    .PARAMETER AddTableTags
    If specified, adds <thead></thead>, <tbody></tbody>, <tfoot /> tags to the output.

    .PARAMETER NestedTable
    If specified, removes the opening <table> and closing </table> tags from the HTML output. This is useful when nesting similar tables within a container table.

    .PARAMETER RowIdPrefix
    Prefixes the id of tr elements to the specified value and appends the row number.

    .PARAMETER RowClass
    Sets the class of tr elements to the specified value.

    .PARAMETER RowClassPrefix
    Prefixes the class of tr elements to the specified value and appends the row number.

    .PARAMETER PrePendHeader
    If specified, adds string to the beginning of the <thead> section. This requires the AddTableTags parameter to inject the value of the PrePendHeader parameter.

    .PARAMETER RemoveHeader
    If specified, removes the th elements within a tr element as well as the enclosing tr element.

    .EXAMPLE
    Sample scripts can be found in the "Examples" folder off of the module's root path

	.NOTES
	Author: brandon said
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory = $false)]
        [String[]]$Properties,

        [Parameter(Mandatory = $false)]
        [Switch]$SetAlternating = $false,

        [Parameter(Mandatory = $false)]
        [Alias('ListTableHead')]
        [String]$ListTableHeader = $null,

        [Parameter(Mandatory = $false)]
        [Switch]$HTMLDecode = $false,

        [Parameter(Mandatory = $false)]
		[String]$ColumnIdPrefix = "",

        [Parameter(Mandatory = $false)]
        [String]$ColumnClass = "",

        [Parameter(Mandatory = $false)]
        [String]$ColumnClassPrefix = "",

        [Parameter(Mandatory = $false)]
		[String]$RowIdPrefix = "",

        [Parameter(Mandatory = $false)]
        [String]$RowClass = "",

        [Parameter(Mandatory = $false)]
        [String]$RowClassPrefix = "",

        [Parameter(Mandatory = $false)]
        [Switch]$RemoveHeader = $false,

        [Parameter(Mandatory = $false)]
        [HashTable]$TableAttributes,

        [Parameter(Mandatory = $false)]
        [Switch]$RemoveColumnGroup,

        [Parameter(Mandatory = $false)]
        [Switch]$AddTableTags,

        [Parameter(Mandatory = $false)]
        [Switch]$NestedTable
    )

    DynamicParam {
        if ($AddTableTags) {
            $Attributes = New-Object -Type System.Management.Automation.ParameterAttribute
            $Attributes.ParameterSetName = "AddTableTags"
            $Attributes.Mandatory = $false
            $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $AttributeCollection.Add($Attributes)

            $DynamicParameter1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("PrependHeader", [String], $AttributeCollection)
            $DynamicParameters = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            $DynamicParameters.Add("PrependHeader", $DynamicParameter1)
            return $DynamicParameters
        }
    }

    begin {
        #Requires -Version 2.0
        Add-Type -AssemblyName System.Xml.Linq | Out-Null
        Add-Type -AssemblyName System.Web | Out-Null
        $Objects = New-Object System.Collections.ArrayList

        $PrependHeader = $PSBoundParameters['PrependHeader']
    }

    process {
        # Loop through inputObject, add to collection. Filter properties if specified.
        foreach ($Object in $InputObject) {
            if ($Properties) {
				[void]$Objects.Add(($Object | Select-Object $Properties))
			} else {
				[void]$Objects.Add($Object)
			}
        }
    }

    end {
        # Convert our data to x(ht)ml
        $Xml = [System.Xml.Linq.XDocument]::Parse("$($Objects | ConvertTo-Html -Fragment)")

        if ($RemoveColumnGroup) {
            $Xml.Element("table").Element("colgroup").Remove()
        }
		foreach ($Table in $($Xml.Descendants("table"))) {
            if ($null -ne $TableAttributes) {
                foreach ($Attribute in $TableAttributes.GetEnumerator()) {
                    $Table.SetAttributeValue($Attribute.Name, $Attribute.Value)
                }
            }
		}
        # Replace * as table head if specified. Note, this should only be done for a list...
        if ($ListTableHeader) {
            $Xml = [System.Xml.Linq.XDocument]::Parse($Xml.Document.ToString().Replace("<th>*</th>","<th>$ListTableHeader</th>"))
        }

        if ($AddTableTags) {
            $Xml.Descendants("tr").Where({$_.Element('th').Value}) | ForEach-Object -Begin {
                    $TableHeader = (New-Object -TypeName 'System.Xml.Linq.XElement' -ArgumentList ([System.Xml.Linq.XName]"thead"))
                    try {
                        $TableHeader.Add([System.Xml.Linq.XElement]::Parse($PrePendHeader))
                    } catch {
                        $TableHeader.Add($PrePendHeader)
                    }
                } -Process {
                    if (-not $RemoveHeader) {
                        $TableHeader.Add($_)
                    }
                $_.Remove()
                } -End {
                    if ($TableHeader.Elements("tr").Count -gt 0) {
                        $Xml.Root.Add($TableHeader)
                    }
            }

            $Xml.Descendants("tr").Where({$_.Element('td').Value}) | ForEach-Object -Begin {
                    $TableBody = (New-Object -TypeName 'System.Xml.Linq.XElement' -ArgumentList ([System.Xml.Linq.XName]"tbody"))
                } -Process {
                    $TableBody.Add($_)
                    $_.Remove()
                } -End {
                    if ($TableBody.Elements("tr").Count -gt 0) {
                        $Xml.Root.Add($TableBody)
                    }
            }
            $Xml.Root.Add((New-Object -TypeName 'System.Xml.Linq.XElement' -ArgumentList ([System.Xml.Linq.XName]"tfoot")))
        } else {
            if ($RemoveHeader) {
                $Xml.Descendants("tr").Where({$_.Element('th').Value}) | ForEach-Object {
                    $_.Remove()
                }
            }
        }

        # Loop through tr elements.
        foreach ($XmlTr in $($Xml.Descendants("tr"))) {
            # Finds rows with th elements
            if ($XmlTr.Where({$_.Element('th').Value})) {
                if ($RowIdPrefix -ne "") {
                    $XmlTr.SetAttributeValue("id", "$RowIdPrefix-$(($XmlTr.NodesBeforeSelf() | Measure-Object).Count)")
                }
                if ($RowClass -ne "") {
                    $XmlTr.SetAttributeValue("class", "$RowClass")
                }
                if ($RowClassPrefix -ne "") {
                    if ($RowClass -ne "") {
                        $XmlTr.SetAttributeValue("class", "$RowClassPrefix-$RowClass")
                    } else {
                        $XmlTr.SetAttributeValue("class", "$RowClassPrefix-$(($XmlTr.NodesBeforeSelf() | Measure-Object).Count)")
                    }
                }

				# Loop through th elements and set CSS id / class values
				foreach ($XmlTh in $($XmlTr.Descendants("th"))) {
					if ($ColumnIdPrefix -ne "") {
                        $XmlTh.SetAttributeValue("id", "$ColumnIdPrefix-$(($XmlTh.NodesBeforeSelf() | Measure-Object).Count)")
					}
					if ($ColumnClass -ne "") {
						$XmlTh.SetAttributeValue("class", "$ColumnClass")
					}
					if ($ColumnClassPrefix -ne "") {
						if ($ColumnClass -ne "") {
							$XmlTh.SetAttributeValue("class", "$ColumnClassPrefix-$ColumnClass")
						} else {
							$XmlTh.SetAttributeValue("class", "$ColumnClassPrefix-$(($XmlTh.NodesBeforeSelf() | Measure-Object).Count)")
						}
					}
				}
            }
            # Finds rows with td elements and set class to even or odd depening on the index value.
            if ($XmlTr.Where({$_.Element('td')})) {
                if ($AddTableTags) {
                    if (($XmlTr.NodesBeforeSelf() | Measure-Object).Count -eq 0) {
                        $XmlTr.SetAttributeValue("class", "first-child")
                    } elseif (($XmlTr.NodesBeforeSelf() | Measure-Object).Count -eq $Xml.Descendants("tr").Where({$_.Element('td').Value}).Count - 1) {
                        $XmlTr.SetAttributeValue("class", "last-child")
                    }
                } else {
                    if ($RemoveColumnGroup -and $RemoveHeader) {
                        if (($XmlTr.NodesBeforeSelf() | Measure-Object).Count -eq 0) {
                            $XmlTr.SetAttributeValue("class", "first-child")
                        }
                        if (($XmlTr.NodesBeforeSelf() | Measure-Object).Count -eq ($Xml.Descendants("tr") | Measure-Object).Count - 1) {
                            $XmlTr.SetAttributeValue("class", "last-child")
                        }
                    } elseif ($RemoveColumnGroup -or $RemoveHeader) {
                        if (($XmlTr.NodesBeforeSelf() | Measure-Object).Count -eq 1) {
                            $XmlTr.SetAttributeValue("class", "first-child")
                        }
                        if (($XmlTr.NodesBeforeSelf() | Measure-Object).Count -eq ($Xml.Descendants("tr").Where({$_.Element('td').Value}) | Measure-Object).Count) {
                            $XmlTr.SetAttributeValue("class", "last-child")
                        }
                    } else {
                        if (($XmlTr.NodesBeforeSelf() | Measure-Object).Count -eq 2) {
                            $XmlTr.SetAttributeValue("class", "first-child")
                        }
                        if (($XmlTr.NodesBeforeSelf() | Measure-Object).Count -eq ($Xml.Descendants("tr") | Measure-Object).Count) {
                            $XmlTr.SetAttributeValue("class", "last-child")
                        }
                    }
                }
                if ($RowIdPrefix -ne "") {
                    $XmlTr.SetAttributeValue("id", "$RowIdPrefix-$(($XmlTr.NodesBeforeSelf() | Measure-Object).Count)")
                }
                if ($RowClass -ne "") {
                    $XmlTr.SetAttributeValue("class", "$RowClass")
                }
                if ($RowClassPrefix -ne "") {
                    if ($RowClass -ne "") {
                        $XmlTr.SetAttributeValue("class", "$RowClassPrefix-$RowClass")
                    } else {
                        $XmlTr.SetAttributeValue("class", "$RowClassPrefix-$(($XmlTr.NodesBeforeSelf() | Measure-Object).Count)")
                    }
                }
                if ($SetAlternating) {
                    if (($XmlTr.NodesBeforeSelf() | Measure-Object).Count % 2 -eq 0) {
                        $XmlTr.SetAttributeValue("class", "even $($XMlTr.Attribute("class").Value)".Trim())
                    }
                    else {
                        $XmlTr.SetAttributeValue("class", "odd $($XMlTr.Attribute("class").Value)".Trim())
                    }
                }
				# Loop through td elements and set CSS id / class values
				foreach ($XmlTd in $($XmlTr.Descendants("td"))) {
                    $XmlTd.SetAttributeValue("valign", "top")
					if ($ColumnIdPrefix -ne "") {
                        $XmlTd.SetAttributeValue("id", "$ColumnIdPrefix-$(($XmlTd.NodesBeforeSelf() | Measure-Object).Count)")
					}
					if ($ColumnClass -ne "") {
						$XmlTd.SetAttributeValue("class", "$ColumnClass")
					}
					if ($ColumnClassPrefix -ne "") {
						if ($ColumnClass -ne "") {
							$XmlTd.SetAttributeValue("class", "$ColumnClassPrefix-$ColumnClass")
						} else {
							$XmlTd.SetAttributeValue("class", "$ColumnClassPrefix-$(($XmlTd.NodesBeforeSelf() | Measure-Object).Count)")
						}
					}
				}
            }
        }
        # Optionally convert <HTML> tags to text to not conflict with XML tags on a per table basis
		# Use -HTMLDecode in Close-HTML if you want to convert entire HTML output
        if ($HTMLDecode) {
            $DecodedXML = [System.Web.HttpUtility]::HtmlDecode($Xml)
        } else {
			$DecodedXML = [System.Xml.Linq.XDocument]::Parse($Xml).Document.ToString()
        }
        if ($NestedTable -and $DecodedXML.StartsWith("<table>`r`n") -and $DecodedXML.EndsWith("`r`n</table>")) {
            $DecodedXML = $DecodedXML.Substring(9, $DecodedXML.Length - 19)
        }
        $DecodedXML
    }
}