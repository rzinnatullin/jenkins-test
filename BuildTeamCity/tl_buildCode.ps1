# Build script for EPMLive

# ### Define user adjustable parameters

param ( 
    # MSBuild - which configuration to build
    [string]$ConfigurationToBuild = "Debug",
    # MSBuild - for which platform to make builds
    [string]$PlatformToBuild = "Any CPU",
    # Tools Version to pass to MSBuild
    [string]$ToolsVersion = "/tv:14.0",
    # user-specific additional command line parameters to pass to MSBuild
    [string]$MsBuildArguments = '/p:visualstudioversion=14.0',
    # should build cleanup be performed before making build
    [switch]$CleanBuild,
	[string]$SDKPath = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.2 Tools",
	[string]$RuleSetsPath = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Team Tools\Static Analysis Tools\Rule Sets",
	[string]$SignToolPath = "C:\Program Files (x86)\Windows Kits\8.0\bin\x64\signtool.exe",
	[switch]$PackageSolutions = $false
	
);
$solutionsToBuild = @("JenkinsTest.sln")
$projectsToBePackaged = @()

# Define script directory
$ScriptDir = split-path -parent $MyInvocation.MyCommand.Definition

$env:EnableNuGetPackageRestore = "true"

# ### Includes 
# look-up of dependent libs
. $ScriptDir\RefsLocate.ps1

# Fix build environment
. $ScriptDir\FixBuildEnv.ps1

# ### Logging helpers
function Log-Section($sectionName) {
	Write-Host "============================================================"
	Write-Host "`t $sectionName"
	Write-Host "============================================================"
}

function Log-SubSection($subsectionName) {
	Write-Host "------------------------------------------------------------"
	Write-Host "`t $subsectionName"
	Write-Host "------------------------------------------------------------"
}

function Log-Message($msg) {
	Write-Host $msg
}

# additional parameters to msbuild
if (Test-Path env:\DF_MSBUILD_BUILD_STATS_OPTS) {
	$DfMsBuildArgs = Get-Childitem env:DF_MSBUILD_BUILD_STATS_OPTS | % { $_.Value }
}

# msbuild executable location
$MSBuildExec = "C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"

# Initialize Sources Directory
$SourcesDirectory = "$ScriptDir\..\"

# Initialize logs directory
$LogsDirectory = "$SourcesDirectory\logs"
if (!(Test-Path -Path $LogsDirectory )){
    New-Item $LogsDirectory -type Directory
}
$loggerArgs = "LogFile=$LogsDirectory\build.log;Verbosity=normal;Encoding=Unicode"
$langversion = "Default"

# Directory for outputs
$OutputDirectory = Join-Path $SourcesDirectory "output"

# Initialize Binaries Directory
$BinariesDirectory = Join-Path $OutputDirectory "binaries"

# Initialize reference paths
$referencePath = "$BinariesDirectory"
$referencePath = $referencePath -replace "\s","%20" 
$referencePath = $referencePath -replace ";","%3B"

# Initialize merged binaries folder
# This directory holds "Single-Folder" build output of all projects
# This is used as a repository to look up dependent DLLs for projects when  
# packaging libs for each project in a separate folder.
# Initialize Libraries Directory
$LibrariesDirectory = "$OutputDirectory\libraries"

# Initialize intermediates directory (PDB)
$IntermediatesDirectory = "$OutputDirectory\intermediate"

### Build preparation steps

# set timezone to UTC - for aline to correctly report on time spent in build tasks
#& tzutil /s "UTC"


Log-Section "Build configuration"
Log-Message "`t Configuration: '$ConfigurationToBuild'"
Log-Message "`t Platform: '$PlatformToBuild'"
Log-Message "`t OutDir: '$BinariesDirectory'"
Log-Message "`t DF MSBuild arguments: '$DfMsBuildArgs'"
Log-Message "`t Additional MSBuild arguments: '$MsBuildArguments'"
Log-Message ""

Log-Section "Downloading Nuget . . ."
$nugetPath = $SourcesDirectory + "\nuget.exe"
Invoke-WebRequest -Uri https://dist.nuget.org/win-x86-commandline/v4.6.2/nuget.exe -OutFile $nugetPath

if (Test-Path $OutputDirectory) {
	Remove-Item -Recurse -Force $OutputDirectory
}
New-Item -ItemType directory -Force -Path $OutputDirectory
New-Item -ItemType directory -Force -Path $BinariesDirectory

