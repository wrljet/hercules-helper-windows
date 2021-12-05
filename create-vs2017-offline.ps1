# create-vs2017-offline.ps1 -- Part of Hercules-Helper
#
# SDL-Hercules-390 builder
# Updated: 2 DEC 2021
#
# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com
#
# Create an offline installer for Visual Studio 2017

$goodies_dir = ".\goodies"
$goodies_dir = Resolve-Path "$goodies_dir"
$wget_exe = "$goodies_dir\gnu\wget.exe"

# $cmd = "$wget_exe -nc https://aka.ms/vs/15/release/vs_community.exe"
$cmd = "$wget_exe https://aka.ms/vs/15/release/vs_community.exe --output-document=vs_community.exe"
Write-Output $cmd
Invoke-Expression -Command "$cmd"

cmd /c .\vs_community.exe `
    --wait --passive --layout .\vs2017offline --lang en-US `
    --add Microsoft.VisualStudio.Workload.NativeDesktop `
    --add Microsoft.Component.VC.Runtime.UCRTSDK `
    --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.WinXP `
    --add Microsoft.VisualStudio.Component.Debugger.JustInTime `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows10SDK `
    --add Microsoft.VisualStudio.Component.Windows10SDK.17763 `
    --add Microsoft.VisualStudio.Component.Git `
    --add Microsoft.VisualStudio.Component.NuGet `
    --add Component.GitHub.VisualStudio

