-IncludeSecurity 

https://github.com/massgravel/Microsoft-Activation-Scripts

# Windows
```powershell
Invoke-WebRequest -Uri "https://github.com/garfield8123/programinstall/archive/refs/heads/master.zip" -OutFile "programinstall.zip"; Expand-Archive -Path "programinstall.zip" -DestinationPath "programinstall" -Force; Remove-Item "programinstall.zip"
```

# Linux
```linux
curl -L -o programinstall.zip https://github.com/garfield8123/programinstall/archive/refs/heads/master.zip && unzip programinstall.zip && rm programinstall.zip
```
