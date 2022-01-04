function ConvertTo-PropertyValue {
    <#
    .SYNOPSIS
    Convert an object with various properties into an array of property, value pairs.

    .DESCRIPTION
    Convert an object with various properties into an array of property, value pairs.

    If you output reports or other formats where a table with one long row is poorly formatted, this is a quick way to create a table of property value pairs.

    .PARAMETER InputObject
    A single object to convert to an array of property value pairs.

    .PARAMETER PropertyHeader
    Header for the left column. Default: Property

    .PARAMETER ValueHeader
    Header for the right column. Default: Value

    .PARAMETER MemberType
    Return only object members of this membertype.  Default: Property, NoteProperty, ScriptProperty

    .EXAMPLE
    Sample scripts can be found in the "Examples" folder off of the module's root path

	.NOTES
	Author: brandon said
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromRemainingArguments = $false)]
        [PSObject]$InputObject,

        [ValidateSet("AliasProperty", "CodeProperty", "Property", "NoteProperty", "ScriptProperty", "Properties", "PropertySet", "Method", "CodeMethod", "ScriptMethod", "Methods", "ParameterizedProperty", "MemberSet", "Event", "Dynamic", "All")]
        [String[]]$MemberType = @( "NoteProperty", "Property", "ScriptProperty" ),

        [Alias('LeftHeader')]
        [String]$PropertyHeader = "Property",

        [Alias('RightHeader')]
        [String]$ValueHeader = "Value"
    )

    begin {
        # Init array to dump all objects into
        $AllObjects = New-Object System.Collections.ArrayList
    }
    process {
        # If we're taking from pipeline and get more than one object, this will build up an array
        [void]$AllObjects.Add($InputObject)
    }
    end {
        # Use only the first object provided
        $AllObjects = $AllObjects[0]

        # Get properties. Filter by memberType.
        $Properties = $AllObjects.PSObject.Properties | Where-Object {$MemberType -contains $_.MemberType} | Select-Object -ExpandProperty Name

        # Loop through properties and display property value pairs
        foreach ($Property in $Properties){
            # Create object with property and value
            $Object = "" | Select-Object $PropertyHeader, $ValueHeader
            $Object.$PropertyHeader = $Property.Replace('"',"")
            $Object.$ValueHeader = try {$AllObjects | Select-Object -ExpandProperty $Object.$PropertyHeader -ErrorAction SilentlyContinue} catch {$null}
            $Object
        }
    }
}