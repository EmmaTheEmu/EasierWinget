#Requires -RunAsAdministrator

#######################
#Function declerations#
#######################

function Install-Winget{
$progressPreference = 'silentlyContinue'
$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]
Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "c:\windows\temp\$latestWingetMsixBundle"
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "c:\windows\temp\Microsoft.VCLibs.x64.14.00.Desktop.appx"
Add-AppxPackage "c:\windows\temp\Microsoft.VCLibs.x64.14.00.Desktop.appx"
Add-AppxPackage "c:\windows\temp\$latestWingetMsixBundle"
}

function Winget-Install([string]$argument){
    & $winget $Command $Argument --accept-package-agreements --accept-source-agreements
}

function Winget-Search([string]$argument){
    & $winget $Command $Argument --accept-package-agreements --accept-source-agreements
}
function Main{
    Switch($Selection){
        1 {Winget-Search}
        2 {Winget-Install}
        0 {Return}
    }
}

#### Main Code
#Check if Winget is installed.
Write-Host "Checking for Winget."
$Winget = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__*"

if(!$winget){
    Write-Host "Winget not found!`nInstalling now..."
    Install-Winget
    $Winget = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__*"
    
    if($winget){
        Write-Host "Winget has been installed!"
        Start-Sleep 2
        Clear-Host
    }
    else{
        Write-Host "Failed to install Winget!"
        return
    }
}
else{
    Write-Host "Winget found!"
    Start-Sleep 2
    Clear-Host
}
$Winget = $Winget.path + "\winget.exe"
$Selection = 0


Write-Host "What would you like to do?"
Write-Host "1. Search"
Write-Host "2. Install"
Write-Host "0. Quit"

$Selection = Read-Host "What would you like to do?"

Main