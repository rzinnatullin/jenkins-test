$dllsInBin = Get-ChildItem -Filter "*.dll" -Recurse | where{$_.FullName -match "\\bin\\"}
$filters = @("*test.dll", "*tests.dll", "*.test.*.dll", "*.tests.*.dll")
$assmsToRun = New-Object System.Collections.ArrayList

foreach ($fi in $filters) {
  $assmsToRun.AddRange(($dllsInBin | where{$_.Name -like $fi}))
}
$assmsToRun = ($assmsToRun | Select -ExpandProperty FullName)
Write-Host $assmsToRun.Count " assemblies found:"
$assmsToRun

Write-Host 'Executing unit tests'
."c:\Program Files (x86)\Microsoft Visual Studio\Preview\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe" $assmsToRun /Settings:Test.runsettings /Logger:trx /Platform:x64 /InIsolation /EnableCodeCoverage