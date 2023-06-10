#Requires -RunAsAdministrator

# Customizable variables incase anything needs to be changed.
$DownloadFolder = "c:\windows\temp"
$latestWingetZIP = "https://github.com/EmmaTheEmu/EasierWinget/raw/Testing/Winget%20v1.4.11071.zip"

#########################
# Function declerations #
#########################

function Setup-Winget{
    if($([Environment]::UserName) -ne "SYSTEM")
    {
        $progressPreference = 'silentlyContinue'
        $latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
        $latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]
        Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "$DownloadFolder\$latestWingetMsixBundle"
        Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "$DownloadFolder\Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Add-AppxPackage "$DownloadFolder\Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Add-AppxPackage "$DownloadFolder\$latestWingetMsixBundle"

        Return Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__*"
    }
    else {
        $latestWingetZIPName = $latestWingetZIP.Split("/")[-1]
        Invoke-WebRequest -Uri $latestWingetZIP -OutFile "$DownloadFolder\$latestWingetZIPName"
        Expand-Archive -path "$DownloadFolder\$latestWingetZIPName" -DestinationPath $DownloadFolder
        Remove-Item -path "$DownloadFolder\$latestWingetZIPName"
        Clear-Host

        Return Resolve-Path "$DownloadFolder\Winget"
    }

}

function Install-Winget([string]$argument){
    #Hides agreements, uses specific ID and hides installer.
    & $winget install -e --accept-source-agreements --accept-package-agreements --id "$Argument" -h
    if($?)
    {
        Write-Host "The Application has been installed successfully!"
        Start-Sleep 2
    }
    else{
        Write-Host "Error! The application is either already installed or there was an issue installing it." 
        Start-Sleep 2
    }
}

function Search-Winget([string]$argument){
    #Specified Winget as source, since we only use package names.
    #MS Store Provides bad package names. It's to avoid later confusion.
    & $winget search --accept-source-agreements -s winget "$argument"
}
function Main{
    Clear-Host
    Write-Host "Press 0 to quit"
    Write-Host "DEBUG: " $winget
    $Selection = Read-Host "Enter app name you wish to install"
    if ($Selection -eq "0"){Exit}
    
    #Create an array to store filtered results.
    #Winget is not native powershell, so we must take the string output
    #And convert it into a string where we filter everything.
    $ResultsFiltered = [System.Collections.ArrayList]::new()
    $Results = Search-Winget $Selection
    Foreach($Search in $Results)
    {
        $Search = [regex]::Match($Search, "\b\w+(\.\w+)+\b")
        if ($search.value -match "[a-z]"){
            #Every added result would output an integer.
            $ResultsFiltered.add($Search.value) | Out-Null
        }
    }
    $i = 1
    # Lists all items in the array (Unfiltered has empty spaces, that's why it's not used.)
    Foreach($Item in $ResultsFiltered)
    {
        Write-Host $i ' ' $Item
        $i++
    }

    $Selection = Read-Host "Select which app you wish to install"
    if ($ResultsFiltered[$Selection-1]){
        Install-Winget $ResultsFiltered[$Selection-1]
    }
}

########################
# Preparing the script #
########################

#Check if Winget is installed.
Write-Host "Checking for Winget."
$Winget = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__*"
# TODO: Add temp install system user

if(!$winget){
    Write-Host "Winget not found!`nInstalling now..."
    $Winget = Setup-Winget
    
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

#Makes the main function loop infinitely.
while($true){
    Main
}