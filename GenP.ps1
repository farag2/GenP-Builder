# https://wiki.dbzer0.com/genp-guides/guide/#latest
# https://wiki.dbzer0.com/genp-guides/guide#download-directory
# https://wiki.dbzer0.com/genp-guides/guide/#genp-modgood

New-Item -Path GenP_SOURCE -ItemType Directory -Force

Write-Verbose -Message "Downloading Dependencies" -Verbose

# https://www.autoitscript.com/site/autoit/downloads/
winget install --id AutoIt.AutoIt --accept-source-agreements --force
# https://www.autoitscript.com/site/autoit-script-editor/downloads/
winget install --id AutoIt.SciTE4AutoIt3 --accept-source-agreements --force

Write-Verbose -Message "Downloading GenP_SOURCE.zip" -Verbose

# https://wiki.dbzer0.com/genp-guides/guide#download-directory
$Parameters = @{
	Uri             = "https://bafybeihxmdurqt2ve6pcgk427jovyvxpdduh422lqeridvscgnlxg3mbeu.ipfs.dweb.link/?filename=GenP_4.2.1_SOURCE.zip&download=true"
	OutFile         = "GenP_SOURCE.zip"
	UseBasicParsing = $true
	Verbose         = $true
}
Invoke-WebRequest @Parameters

Write-Verbose -Message "Extracting archives" -Verbose

& "$env:SystemRoot\System32\tar.exe" -xvf "GenP_SOURCE.zip" -C "GenP_SOURCE" --strip-components=2

Write-Verbose -Message Building -Verbose

# Remove first 19 strings of AutoIt3Wrapper_GUI to insert new directives within console ones
(Get-Content -Path "GenP_SOURCE\GenP\GenP-v$($env:Version).au3" -Encoding utf8NoBOM -Force) | Select-Object -Skip 19 | Set-Content -Path "GenP_SOURCE\GenP\GenP-v$($env:Version).au3" -Encoding utf8NoBOM -Force

# https://www.autoitscript.com/autoit3/docs/directives/pragma-compile.htm
$Region = @"
#NoTrayIcon
#RequireAdmin
#Region
#pragma compile(Icon, Skull.ico)
#pragma compile(Comments, GenP)
#pragma compile(CompanyName, GenP)
#pragma compile(FileDescription, GenP)
#pragma compile(FileVersion, $($env:Version))
#pragma compile(LegalCopyright, GenP 2026)
#pragma compile(LegalTrademarks, GenP 2026)
#pragma compile(ProductName, GenP)
#pragma compile(ProductVersion, $($env:Version))
#pragma compile(UPX, true)
#EndRegion
"@
$Region, (Get-Content -Path "GenP_SOURCE\GenP\GenP-v$($env:Version).au3" -Encoding utf8NoBOM -Force) | Set-Content -Path "GenP_SOURCE\GenP\GenP-v$($env:Version).au3" -Encoding utf8NoBOM -Force

# Replace upx with the latest one
# https://github.com/upx/upx
$Parameters = @{
	Uri             = "https://api.github.com/repos/upx/upx/releases/latest"
	UseBasicParsing = $true
}
$Response = Invoke-RestMethod @Parameters
$tag_name = $Response.tag_name.Replace("v","")
$UPX_URL = ($Response.assets | Where-Object -FilterScript {$_.Name -match "win64"}).browser_download_url
$Parameters = @{
	Uri             = $UPX_URL
	OutFile         = "upx.zip"
	UseBasicParsing = $true
	Verbose         = $true
}
Invoke-WebRequest @Parameters

# Extract upx.exe
& "$env:SystemRoot\System32\tar.exe" -xvf "upx.zip" -C "GenP_SOURCE\GenP" --strip-components=1 upx-$($tag_name)-win64/upx.exe

# Instead of compiling as it's written in the build.ps1 from the archive, headless CI enviroment fails to do so, so we need to call Aut2Exe.exe
# $ArgumentList = "`"${env:ProgramFiles(x86)}\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.au3`" /NoStatus /in GenP_SOURCE\GenP-v$($env:Version).au3"
# Start-Process -FilePath "${env:ProgramFiles(x86)}\AutoIt3\AutoIt3_x64.exe" -ArgumentList $ArgumentList -WorkingDirectory GenP_SOURCE

& "${env:ProgramFiles(x86)}\AutoIt3\Aut2Exe\Aut2Exe.exe" /in "GenP_SOURCE\GenP\GenP-v$($env:Version).au3" /out "GenP_SOURCE\GenP.exe" /x64 /gui

# Wait until apk is being downloaded
do
{
	$GenP = Test-Path -Path "GenP_SOURCE\GenP.exe"

	if (-not $GenP)
	{
		"Waiting for a GenP file to be compiled..."
		Get-ChildItem -Path GenP_SOURCE -File
		Start-Sleep -Seconds 5
	}
}
while (-not $GenP)
