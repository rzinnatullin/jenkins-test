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
."C:\Program Files (x86)\Microsoft Visual Studio\2017\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe" /Logger:trx /Platform:x64 /InIsolation /EnableCodeCoverage $assmsToRun