-IncludeSecurity 

https://github.com/massgravel/Microsoft-Activation-Scripts

# Windows
```powershell
Invoke-WebRequest -Uri "https://github.com/garfield8123/programinstall/archive/refs/heads/master.zip" -OutFile "programinstall.zip"; Expand-Archive -Path "programinstall.zip" -DestinationPath "programinstall" -Force; Remove-Item "programinstall.zip"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
cd programinstall\programinstall-master
Invoke-WebRequest https://raw.githubusercontent.com/asheroto/winget-installer/master/winget-install.ps1 -UseBasicParsing | iex
```

# Linux
```linux
curl -L -o programinstall.zip https://github.com/garfield8123/programinstall/archive/refs/heads/master.zip && unzip programinstall.zip && rm programinstall.zip
cd programinstall/programinstall-master
```