If ($CleanBuild) {
	#  clean previous build outputs
	Log-Section "Cleaning build outputs..."
	
	
	
	foreach($solutionToBuild in $solutionsToBuild){
  
		$projAbsPath = Join-Path $SourcesDirectory $solutionToBuild
		$projDir = Split-Path $projAbsPath -parent
		$projName = [System.IO.Path]::GetFileNameWithoutExtension($projAbsPath) 
		
		# Run MSBuild
		Log-SubSection "Cleaning '$projName'..."
			
		& $MSBuildExec "$projAbsPath" `
			/t:Clean `
			/p:SkipInvalidConfigurations=true `
			/p:Configuration="$ConfigurationToBuild" `
			/p:Platform="$PlatformToBuild" `
			/m:4 `
			/p:WarningLevel=0 `
			$ToolsVersion `
			$DfMsBuildArgs `
			$MsBuildArguments
		if ($LastExitCode -ne 0) {
			throw "Project clean-up failed with exit code: $LastExitCode."
		}
	}
}

# ### Make build the same way SolutionPackager does
Log-Section "Starting build..."

if ($PackageSolutions -ne $True)
{
	foreach($solutionToBuild in $solutionsToBuild){
	  
		$projAbsPath = Join-Path $SourcesDirectory $solutionToBuild
		$projDir = Split-Path $projAbsPath -parent
		$projName = [System.IO.Path]::GetFileNameWithoutExtension($projAbsPath) 

		
		
		$outDir = ''
		if ($solutionToBuild.ToLower().EndsWith('.sln') -ne $true)
		{
			$outDir = "/p:OutputPath=""bin"""
		}
		else
		{
			Log-Section "Restoring missing packages . . ."
			& $nugetPath `
			restore `
			$projAbsPath
		}
		
		# ### Make build the same way SolutionPackager does
		Log-SubSection "Building '$projName'..."
			
		# Run MSBuild
		& $MSBuildExec $projAbsPath `
			/p:CodeAnalysisRuleSetDirectories="$RuleSetsPath"  `
			/p:PreBuildEvent= `
			/p:PostBuildEvent= `
			/p:Configuration="$ConfigurationToBuild" `
			/p:Platform="$PlatformToBuild" `
			/p:langversion="$langversion" `
		/p:TargetFrameworkSDKToolsDirectory="$SDKPath"  `
		/p:WarningLevel=0 `
		/p:GenerateSerializationAssemblies="Off" `
		/p:ReferencePath=$referencePath `
		/fl /flp:"$loggerArgs" `
		/m:4 `
		$ToolsVersion `
		$DfMsBuildArgs `
		$MsBuildArguments `
		$outDir
		if ($LastExitCode -ne 0) {
			throw "Project build failed with exit code: $LastExitCode."
		}
	}
}
else
{
	Log-Section "Packaging Projects . . ."
	
	foreach($projectToBePackaged in $projectsToBePackaged){
		
		
		$outDir = "/p:OutputPath=""bin"""
		
		if (($projectToBePackaged.ToLower().EndsWith('.sln') -eq $true) -or ($projectToBePackaged.ToLower().EndsWith('.csproj') -eq $true))
		{
			$collect = $false
			$wording = 'Building'
			$packageParam = ''
			$projectPath = Join-Path $SourcesDirectory $projectToBePackaged
			$projDir = Split-Path $projectPath -parent
		}
		else
		{
			$collect = $true
			$wording = 'Packaging'
			$packageParam = '/t:Package'
			$projectPath = Get-ChildItem -Path ($SourcesDirectory + "\*") -Include ($projectToBePackaged + ".csproj") -Recurse
			$projDir = Split-Path $projectPath -parent
		}
		
		
		Log-SubSection "$Wording '$projectToBePackaged'..."
		Log-SubSection "projectPath: '$projectPath'...."
		
	   & $MSBuildExec $projectPath `
	   $packageParam `
	   /p:PreBuildEvent= `
	   /p:PostBuildEvent= `
	   /p:WarningLevel=0 `
	   /p:Configuration="$ConfigurationToBuild" `
	   /p:Platform="$PlatformToBuild" `
		/p:langversion="$langversion" `
	   /p:GenerateSerializationAssemblies="Off" `
	   /p:ReferencePath=$referencePath `
	   /p:TargetFrameworkSDKToolsDirectory="$SDKPath" `
		/fl /flp:"$loggerArgs" `
		/m:4 `
		$ToolsVersion `
		$DfMsBuildArgs `
		$MsBuildArguments `
		$outDir
		
		if ($LastExitCode -ne 0) {
			throw "Project build failed with exit code: $LastExitCode."
		}
		if ($collect -eq $true)
		{
			$wspFile = Join-Path $projDir "bin" 
			Get-ChildItem -Path ($wspFile + "\*") -Include *.wsp | Copy-Item -Destination $OutputDirectory
		}
	}
	& $SignToolPath sign /f SitrionCodeSign.pfx /p "SitrionizeIt!" /t http://timestamp.verisign.com/scripts/timstamp.dll /v "$SourcesDirectory\NewsGator.Install\bin\Install.exe"
	& $SignToolPath sign /f SitrionCodeSign.pfx /p "SitrionizeIt!" /t http://timestamp.verisign.com/scripts/timstamp.dll /v "$SourcesDirectory\NewsGator.Install.Launcher\bin\Launcher.exe"
	& $SignToolPath sign /f SitrionCodeSign.pfx /p "SitrionizeIt!" /t http://timestamp.verisign.com/scripts/timstamp.dll /v "$SourcesDirectory\NewsGator.Install.Cmdlets\bin\NewsGator.Install.Cmdlets.dll"
	& $SignToolPath sign /f SitrionCodeSign.pfx /p "SitrionizeIt!" /t http://timestamp.verisign.com/scripts/timstamp.dll /v "$SourcesDirectory\NewsGator.Install.Cmdlets\bin\NewsGator.Install.Common.dll"
	& $SignToolPath sign /f SitrionCodeSign.pfx /p "SitrionizeIt!" /t http://timestamp.verisign.com/scripts/timstamp.dll /v "$SourcesDirectory\NewsGator.Install.Cmdlets\bin\NewsGator.Install.Resources.dll"
}


$filter = (Resolve-Path $BinariesDirectory).Path + "\*"
Get-ChildItem -Path ($SourcesDirectory + "\*") -Include NewsGator*.dll,NewsGator*.pdb,Social*.dll,Social*.pdb,SharePoint.Ajax.Library.dll,SharePoint.Ajax.Library.pdb -Exclude *.Resources.resources.dll -Recurse | where-object{$_.fullname -notlike $filter} | Copy-Item -Destination $BinariesDirectory -Force		
	


