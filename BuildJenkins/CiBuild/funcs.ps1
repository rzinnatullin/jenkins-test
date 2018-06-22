function CollectTestAssemblies()
{
  $dllsInBin = Get-ChildItem -Filter "*.dll" -Recurse | where{$_.FullName -match "\\bin\\"}
  $filters = @("*test.dll", "*tests.dll", "*.test.*.dll", "*.tests.*.dll")
  $assmsToRun2 = New-Object System.Collections.Generic.HashSet[object]

  foreach ($fi in $filters) {
    foreach ($dll in ($dllsInBin | where{$_.Name -like $fi})) {
      $assmsToRun2.Add($dll.FullName) > $null
    }
  }
  return $assmsToRun2
}