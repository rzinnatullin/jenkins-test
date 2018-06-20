<#

 Module with functions to locate dependent libraries for VS project files.
 
#>

<#
Returns GAC path
#>
function Get-GAC-Path {
	if ($PSVersionTable['CLRVersion'].ToString(1) -lt 4) {
		return Join-Path $env:windir 'assembly'
	}
	else {
		return Join-Path $env:windir 'Microsoft.NET\assembly'
	}
}

<#
Get a list of projects in a given solution file.

Not used.
#>
function Get-Solution-Projects($solutionFilepath) {
    Get-Content $solutionFilepath |
      Select-String 'Project\(' |
      ForEach-Object {
	  $projectParts = $_ -Split '[,=]' | ForEach-Object { $_.Trim('[ "{}]') };
	  New-Object PSObject -Property @{
              Name = $projectParts[1];
              File = $projectParts[2];
              Guid = $projectParts[3];
		}
      }
}

function Format-Include-Property($includePropString) {
	$values = $includePropString -Split '='
	if ($values.Length -eq 2) {
		return @{"Name" = $values[0].Trim(); "Value" = $values[1].Trim()}
	} else {
		throw "Invalid include property provided: '$includePropString'"
	}
}

function Format-Include-Attribute($includeAttr) {
	if (($includeAttr -eq $null) -or ($includeAttr -eq "")) {
		return $null
	}
	
	$includeProps = $includeAttr -Split ','
	Write-Debug "Include properties: '$includeProps'"
	$includeDict = @{"Name" = $includeProps[0]}
	if (($includeDict["Name"] -eq $null) -or ($includeDict["Name"] -eq "")) {
		throw "Bad include attribute - no lib name provided"
	}
	if ($includeProps.Length -eq 1) {
		# simple include, probably system lib, just return its name 
		return $includeDict
	}
	
	# extract include properties
	$includeProps = $includeProps[1..($includeProps.Length-1)]
	ForEach ($propString in $includeProps) {
		#Write-Debug "Processing include property: '$propString'"
		$prop = Format-Include-Property $propString		
		$includeDict[$prop["Name"]] = $prop["Value"]
	}
	
	return $includeDict
}

<# 
Formats inputs XML <Reference> element as a map for easier operation on it.
#>
function Format-Reference-Element($ref) {
	$refDetails = Format-Include-Attribute $ref.Include
	if ($refDetails -eq $null) {
		return $null
	}	
	if ($ref.HintPath -ne $null) {
		$refDetails["HintPath"] = $ref.HintPath.Trim()
	}
	return $refDetails
}

<#
Builds a list of libs for a given VS project file.
#>
function Get-Project-Lib-List($projectFilepath) {
	$projectName = [System.IO.Path]::GetFileName($projectFilepath)
	[xml]$xmldata = Get-Content($projectFilepath)

	$references = $xmldata.Project.ItemGroup.Reference
	$refsDetails = $references | % { Format-Reference-Element $_ }
	$refsDetails = $refsDetails | ? { $_ -ne $null }
	
	return $refsDetails
}


function Locate-GAC-Lib($libName) {
	$gacPath = Get-GAC-Path
	
	Write-Debug "Trying to find $libName in GAC..."
	$libPath = $null
	$libPath = Get-ChildItem -Path $gacPath -Filter "$libName" -File -Recurse | % { $_.FullName }
	if ($libPath -ne $null) {
		if ($libPath -is [system.array]) {
			# KLUDGE: bad way to locate a lib - just picking up first match
			# TODO: re-do with version, build arch and publickey checks
			$libPath = $libPath[0]
		}
	}
	
	if ($libPath -eq $null) {
		return $null
	} else {
		Write-Debug "Found: $libPath"
		return $libPath
	}
}

<#
Function tries to locate lib in project-specific dirs. The dir list 
where lib look-up should be performed is configured in $ProjectLibsList global property.
#>
function Locate-Project-Lib($libName, $dirsList) {
	Write-Debug "Trying to locate project lib: '$libName'..."
	ForEach ($d in $dirsList) {
		Write-Debug "Looking in '$d'"
		$libPath = Get-ChildItem -Path $d -Filter "${libName}" -File -Recurse | % { $_.FullName }
		if ($libPath -eq $null) {
			Write-Debug "Have not found '$libName' under this location"
		} else {
			if ($libPath -is [system.array]) {
				# KLUDGE: bad way to locate a lib - just picking up first match
				# TODO: re-do with version, build arch and publickey checks
				$libPath = $libPath[0]
			}
			return $libPath
		}
	}
	
	# not found the $libName in project's dir list
	Write-Debug "Have not found this lib in project-specific locations."
	return $null
}

<#
Tries to locate given library on a VM.

At first search in GAC is made, then it tries to find lib 
in project-specific dirs.
#>
function Locate-Lib($libInfo, $productLibDirs = @()) {
	if ($libInfo["Name"] -eq "") {
		throw "Library name to locate is required! Cannot continue."
	}
	
	$libPath = $null
	$libName = $libInfo["Name"] + ".dll"
	$libPath = Locate-GAC-Lib $libName
	if ($libPath -eq $null) {
		$libPath = Locate-Project-Lib $libName $productLibDirs
	}
	
	if ($libPath -eq $null) {
		Write-Warning "Cannot find library: '$libName'"
		return $null
	} else {
		Write-Host "Found library: '$libPath'"
		return $libPath
	}
}

function Copy-Project-Libs($projectFilepath, $destDir, $productLibDirs = @()) {
	New-Item -ItemType directory -Path $destDir -Force
	ForEach ($libItem in Get-Project-Lib-List $projectFilepath ) {
		$libPath = Locate-Lib $libItem $productLibDirs
		if ($libPath -ne $null) {
			Copy-Item $libPath -Destination $destDir -Force
		}
	}
}

function Copy-Libs($projectsList, $destDir, $productLibDirs = @()) {
	ForEach ($proj in $projectsList) {
		Write-Host "`nCopying dependent libraries for '$proj'...`n"
		
		$projectName = [System.IO.Path]::GetFileNameWithoutExtension("$proj")
		Copy-Project-Libs $proj "$destDir\$projectName" $productLibDirs
		
		Write-Host "`nFinished copying dependent libs.`n"
	}
}