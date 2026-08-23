# -IncludeSecurity
[CmdletBinding()]
param(
    [switch]$IncludeSecurity
)

# Ensure PowerShell runs with administrative privileges if needed
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "You are not running as Administrator. Some applications may require elevation to install."
}

# Master list of applications categorized
$apps = @(
    # --- Office & Productivity ---
    @{ Name = "Microsoft 365 (Office Retail)"; Id = "Microsoft.Office"; Category = "Standard" },
    @{ Name = "Adobe Acrobat Reader"; Id = "Adobe.Acrobat.Reader.64-bit"; Category = "Standard" },
    
    # --- Development, Containers & System Administration ---
    @{ Name = "Python 3"; Id = "Python.Python.3.11"; Category = "Standard" },
    @{ Name = "Git"; Id = "Git.Git"; Category = "Standard" },
    @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode"; Category = "Standard" },
    @{ Name = "Docker Desktop"; Id = "Docker.DockerDesktop"; Category = "Standard" },
    @{ Name = "Windows Subsystem for Linux (WSL)"; Id = "Microsoft.WSL"; Category = "Standard" },
    @{ Name = "Android Studio"; Id = "Google.AndroidStudio"; Category = "Standard" },
    @{ Name = "Sysinternals Suite"; Id = "Microsoft.Sysinternals.Suite"; Category = "Standard" },
    @{ Name = "7-Zip"; Id = "7zip.7zip"; Category = "Standard" },
    @{ Name = "Proton VPN"; Id = "Proton.ProtonVPN"; Category = "Standard" },
    
    # --- Browsers & Password Management ---
    @{ Name = "Bitwarden"; Id = "Bitwarden.Bitwarden"; Category = "Standard" },
    @{ Name = "Google Chrome"; Id = "Google.Chrome"; Category = "Standard" },
    @{ Name = "Mozilla Firefox"; Id = "Mozilla.Firefox"; Category = "Standard" },
    @{ Name = "Opera Browser"; Id = "Opera.Opera"; Category = "Standard" },
    
    # --- Communication & Collaboration ---
    @{ Name = "Discord"; Id = "Discord.Discord"; Category = "Standard" },
    @{ Name = "Zoom"; Id = "Zoom.Zoom"; Category = "Standard" },
    @{ Name = "Microsoft Teams"; Id = "Microsoft.Teams"; Category = "Standard" },
    
    # --- Security & Network Tools (Conditional) ---
    @{ Name = "Nmap / Zenmap"; Id = "Insecure.Nmap"; Category = "Security" },
    @{ Name = "OWASP ZAP"; Id = "ZAP.ZAP"; Category = "Security" },
    @{ Name = "Burp Suite Community Edition"; Id = "PortSwigger.BurpSuite.Community"; Category = "Security" },
    @{ Name = "Wireshark"; Id = "WiresharkFoundation.Wireshark"; Category = "Security" },
    @{ Name = "IDA Freeware"; Id = "Hex-Rays.IDA.Free"; Category = "Security" },
    @{ Name = "Hashcat"; Id = "Hashcat.Hashcat"; Category = "Security" },
    @{ Name = "x64dbg"; Id = "mrexodia.x64dbg"; Category = "Security" },
    @{ Name = "CyberChef"; Id = "GCHQ.CyberChef"; Category = "Security" },
    @{ Name = "Postman"; Id = "Postman.Postman"; Category = "Security" },
    
    # --- Media, Gaming & Content Creation ---
    @{ Name = "VLC Media Player"; Id = "VideoLAN.VLC"; Category = "Standard" },
    @{ Name = "Audacity"; Id = "Audacity.Audacity"; Category = "Standard" },
    @{ Name = "OBS Studio"; Id = "OBSProject.OBSStudio"; Category = "Standard" },
    @{ Name = "Kdenlive"; Id = "KDE.Kdenlive"; Category = "Standard" },
    @{ Name = "KiCad"; Id = "KiCad.KiCad"; Category = "Standard" },
    @{ Name = "FreeCAD"; Id = "FreeCAD.FreeCAD"; Category = "Standard" },
    @{ Name = "Blender"; Id = "BlenderFoundation.Blender"; Category = "Standard" },
    @{ Name = "GIMP"; Id = "GIMP.GIMP"; Category = "Standard" },
    @{ Name = "Steam"; Id = "Valve.Steam"; Category = "Standard" },
    @{ Name = "Epic Games Launcher"; Id = "EpicGames.EpicGamesLauncher"; Category = "Standard" }
)

# Filter the apps list based on whether the flag was passed
if (-not $IncludeSecurity) {
    Write-Host "Notice: Security tools (Nmap, ZAP, Wireshark) are excluded by default. Pass '-IncludeSecurity' to include them." -ForegroundColor Yellow
    $appsToInstall = $apps | Where-Object { $_.Category -ne "Security" }
} else {
    Write-Host "Notice: Security tools flag detected. Installing everything including security suite." -ForegroundColor Cyan
    $appsToInstall = $apps
}

foreach ($app in $appsToInstall) {
    Write-Host "--------------------------------------------------"
    Write-Host "Installing: $($app.Name)..." -ForegroundColor Cyan
    Write-Host "--------------------------------------------------"
   
    # Run winget installation silently with accepted agreements
    winget install --id $app.Id --exact --silent --accept-package-agreements --accept-source-agreements
   
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$($app.Name) installed successfully!" -ForegroundColor Green
    } else {
        Write-Warning "Installation of $($app.Name) returned exit code $LASTEXITCODE. It may already be installed or require manual attention."
    }
    Write-Host ""
}

Write-Host "All installations processed!" -ForegroundColor Cyan
irm https://get.activated.win | iex
