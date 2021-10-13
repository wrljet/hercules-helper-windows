# run-vs2019-offline.ps1 -- Part of Hercules-Helper
#
# SDL-Hercules-390 builder
# Updated: 12 OCT 2021
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
# Run offline installer for Visual Studio 2019

pushd .\vs2019offline\
    cmd /c .\vs_community_2019_16.11.31729.503.exe --passive --norestart --wait
popd
