Param(
	[string] $sourcesRoot = $null
)

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. $scriptDir\funcs.ps1

if ($sourcesRoot -eq '') {
	$sourcesRoot = (Get-Item $scriptDir).Parent.Parent.FullName
}
$testResultDir = Join-Path $sourcesRoot "TestResults"

$assmsToRun = (CollectTestAssemblies)
Write-Host $assmsToRun.Count "assemblies found:"
$assmsToRun

Write-Host 'Clearing test results directory'
Remove-Item -Path $testResultDir -Recurse -ErrorAction:SilentlyContinue
New-Item -ItemType Directory -Force -Path $testResultDir > $null

Write-Host 'Executing unit tests and collecting coverage'
. vstest.console.exe /Logger:trx /Platform:x64 /InIsolation /EnableCodeCoverage $assmsToRun

Write-Host 'Converting .coverage to .coveragexml'
$coverageFile = (Get-ChildItem -File *.coverage -Recurse | Select-Object -first 1).FullName
$coverageXmlFile = Join-Path $testResultDir "vstest.coveragexml"
$coverageConverter = Join-Path $sourcesRoot "BuildJenkins/CoverageConverter/Compiled/CoverageConverter.exe"
Write-Host "Coverage file $coverageFile"
Write-Host "CoverageXml file $coverageXmlFile"
.$coverageConverter $coverageFile $coverageXmlFile