# run-vs2026-offline.ps1 -- Part of Hercules-Helper
#
# SDL-Hercules-390 builder
# Updated: 18 SEP 2025
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
# Run offline installer for Visual Studio 2026

pushd .\vs2026offline\
    cmd /c .\vs_community.exe --passive --norestart --wait
popd
