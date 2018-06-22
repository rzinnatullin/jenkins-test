param (
    # MSBuild - which configuration to build
    [string]$ConfigurationToBuild = "Debug"
)
	
$ScriptDir = split-path -parent $MyInvocation.MyCommand.Definition
$ScriptDir = (get-item $ScriptDir).parent.FullName


$covConsolePath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\TestAgent\Team Tools\Dynamic Code Coverage Tools\amd64\CodeCoverage.exe"


$targetFiles= (@(Get-ChildItem "$ScriptDir" -Include *.Tests.dll,*.Test.dll,*.Tests.*.dll,*.Test.*.dll  -Recurse -File |
    Where-Object {($_.DirectoryName -inotmatch '\\obj\\' -and ($_.DirectoryName -ilike "*\$ConfigurationToBuild" -or $_.DirectoryName -ilike "*\Test-Output"))}
) | Select -ExpandProperty FullName) 


Write-Host "=> Running Tests " -ForegroundColor DarkCyan
$xmlCoverageFile = "$ScriptDir\CodeCoverage.xml"
Remove-Item $xmlCoverageFile -ErrorAction SilentlyContinue

#$vsConsolePath = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe"
#$vsConsolePath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe"
#$a = New-Object -ComObject Scripting.FileSystemObject
#$f = $a.GetFile($vsConsolePath)
#$vsConsolePath = $f.ShortPath
#& $vsConsolePath  $targetFiles /InIsolation /Platform:X64 /EnableCodeCoverage
$coverageFile = $(get-ChildItem -Path "$ScriptDir\TestResults" -Recurse -Include *coverage)[0]
& $covConsolePath  analyze  /output:$xmlCoverageFile $coverageFile 

Write-Host "=> Ended Test Coverage" -ForegroundColor DarkCyan   

$reportPath = "$ScriptDir\CoverageReports"
$artifactsDir = "$ScriptDir\Artifacts"

Remove-Item  -Recurse $reportPath -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $reportPath
Remove-Item -Recurse $artifactsDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $artifactsDir

$RepGenPath = (Resolve-Path "$ScriptDir\BuildTeamCity\ReportGenerator\tools\ReportGenerator.exe").ToString()

&$RepGenPath -reports:$xmlCoverageFile -targetdir:$reportPath -reportTypes:"HtmlSummary;XMLSummary"

function CreateCoverageArtifactsPackage() {
    Write-Host ("`n`Packing Coverage Artifacts") -ForegroundColor Yellow

    Rename-Item -Path "$reportPath\summary.htm" -NewName "$reportPath\index.html" -ErrorAction SilentlyContinue -Force

    [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null 
    [System.IO.Compression.Zipfile]::CreateFromDirectory("$reportPath","$artifactsDir\coverage.zip") | Out-Null
}

CreateCoverageArtifactsPackage

$xmlFile = Join-Path $reportPath "summary.xml"
[xml]$cn = Get-Content $xmlFile

$CodeCoverageAbsLTotal= $cn.CoverageReport.Summary.Coverablelines
$CodeCoverageAbsLCovered = $cn.CoverageReport.Summary.Coveredlines

"##teamcity[buildStatisticValue key='CodeCoverageAbsLTotal' value='$CodeCoverageAbsLTotal']"
"##teamcity[buildStatisticValue key='CodeCoverageAbsLCovered' value='$CodeCoverageAbsLCovered']"