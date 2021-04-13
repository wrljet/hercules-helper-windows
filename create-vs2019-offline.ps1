# create-vs2019-offline.ps1 -- Part of Hercules-Helper
#
# SDL-Hercules-390 builder
# Updated: 22 MAR 2021
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
# Create an offline installer for Visual Studio 2019

cmd /c .\goodies\msft\vs_community_2019_16.9.31112.23.exe `
    --wait --passive --layout .\vs2019offline --lang en-US `
    --add Microsoft.VisualStudio.Workload.NativeDesktop `
    --add Microsoft.Component.MSBuild `
    --add Microsoft.Component.VC.Runtime.UCRTSDK `
    --add Microsoft.VisualStudio.Component.Debugger.JustInTime `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows10SDK `
    --add Microsoft.VisualStudio.Component.Windows10SDK.17763 `
    --add Microsoft.VisualStudio.Component.WinXP `
    --add Microsoft.VisualStudio.Component.Git `
    --add Microsoft.VisualStudio.Component.NuGet `
    --add Component.GitHub.VisualStudio

