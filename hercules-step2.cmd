:: hercules-step2.cmd -- Part of Hercules-Helper
::
:: Hercules builder
:: Updated: 01 JUN 2021
::
:: The most recent version of this project can be obtained with:
::   git clone https://github.com/wrljet/hercules-helper.git
:: or:
::   wget https://github.com/wrljet/hercules-helper/archive/master.zip
::
:: Please report errors in this to me so everyone can benefit.
::
:: Bill Lewis  bill@wrljet.com
::
:: Called from hercules-buildall.ps1, from the hercules-helper\windows directory

@if defined TRACEON (@echo on) else (@echo off)

echo Starting Hercules-Step 2...

pushd %HERCULES_HELPER_BUILD_DIR%\%1

    set "HERCULES_BUILD_DIR=%cd%\msvc.AMD64.bin"
 :: echo %HERCULES_BUILD_DIR%

    call "%HERCULES_HELPER_VCVARS_CMD%"

 :: echo %INCLUDE%
 :: set INCLUDE=%INCLUDE%;C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Include

    echo.
    echo [40;92m==^> Build Hercules - Press return to continue ...[0m
    set /P dummy=

    call makefile.bat RETAIL-X64 makefile.msvc 8 -title "*** Hercules-Helper Test Build ***" -a

    echo.
    echo [40;92m Just FYI: Windows Defender anti-malware may cause the tests to fail or hang. [0m
    echo.
    echo [40;92m==^> Run Tests - Press return to continue ...[0m
    set /P dummy=

    call tests\runtest.cmd -n * -t 2 -d ..\%1\tests

popd
:: back to builder

echo.
echo Hercules-Step2 phase completed!
echo Returning to PowerShell
echo.

