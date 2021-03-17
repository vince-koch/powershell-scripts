param (
    [string] $verb,
    [string] $arg0 = ""
)

$ErrorActionPreference = "Stop"
Add-Type -Assembly System.IO.Compression.FileSystem
Import-Module $PSScriptRoot\Elevate.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force

# capture variables for command elevation
$command = $PSCommandPath
$arguments = $PsBoundParameters.Values + $args

function Main
{
    switch ($verb)
    {
        "update" { Update }
        "help" { ShowHelp }
        default { ShowHelp }
    }

    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
}

function Update
{
    Ensure-Elevated $command $arguments

    $hostsUrl = "https://winhelp2002.mvps.org/hosts.zip"
    $hostsZipPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)\hosts.zip"
    $hostsPath = "$([Environment]::SystemDirectory)\drivers\etc\hosts"

    if (Test-Path $hostsZipPath) {
        Remove-Item $hostsZipPath
    }
    
    # download
    Write-Host "Downloading " -ForegroundColor DarkGray -NoNewLine
    Write-Host $hostsUrl
    Invoke-WebRequest -Uri $hostsUrl -OutFile $hostsZipPath

    # extract hosts from zip
    Write-Host "Updating " -ForegroundColor DarkGray -NoNewLine
    Write-Host $hostsPath
    $zip = [IO.Compression.ZipFile]::OpenRead($hostsZipPath)
    $zip.Entries | where {$_.Name -like 'hosts'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $hostsPath, $true)}
    $zip.Dispose()

    # delete zip file
    Remove-Item $hostsZipPath

    Write-Host "Success" -ForegroundColor Green
}

function ShowHelp
{
    Write-Host
    Write-Host "update            updates the hosts file"
    Write-Host "help              displays this help screen"
}

Main