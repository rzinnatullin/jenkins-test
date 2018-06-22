$dllsInBin = Get-ChildItem -Filter "*.dll" -Recurse | where{$_.FullName -match "\\bin\\"}
$filters = @("*test.dll", "*tests.dll", "*.test.*.dll", "*.tests.*.dll")
$assmsToRun = New-Object System.Collections.Generic.HashSet[object]

foreach ($fi in $filters) {
  foreach ($dll in ($dllsInBin | where{$_.Name -like $fi})) {
    $assmsToRun.Add($dll)
  }
}
$assmsToRun = ($assmsToRun | Select -ExpandProperty FullName)
Write-Host $assmsToRun.Count " assemblies found:"
$assmsToRun

Write-Host 'Executing unit tests'
."C:\Program Files (x86)\Microsoft Visual Studio\2017\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe" $assmsToRun /Settings:Test.runsettings /Logger:trx /Platform:x64 /InIsolation /EnableCodeCoverage
#."C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe" $assmsToRun /Settings:Test.runsettings /Logger:trx /Platform:x64 /InIsolation /EnableCodeCoverage
