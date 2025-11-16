# create-vs2026-offline.ps1 -- Part of Hercules-Helper
#
# SDL-Hercules-390 builder
# Updated: 13 NOV 2025
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
# Create an offline installer for Visual Studio 2026

$goodies_dir = ".\goodies"
$goodies_dir = Resolve-Path "$goodies_dir"
$wget_exe = "$goodies_dir\gnu\wget.exe"

# $cmd = "$wget_exe -nc https://aka.ms/vs/18/release/vs_Community.exe"
$cmd = "$wget_exe https://aka.ms/vs/stable/vs_community.exe --output-document=vs_community.exe"
Write-Output $cmd
Invoke-Expression -Command "$cmd"

cmd /c .\vs_community.exe `
    --wait --passive --layout .\vs2026offline --lang en-US `
    --add Microsoft.VisualStudio.Component.CoreEditor `
    --add Microsoft.VisualStudio.Workload.CoreEditor `
    --add Microsoft.VisualStudio.Component.Roslyn.Compiler `
    --add Microsoft.Component.MSBuild `
    --add Microsoft.VisualStudio.Component.TextTemplating `
    --add Microsoft.VisualStudio.Component.DiagnosticTools `
    --add Microsoft.VisualStudio.Component.Debugger.JustInTime `
    --add Microsoft.VisualStudio.Component.VC.CoreIde `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows11SDK.26100 `
    --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest `
    --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core `
    --add Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake `
    --add Microsoft.Component.VC.Runtime.UCRTSDK `
    --add Microsoft.VisualStudio.Workload.NativeDesktop `
    --add Microsoft.VisualStudio.Component.Git `
    --add Microsoft.VisualStudio.Component.WinXP

