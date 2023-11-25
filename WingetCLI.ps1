# Customizable variables incase anything needs to be changed.
$DownloadFolder = "c:\temp"
$latestWingetZIP = "https://raw.githubusercontent.com/EmmaTheEmu/EasierWinget/main/Wingetv1.6.3133.zip"

#########################
# Function declerations #
#########################

function Setup-Winget
{
    if($([Environment]::UserName) -ne "SYSTEM")
    {
        $progressPreference = 'silentlyContinue'
        if(!(Test-Path $DownloadFolder -ErrorAction SilentlyContinue))
        {
            New-Item -ItemType Directory -Path $DownloadFolder
        }
        Write-Host Installing Winget as User.
        $latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
        $latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]
        Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "$DownloadFolder\$latestWingetMsixBundle"
        Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "$DownloadFolder\Microsoft.VCLibs.appx"
        Add-AppxPackage "$DownloadFolder\Microsoft.VCLibs.appx" -ErrorAction SilentlyContinue
        Add-AppxPackage "$DownloadFolder\$latestWingetMsixBundle" -ErrorAction SilentlyContinue
        Clear-Host
        Return Get-Command winget
    }
    if($([Environment]::UserName) -eq "SYSTEM")
    {
        if(!(Test-Path $DownloadFolder -ErrorAction SilentlyContinue))
        {
            New-Item -ItemType Directory -Path $DownloadFolder
        }
        Write-Host Installing Winget as SYSTEM.
        $latestWingetZIPName = $latestWingetZIP.Split("/")[-1]
        # For some reason it takes a bit longer to create the folder than to actually execute the damn code so it causes issues.
        Invoke-WebRequest -Uri $latestWingetZIP -OutFile "$DownloadFolder\$latestWingetZIPName"
        Expand-Archive -path "$DownloadFolder\$latestWingetZIPName" -DestinationPath $DownloadFolder -ErrorAction SilentlyContinue
        Remove-Item -path "$DownloadFolder\$latestWingetZIPName"
        Clear-Host

        Return Resolve-Path "$DownloadFolder\Winget\winget.exe"
    }

}

function Install-Winget([string]$argument)
{
    #Hides agreements, uses specific ID and hides installer.
    & $winget.Path install -e --accept-source-agreements --accept-package-agreements --id "$Argument" -h --scope=machine
    if($?)
    {
        Write-Host "The Application has been installed successfully!"
        Start-Sleep 2
        Clear-Host
    }
    if(!$?){
        Write-Host "Error! The application is either already installed or there was an issue installing it." 
        Write-Host "Attempting to install without machine scope. (User may not be able to see this application)"
        Start-Sleep 4
        & $winget install -e --accept-source-agreements --accept-package-agreements --id "$Argument" -h
        if(!$?)
        {
            Write-Host "Error! Unable to install the application using winget." 
        }
    }
}

function Search-Winget([string]$argument)
{
    #Specified Winget as source, since we only use package names.
    #MS Store Provides bad package names. It's to avoid later confusion.
    & $winget.Path search --accept-source-agreements -s winget "$argument"
}
function Main
{
    Write-Host "Press 0 to quit`n"

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
    # If there are no results, don't ask what to install.
    if($ResultsFiltered.Count -eq 0){
        Write-Host "No results found!"
        Start-sleep 2
        Return}
    # Lists all items in the array (Unfiltered has empty spaces, that's why it's not used.)
    Write-Host "0 to go back."
    Foreach($Item in $ResultsFiltered)
    {
        Write-Host $i ' ' $Item
        $i++
    }

    $Selection = Read-Host "Select which app you wish to install"
    if ($Selection -eq "0"){Return}
    if ($ResultsFiltered[$Selection-1]){
        Install-Winget $ResultsFiltered[$Selection-1]
    }
}

########################
# Preparing the script #
########################

#Check if Winget is installed.
if($([Environment]::UserName) -eq "SYSTEM")
{
    Write-Host "Checking for Winget."
    $Winget = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__*\winget.exe" -ErrorAction SilentlyContinue
    if($Winget)
    {
        Write-Host "Winget found!"
        Start-Sleep 2
        Clear-Host
    }

    if(!$Winget)
    {
        $Winget = Resolve-Path "$DownloadFolder\Winget\winget.exe" -ErrorAction SilentlyContinue

        if($Winget)
        {
            Write-Host "Winget found!"
            Start-Sleep 2
            Clear-Host
        }

        if(!$Winget)
        {
            $Winget = Setup-Winget
        }
    }
}

if ($([Environment]::UserName) -ne "SYSTEM")
{
    $Winget = Resolve-Path "$DownloadFolder\Winget\winget.exe" -ErrorAction SilentlyContinue
    if($Winget)
    {
        Write-Host "Winget found!"
        Start-Sleep 2
        Clear-Host
    }

    if(!$Winget)
    {
        $Winget = Setup-Winget
    }
}

$Selection = 0

#Makes the main function loop infinitely.
while($true)
{
    Main
}