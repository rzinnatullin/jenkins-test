function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $folder = New-Item -ItemType Directory -Path (Join-Path $parent $name)
    return $folder.FullName
}

function DownloadAndRegisterAsmInGac ([string] $asmDownloadUrl, [string] $asmName)
{
    Write-Host "Downloading and registering '$asmName' in GAC"
    $tempDir = New-TemporaryDirectory
    $asmFileTempPath = Join-Path $tempDir $asmName
    Invoke-WebRequest $asmDownloadUrl -OutFile $asmFileTempPath
    . $gacUtil /i $asmFileTempPath
    Remove-Item -Path $asmFileTempPath -Recurse -Force
}