# Fixes of build environment

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. $scriptDir\Utils.ps1

$gacUtil = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\gacutil.exe"

# Make sure Microsoft.QualityTools.Testing.Fakes.ImportAfter.targets is in place

$fakesTargetsFileName = "Microsoft.QualityTools.Testing.Fakes.ImportAfter.targets"
$fakesTargetsFolder = "C:\Program Files (x86)\MSBuild\14.0\Microsoft.Common.Targets\ImportAfter"
$fakesTargetsFullFileName = Join-Path $fakesTargetsFolder $fakesTargetsFileName
$fakesTargetsDownloadUrl = "https://s3.amazonaws.com/skyvera-build-repo/Social+Deployment+Packages/Microsoft.QualityTools.Testing.Fakes.ImportAfter.targets"

if (!(Test-Path $fakesTargetsFullFileName))
{
    Write-Host "$fakesTargetsFileName is not in place"
    if (!(Test-Path $fakesTargetsFolder))
    {
        New-Item $fakesTargetsFolder -ItemType Directory > $null
    }

    Write-Host "Downloading $fakesTargetsFileName to '$fakesTargetsFolder'"
    Invoke-WebRequest $fakesTargetsDownloadUrl -OutFile $fakesTargetsFullFileName
}

# Make sure Microsoft.Web.Design.Server.dll v14 is in GAC
$msWebDesignServer14FileName = "Microsoft.Web.Design.Server.dll"
$msWebDesignServer14DownloadUrl = "https://s3.amazonaws.com/skyvera-build-repo/Social+Deployment+Packages/Microsoft.Web.Design.Server.dll-14"
DownloadAndRegisterAsmInGac $msWebDesignServer14DownloadUrl $msWebDesignServer14FileName 

# Make sure Microsoft.SharePoint.Library.dll v14 is in GAC
$msSPLibrary14FileName = "Microsoft.SharePoint.Library.dll"
$msSPLibrary14DownloadUrl = "https://s3.amazonaws.com/skyvera-build-repo/Social+Deployment+Packages/Microsoft.SharePoint.Library.dll-14"
DownloadAndRegisterAsmInGac $msSPLibrary14DownloadUrl $msSPLibrary14FileName 