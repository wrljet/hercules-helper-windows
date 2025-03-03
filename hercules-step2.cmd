:: hercules-step2.cmd -- Part of Hercules-Helper
::
:: Hercules builder
:: Updated: 03 MAR 2025
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
::
:: cmd.exe /c hercules-step2.cmd $Flavor $CpuArch $NoPrompt 2`>`&1 | Tee-Object -Variable dummy

@if defined TRACEON (@echo on) else (@echo off)

setlocal
set "rc=0"

set NOPROMPT=%~2
@echo Starting Hercules-Step 2...

pushd %HERCULES_HELPER_BUILD_DIR%\%1

    set "BUILD_TYPE=RETAIL-X64"
    set "HERCULES_BUILD_DIR=%cd%\msvc.AMD64.bin"
    set "HERCULES_TEST_OPTION=-64"
    if "%2" equ "X86" (
        set "BUILD_TYPE=RETAIL"
        set "HERCULES_BUILD_DIR=%cd%\msvc.dllmod.bin"
        set "HERCULES_TEST_OPTION=-32"
    )

 :: echo %HERCULES_BUILD_DIR%

    call "%HERCULES_HELPER_VCVARS_CMD%"

 :: echo %INCLUDE%
 :: set INCLUDE=%INCLUDE%;C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Include

    echo.
    if "%NOPROMPT%" neq "True" (
        echo [40;92m==^> Build Hercules - Press return to continue ...[0m
        set /P dummy=
    )

    call makefile.bat %BUILD_TYPE% makefile.msvc 8 -title "*** Hercules-Helper Test Build ***" -a

:: Check return code from above before continuing
    set "rc=%errorlevel%"
    echo "ErrorLevel from build: %rc%"
    if %rc% equ 0 (
        echo.
        echo [40;92m Just FYI: Windows Defender anti-malware may cause the tests to fail or hang. [0m
        echo.
        if "%NOPROMPT%" neq "True" (
            echo [40;92m==^> Run Tests - Press return to continue ...[0m
            set /P dummy=
        )

        call tests\runtest.cmd -n * -t 2 %HERCULES_TEST_OPTION% -d ..\%1\tests
        set "rc=%errorlevel%"
    ) else (
        echo BUILD FAILED! Skipping tests
    )

popd
:: back to builder

echo.
echo Hercules-Step2 phase completed!
echo Returning to PowerShell
echo.

endlocal & exit /b %rc%
