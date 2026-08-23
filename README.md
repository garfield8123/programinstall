-IncludeSecurity 

https://github.com/massgravel/Microsoft-Activation-Scripts

# Windows
```powershell
Invoke-WebRequest -Uri "https://github.com/garfield8123/programinstall/archive/refs/heads/master.zip" -OutFile "programinstall.zip"; Expand-Archive -Path "programinstall.zip" -DestinationPath "programinstall" -Force; Remove-Item "programinstall.zip"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
cd programinstall\programinstall-master

$progressPreference = 'silentlyContinue'
$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
$latestWingetMsixBundle = $env:TEMP + "\Microsoft.DesktopAppInstaller.msixbundle"
Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile $latestWingetMsixBundle
Add-AppxPackage $latestWingetMsixBundle
.\installprograms.ps1
```

# Linux
```linux
curl -L -o programinstall.zip https://github.com/garfield8123/programinstall/archive/refs/heads/master.zip && unzip programinstall.zip && rm programinstall.zip
cd programinstall/programinstall-master
```
