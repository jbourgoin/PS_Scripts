<#
.Synopsis
   Installs Git and dependencies on your local system.
.DESCRIPTION
   This script uses chocolatey to install Git, add the Git & Unix Tools to your system's Environment Variable PATH. Refreshes that PATH variable and lastly downloads the specified repository.
.EXAMPLE
   Install-GitandClone -RepoToDownload "Your Git Repo URL"
.EXAMPLE
   If you want to uninstall Git via PowerShell you can use the folllowing command: choco uninstall git --package-parameters='"/GitAndUnixToolsOnPath"'
#>
function Install-GitandClone
{
    [CmdletBinding()]
    Param(
    # Parameter help description
    [Parameter(Mandatory=$false)]
    [string]$RepoToDownload
    )

    Begin
    {
        # Parsing repo string for directory name
        Write-Host "`n`nPreparing to install Git via Chocolatey. This may take a couple minites...`n`n" -ForegroundColor Yellow
        $RepoName = $RepoToDownload.Split('/')[-1]
    }
    Process
    {
        # check if Chocolatey is installed and if not, install it
        try {
            choco
        }
        catch [CommandNotFoundException] {
            # Exception is stored in the automatic variable _
            Set-ExecutionPolicy Bypass -Scope Process -Force
            Write-Host "`nDownloading Chocolatey nuget manager for Git Installation`n" -ForegroundColor Yellow
            Invoke-expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -Force
        }

        # Helping the user out by creating a All Users All Hosts Profile that imports this module for each PSSesssion.
        if (!(test-path $profile.AllUsersAllHosts))
        {
            new-item -type file -path $profile.AllUsersAllHosts -Force
            Set-content -Path $profile.AllUsersAllHosts -Value "Import-Module Posh-Git -Force" -Force
        }

        # Install Git via Chocolatey with the Git and Unix tools added to the System Environment variable: PATH
        choco install git -y --package-parameters='"/GitAndUnixToolsOnPath"'
        
        # Changes location to your user's Source folder
        if(!(Test-Path $home\source))
        {
            New-Item -ItemType Directory -Name Source -Force
        }

        Set-Location $home\source\

        # Reinitializes your PATH system variables so that you can use the Git utility to pull down our Module
        Write-Host "`nRefreshing System Environment Variable: PATH`n" -ForegroundColor Yellow
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        # the line above works better than 'refreshenv'
        
        # Installing Posh-Git Module
        Write-Host "Installing and Importing Posh-Git Module" -ForegroundColor Yellow
        Install-module Posh-Git -Force
        Import-module Posh-Git -Force

        # We can now download our code locally and use Git to track changes
        Write-Host "`nNow downloading our $($RepoName) module`n" 
        $GitExe = "C:\Program Files\Git\cmd\git.exe"
        $Arguments = "clone $($RepoToDownload)"
        Start-process -WindowStyle Hidden -FilePath $GitExe -ArgumentList $Arguments -Wait
        # This -wait switch makes the user experience smoother
        Write-Output "`nGit Installation and Done!`n"
    }
    End
    {
        #End Tasks
        Set-Location $home\source\$RepoName
    }
}