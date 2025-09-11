# hercules-buildall.ps1 -- Part of Hercules-Helper
#
# Hercules builder
# Updated: 11 SEP 2025
#
# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper-windows.git
# or:
#   wget https://github.com/wrljet/hercules-helper-windows/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com
#
# Intended for Windows 10 and 11
#    Tested on Windows 10 Pro,  22H2
#    Works  on Windows 11 (not routinely tested)
#    Works  on Windows 10 Home, 22H2 (not routinely tested)
#    Works  on Windows 7 Enterprise (not routinely tested)
#    Tested with PowerShell 5.1, 7.1.3, and 7.3.8
#
# Works with Visual Studio 2017, 2019, 2022, and 2026 Community Edition
# in C:\Program Files (x86)\Microsoft Visual Studio\201x\Community

# Set-PSDebug -Trace 1

# May need these:
# Set-ExecutionPolicy RemoteSigned
# Set-ExecutionPolicy Unrestricted
#
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [Switch]$SkipVS,

    [Parameter(Mandatory = $false)]
    [Switch]$VS2017,

    [Parameter(Mandatory = $false)]
    [Switch]$VS2019,

    [Parameter(Mandatory = $false)]
    [Switch]$VS2022,

    [Parameter(Mandatory = $false)]
    [Switch]$VS2026,

    [Parameter(Mandatory = $false)]
    [String]$BuildDir,

    [Parameter(Mandatory = $false)]
    [String]$Flavor,

    [Parameter(Mandatory = $false)]
    [String]$SourceDir,

    [Parameter(Mandatory = $false)]
    [String]$GitRepo,

    [Parameter(Mandatory = $false)]
    [String]$GitBranch,

    [Parameter(Mandatory = $false)]
    [String]$GitCommit,

    [Parameter(Mandatory = $false)]
    [Switch]$ForceClone,

    [Parameter(Mandatory = $false)]
    [Switch]$Firewall,

    [Parameter(Mandatory = $false)]
    [Switch]$ColorText,

    [Parameter(Mandatory = $false)]
    [Switch]$NoPrompt)

##############################################################################
#

$DebugInfo = $false

$goodies_dir = ".\goodies"
$goodies_dir = Resolve-Path "$goodies_dir"
$consoleout_exe = "$goodies_dir\wrljet\consoleout.exe"

Function WriteCustomOutput($message,
                           [System.ConsoleColor]$foregroundcolor,
                           [System.ConsoleColor]$backgroundcolor)
{
    if ($message) {
        $currentForeColor = $Host.UI.RawUI.ForegroundColor
        $currentBackColor = $Host.UI.RawUI.BackgroundColor
        
        $Host.UI.RawUI.ForegroundColor = $foregroundcolor
        $Host.UI.RawUI.BackgroundColor = $backgroundcolor
    
        &"$consoleout_exe" $message
    
        $Host.UI.RawUI.ForegroundColor = $currentForeColor
        $Host.UI.RawUI.BackgroundColor = $currentBackColor

        Write-Output ''
    }
}

Function WriteGreenOutput($message)
{
    if ($message) {
        WriteCustomOutput -ForegroundColor Green -BackgroundColor Black -Message $message
    }
}

Function FindVCVARS($pattern)
{

if ($DebugInfo) { Write-Output "FindVCVARS(): pattern: $pattern" | out-host }

# $link = Get-ChildItem -Path "C:\ProgramData\Microsoft\Windows\Start Menu" -Recurse -File -Filter "x64*Native*2022.lnk"
    $link = Get-ChildItem -Path "C:\ProgramData\Microsoft\Windows\Start Menu" -Recurse -File -Filter $pattern

# C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio 2022\Visual Studio Tools\VC\x64 Native Tools Command Prompt for VS 2022.lnk

if ($DebugInfo) { Write-Output "FindVCVARS(): link: $link" | out-host }

    $fullname = $link.FullName
if ($DebugInfo) { Write-Output "FindVCVARS(): link.FullName: $fullname" | out-host }

    $sh = New-Object -ComObject WScript.Shell
    $shortcut = $sh.CreateShortcut($link.FullName)
if ($DebugInfo) { Write-Output "FindVCVARS(): shortcut:" | out-host }
if ($DebugInfo) { Write-Output $shortcut | out-host }

# /k "E:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

    $arguments = $shortcut.Arguments
if ($DebugInfo) { Write-Output "FindVCVARS(): arguments: $arguments" | out-host }

#   'matching : '
    if ($shortcut.Arguments -match '"\w:.*$') {
        $vcvars = $Matches[0]
    } else {
        Write-Output 'Match for vcvars failed' | out-host
    }

if ($DebugInfo) { Write-Output "FindVCVARS(): vcvars: $vcvars" | out-host }
    return $vcvars.ToString();
}

##############################################################################

$ver = $psversiontable.PSVersion
if ([System.Version]$ver -lt [System.Version]"5.1.0.0") {
    Write-Output "Powershell : $ver is too old.  5.1 is the minimum version."
    Exit 3
}

# Wrap everything in try/catch so we can stop the transcript
try {
    $startup_dir = Convert-Path .

    # Log everything
    $date = Get-Date -Format "yyyyMMdd_HH-mm-ss"
    $logfilename = ".\hercules-helper-$date.log"
    Start-Transcript "$logfilename"
    if ($?) {
        # Transcript started
    } else {
        Write-Error "Error: Unable to create transcript file: $logfilename"
        Exit 3
    }

    Import-Module -Name ".\EnvPaths.psm1"

    # Create the Rebuild.cmd script as we go along
    $rebuild_filename = ".\rebuild.cmd"
    ":: Rebuild Hercules, created by Hercules-Helper" | Out-File -FilePath $rebuild_filename
    "::" | Out-File -FilePath $rebuild_filename -Append
    ":: Original options used:" | Out-File -FilePath $rebuild_filename -Append

    Write-Output ""
    Write-Output "Rebuild script: $rebuild_filename"

    Write-Output ""
    Write-Output "Options:"
#    if ($ColorText.IsPresent) {
#        Write-Output "Color Text"
#    } else {
#        Write-Output "Plain Text"
#    }

    if ([string]::IsNullOrEmpty($BuildDir)) {
        Write-Error "Error: -BuildDir parameter is missing"
        Exit 3
    }

    # Process Visual Studio related options
    if ($SkipVS.IsPresent) {
        Write-Output "-SkipVS: Skipping Visual Studio installation/update"
    }

    if ($VS2017.IsPresent + $VS2019.IsPresent + $VS2022.IsPresent + $VS2026.IsPresent -Eq 0) {
        Write-Error "Error: Must specify either -VS2017, -VS2019, -VS2022, or -VS2026 option"
        Exit 3
    } elseif ($VS2017.IsPresent + $VS2019.IsPresent + $VS2022.IsPresent + $VS2026.IsPresent -Gt 1) {
        Write-Error "Error: Cannot specify multiple -VS2017, -VS2019, VS2022, and -VS2026 options together"
        Exit 3
    } elseif ($VS2017.IsPresent) {
        Write-Output "-VS2017  : Using Visual Studio 2017 installation/update"
        ":: Using VS2017" | Out-File -FilePath $rebuild_filename -Append
    } elseif ($VS2019.IsPresent) {
        Write-Output "-VS2019  : Using Visual Studio 2019 installation/update"
        ":: Using VS2019" | Out-File -FilePath $rebuild_filename -Append
    } elseif ($VS2022.IsPresent) {
        Write-Output "-VS2022  : Using Visual Studio 2022 installation/update"
        ":: Using VS2022" | Out-File -FilePath $rebuild_filename -Append
    } elseif ($VS2026.IsPresent) {
        Write-Output "-VS2026  : Using Visual Studio 2026 installation/update"
        ":: Using VS2026" | Out-File -FilePath $rebuild_filename -Append
    }

    if ($Firewall.IsPresent) {
        Write-Output "-Firewall: firewall rules will be updated"
        ":: Firewall rules will be updated" | Out-File -FilePath $rebuild_filename -Append
        ":: (not yet implemented)" | Out-File -FilePath $rebuild_filename -Append
    } else {
        Write-Output "         : firewall rules will not be updated"
        ":: Firewall rules will not be updated" | Out-File -FilePath $rebuild_filename -Append
    }

    Write-Output "-BuildDir: $BuildDir"

    if (! [string]::IsNullOrEmpty($Flavor)) {
        if ( $Flavor.ToLower() -eq 'sdl-hyperion' -Or $Flavor.ToLower() -eq 'sdl-hercules') {
            Write-Output "-Flavor  : SDL-Hyperion"
            ":: Build flavor = SDL-Hyperion" | Out-File -FilePath $rebuild_filename -Append
            $Flavor = "sdl-hyperion"
        } elseif ( $Flavor.ToLower() -eq 'aethra') {
            Write-Output "-Flavor  : Aethra"
            ":: Build flavor = Aethra" | Out-File -FilePath $rebuild_filename -Append
            $Flavor = "aethra"
        } else {
            Write-Error "Error: Unknown Flavor option: $Flavor"
            Exit 3
        }
    } else {
        Write-Output "-Flavor not present, assuming Hercules-Aethra"
        ":: Build flavor = Hercules-Aethra" | Out-File -FilePath $rebuild_filename -Append
        $Flavor = "aethra"
    }

    if (! [string]::IsNullOrEmpty($SourceDir)) {
        Write-Output "-SourceDir: $SourceDir"
        ":: SourceDir = $SourceDir" | Out-File -FilePath $rebuild_filename -Append
        if (! [string]::IsNullOrEmpty($GitRepo)) {
            Write-Error "Error: -GitRepo is incompatible with -SourceDir"
            Exit 3
        }
        if (! [string]::IsNullOrEmpty($GitBranch)) {
            Write-Error "Error: -GitBranch is incompatible with -SourceDir"
            Exit 3
        }
        if (! [string]::IsNullOrEmpty($GitCommit)) {
            Write-Error "Error: -GitCommit is incompatible with -SourceDir"
            Exit 3
        }
    } else {
        if (! [string]::IsNullOrEmpty($GitRepo)) {
            Write-Output "-GitRepo: $GitRepo"
        } else {
            if ( $Flavor -eq 'sdl-hyperion') {
                $GitRepo = "https://github.com/SDL-Hercules-390/hyperion.git"
            } elseif ( $Flavor -eq 'aethra') {
                $GitRepo = "https://github.com/Hercules-Aethra/aethra.git"
            } else {
                $GitRepo = "https://github.com/SDL-Hercules-390/hyperion.git"
            }
        }

        ":: GitRepo = $GitRepo" | Out-File -FilePath $rebuild_filename -Append

        if (! [string]::IsNullOrEmpty($GitBranch)) {
            Write-Output "-GitBranch: $GitBranch"
            ":: GitBranch = $GitBranch" | Out-File -FilePath $rebuild_filename -Append
        }

        if (! [string]::IsNullOrEmpty($GitCommit)) {
            Write-Output "-GitCommit: $GitCommit"
            ":: GitCommit = $GitCommit" | Out-File -FilePath $rebuild_filename -Append
        }

        if ($ForceClone.IsPresent) {
            Write-Output "-ForceClone: Git repo will be overwritten"
            ":: ForceClone = yes" | Out-File -FilePath $rebuild_filename -Append
        }
    }

    Write-Output ""

    $user_dir = $env:USERPROFILE
    Write-Output "User directory     : $user_dir"
    ":: User directory = $user_dir" | Out-File -FilePath $rebuild_filename -Append

    $hercules_dir = "$BuildDir"
    $dir = New-Item -ItemType Directory -Force -Path "$hercules_dir"
    $hercules_dir = Resolve-Path "$hercules_dir"
    Write-Output "Hercules directory : $hercules_dir"
    ":: Hercules directory = $hercules_dir" | Out-File -FilePath $rebuild_filename -Append

    $goodies_dir = ".\goodies"
    $goodies_dir = Resolve-Path "$goodies_dir"
    Write-Output "goodies_dir        : $goodies_dir"
    ":: Goodies directory = $goodies_dir" | Out-File -FilePath $rebuild_filename -Append

    $unzip_exe = "$goodies_dir\gnu\unzip.exe"
    Write-Output "unzip.exe          : $unzip_exe"
    ":: Unzip = $unzip_exe" | Out-File -FilePath $rebuild_filename -Append
    $wget_exe = "$goodies_dir\gnu\wget.exe"
    Write-Output "wget.exe           : $wget_exe"
    ":: Wget = $wget_exe" | Out-File -FilePath $rebuild_filename -Append
    Write-Output ""

    $sLogPath = Resolve-Path '.\'
    $sLogName = 'logfile.log'
    $sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName
    ":: LogFile = $sLogFile" | Out-File -FilePath $rebuild_filename -Append

    "" | Out-File -FilePath $rebuild_filename -Append

    ##############################################################################
    if (Test-Path 'env:REXX_HOME') {
        Write-Output "REXX_HOME is $env:REXX_HOME"
    } else {
        Write-Output " `
        REXX_HOME environment variable is empty.  Is ooRexx installed? `
        `
        REXX will be needed to run the Hercules instruction tests after building. `
        `
        The ooRexx v5.0.0 installer (64-bit) may be found in the 'goodies' directory. `
        `
        You will need to restart PowerShell to get a fresh set of environment `
        variables after installing REXX. `
        "

        WriteGreenOutput "        Stop now (Ctrl+C) and install REXX if you've forgotten it."

        $input = Read-Host -Prompt 'Press return to continue without REXX'
    }
    Write-Output ""

    ##############################################################################
    # Check if there are already environment variables for the winbuild packages
    # and if so, that they point to the correct place.
    #
    # e.g. $hercules_dir\hyperion\winbuild\bzip2
    #

    $bzip2_dir_bad = $false
    $pcre_dir_bad  = $false
    $zlib_dir_bad  = $false

    if (Test-Path 'env:BZIP2_DIR') {
        Write-Output "BZIP2_DIR is $env:BZIP2_DIR"
        $winbuild_bzip2_dir = Resolve-Path "$hercules_dir\$Flavor\winbuild\bzip2"
        Write-Output "winbuild bzip2 dir : $winbuild_bzip2_dir"
        if ( $env:BZIP2_DIR -ine $winbuild_bzip2_dir ) {
            $bzip2_dir_bad = $true
            Write-Error "Pre-existing BZIP2_DIR environment variable points to the wrong directory"
            Write-Output ""
        }
    }

    if (Test-Path 'env:PCRE_DIR') {
        Write-Output "PCRE_DIR is $env:PCRE_DIR"
        $winbuild_pcre_dir = Resolve-Path "$hercules_dir\$Flavor\winbuild\pcre"
        Write-Output "winbuild pcre dir : $winbuild_pcre_dir"
        if ( $env:PCRE_DIR -ine $winbuild_pcre_dir ) {
            $pcre_dir_bad = $true
            Write-Error "Pre-existing PCRE_DIR environment variable points to the wrong directory"
            Write-Output ""
        }
    }

    if (Test-Path 'env:ZLIB_DIR') {
        Write-Output "ZLIB_DIR is $env:ZLIB_DIR"
        $winbuild_zlib_dir = Resolve-Path "$hercules_dir\$Flavor\winbuild\zlib"
        Write-Output "winbuild zlib dir : $winbuild_zlib_dir"
        if ( $env:ZLIB_DIR -ine $winbuild_zlib_dir ) {
            $zlib_dir_bad = $true
            Write-Error "Pre-existing ZLIB_DIR environment variable points to the wrong directory"
            Write-Output ""
        }
    }

    if ($bzip2_dir_bad -or $pcre_dir_bad -or $zlib_dir_bad) {
        Exit 3
    } else {
        Write-Output ""
    }

    ##############################################################################
    Write-Output "System Information:"
    (systeminfo /fo csv | ConvertFrom-Csv | select 'OS Name', 'OS Version' | Format-List | Out-String).Trim()
    $ver = $psversiontable.PSVersion.ToString()
    Write-Output "Powershell : $ver"
    Write-Output ""

    Write-Output "Locale     : "
    Get-WinSystemLocale
    Write-Output ""

    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    Write-Output "CPU Info   : $cpuInfo"
    Write-Output ""

    # Write-Output "wmic os get osarchitecture"
    if ((Get-WmiObject Win32_OperatingSystem | Select-Object OSArchitecture) -match "32") {
        # Write-Output "found 32-bit system"
        $bitness = 32
        $CpuArch = "x86"
    } else {
        # Write-Output "found 64-bit system"
        $bitness = 64
        $CpuArch = "x64"
    }

    Write-Output ""
    Write-Output "==> Begin ..."
    if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }

    ##############################################################################
    # Check for existing VS2017 and required workloads
    #
    Write-Output "Checking for existing VS2017 15.9, VS2019 16.11, VS2022 17.14, or VS2026 18.0 required workloads ..."
    Write-Output ""
    WriteGreenOutput "Note: Visual Studio 2017, 2019, 2022, and 2026 will peacefully coexist."
    Write-Output ""

    # From:
    # https://github.com/microsoft/vssetup.powershell via NuGet
    # Install-Module VSSetup -Scope CurrentUser -Force

    if ((Get-Module -ListAvailable -Name VSSetup) -eq $Null) {
        # VSSetup is not installed
        if (!(Test-Path -Path "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\VSSetup")) {
            # VSSetup is not in local modules directory
            Write-Output "Installing https://github.com/microsoft/vssetup.powershell via goodies zipfile"

            try {
                Expand-Archive "$goodies_dir\msft\VSSetup.zip" "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\VSSetup"
            } catch {
                throw $_.Exception.Message
            }
        } else {
            Write-Output "VSSetup found in local modules directory"
        }

        Install-Module VSSetup -Scope CurrentUser -Force
    } else {
        Write-Output "https://github.com/microsoft/vssetup.powershell is already present locally"
    }

    $workloads_2017 = `
        'Microsoft.VisualStudio.Workload.NativeDesktop', `
        'Microsoft.Component.VC.Runtime.UCRTSDK', `
        'Microsoft.VisualStudio.ComponentGroup.NativeDesktop.WinXP', `
        'Microsoft.VisualStudio.Component.Debugger.JustInTime', `
        'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', `
        'Microsoft.VisualStudio.Component.Windows10SDK', `
        'Microsoft.VisualStudio.Component.Windows10SDK.17763', `
        'Microsoft.VisualStudio.Component.Git', `
        'Microsoft.VisualStudio.Component.NuGet', `
        'Component.GitHub.VisualStudio'

    $workloads_2019 = `
        'Microsoft.VisualStudio.Workload.NativeDesktop', `
        'Microsoft.Component.VC.Runtime.UCRTSDK', `
        'Microsoft.VisualStudio.Component.WinXP', `
        'Microsoft.VisualStudio.Component.Debugger.JustInTime', `
        'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', `
        'Microsoft.VisualStudio.Component.Windows10SDK', `
        'Microsoft.VisualStudio.Component.Windows10SDK.17763', `
        'Microsoft.VisualStudio.Component.Git', `
        'Microsoft.VisualStudio.Component.NuGet', `
        'Component.GitHub.VisualStudio'

    $workloads_2022 = `
        'Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core', `
        'Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake', `
        'Microsoft.VisualStudio.Workload.CoreEditor', `
        'Microsoft.VisualStudio.Workload.NativeDesktop', `
        'Microsoft.VisualStudio.Component.CoreEditor', `
        'Microsoft.VisualStudio.Component.Roslyn.Compiler', `
        'Microsoft.Component.MSBuild', `
        'Microsoft.VisualStudio.Component.TextTemplating', `
        'Microsoft.VisualStudio.Component.Debugger.JustInTime', `
        'Microsoft.VisualStudio.Component.VC.CoreIde', `
        'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', `
        'Microsoft.VisualStudio.Component.Windows10SDK.19041', `
        'Microsoft.VisualStudio.Component.VC.Redist.14.Latest', `
        'Microsoft.VisualStudio.Component.VC.CMake.Project', `
        'Microsoft.Component.VC.Runtime.UCRTSDK', `
        'Microsoft.VisualStudio.Component.Git', `
        'Microsoft.VisualStudio.Component.WinXP'

    $workloads_2026 = `
        'Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core', `
        'Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake', `
        'Microsoft.VisualStudio.Workload.CoreEditor', `
        'Microsoft.VisualStudio.Workload.NativeDesktop', `
        'Microsoft.VisualStudio.Component.CoreEditor', `
        'Microsoft.VisualStudio.Component.Roslyn.Compiler', `
        'Microsoft.Component.MSBuild', `
        'Microsoft.VisualStudio.Component.TextTemplating', `
        'Microsoft.VisualStudio.Component.Debugger.JustInTime', `
        'Microsoft.VisualStudio.Component.VC.CoreIde', `
        'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', `
        'Microsoft.VisualStudio.Component.Windows10SDK.19041', `
        'Microsoft.VisualStudio.Component.VC.Redist.14.Latest', `
        'Microsoft.VisualStudio.Component.VC.CMake.Project', `
        'Microsoft.Component.VC.Runtime.UCRTSDK', `
        'Microsoft.VisualStudio.Component.Git', `
        'Microsoft.VisualStudio.Component.WinXP'

    if ($VS2017.IsPresent) {
        $workloads = $workloads_2017
    } elseif ($VS2019.IsPresent) {
        $workloads = $workloads_2019
    } elseif ($VS2022.IsPresent) {
        $workloads = $workloads_2022
    } elseif ($VS2026.IsPresent) {
        $workloads = $workloads_2026
    } else {
        Write-Error "Error: Inconsistent VS2017/VS2019/VS2022/VS2026 options"
        Exit 3
    }

    Write-Output ""

    $vs_2017_missing = $false
    $vs_2019_missing = $false
    $vs_2022_missing = $false
    $vs_2026_missing = $false
    foreach ($workload in $workloads)
    {
        $vs2017_found = $false
        $vs2019_found = $false
        $vs2022_found = $false
        $vs2026_found = $false
        $workload_2017_found = $false
        $workload_2019_found = $false
        $workload_2022_found = $false
        $workload_2026_found = $false

        $found = (Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Require "$workload" -Version '[15.9,)')

        if ($found -eq $null) {
            WriteCustomOutput -ForegroundColor Yellow -BackgroundColor Black -Message `
                "missing        : $workload"
            $vs_2017_missing = $true
            $vs_2019_missing = $true
            $vs_2022_missing = $true
            $vs_2026_missing = $true
        } else {
            foreach ($f in $found) {
                echo $workload
                echo $f.InstallationVersion.ToString()

                $ff = $f.InstallationVersion.ToString() 
                Write-Output "$ff : $workload"

                if ($ff.StartsWith('15.9')) {
                    # Write-Output "15.9 version found"
                    $workload_2017_found = $true
                    $vs2017_found = $true
                } elseif ($ff.StartsWith('16.11')) {
                    # Write-Output "16.11 version found"
                    $workload_2019_found = $true
                    $vs2019_found = $true
                } elseif ($ff.StartsWith('17.14')) {
                    # Write-Output "17.14 version found"
                    $workload_2022_found = $true
                    $vs2022_found = $true
                } elseif ($ff.StartsWith('18.0')) {
                    # Write-Output "18.0 version found"
                    $workload_2026_found = $true
                    $vs2026_found = $true
                } else {
                    # Write-Output "not            : VS2017 15.9, VS2019 16.11, or VS2022 17.14 version"
                }
            }

            if ($VS2017.IsPresent -And !$workload_2017_found) {
                $vs_2017_missing = $true
                WriteCustomOutput -ForegroundColor Yellow -BackgroundColor Black -Message `
                    "missing VS2017 : $workload"
            }

            if ($VS2019.IsPresent -And !$workload_2019_found) {
                $vs_2019_missing = $true
                WriteCustomOutput -ForegroundColor Yellow -BackgroundColor Black -Message `
                    "missing VS2019 : $workload"
            }

            if ($VS2022.IsPresent -And !$workload_2022_found) {
                $vs_2022_missing = $true
                WriteCustomOutput -ForegroundColor Yellow -BackgroundColor Black -Message `
                    "missing VS2022 17.14 : $workload"
            }

            if ($VS2026.IsPresent -And !$workload_2026_found) {
                $vs_2026_missing = $true
                WriteCustomOutput -ForegroundColor Yellow -BackgroundColor Black -Message `
                    "missing VS2026 18.0 : $workload"
            }
        }
    }

    Write-Output ""
    if ($VS2017.IsPresent -And $vs_2017_missing) {
        Write-Output "Some required VS2017 workloads are missing, and can be automatically installed."
    } elseif ($VS2017.IsPresent) {
        WriteGreenOutput "All required VS2017 workloads are present."
    }

    if ($VS2019.IsPresent -And $vs_2019_missing) {
        Write-Output "Some required VS2019 workloads are missing, and can be automatically installed."
    } elseif ($VS2019.IsPresent) {
        WriteGreenOutput "All required VS2019 workloads are present."
    }

    if ($VS2022.IsPresent -And $vs_2022_missing) {
        Write-Output "Some required VS2022 workloads are missing, and can be automatically installed."
    } elseif ($VS2022.IsPresent) {
        WriteGreenOutput "All required VS2022 workloads are present."
    }

    if ($VS2026.IsPresent -And $vs_2026_missing) {
        Write-Output "Some required VS2026 workloads are missing, and can be automatically installed."
    } elseif ($VS2026.IsPresent) {
        WriteGreenOutput "All required VS2026 workloads are present."
    }
    Write-Output ""

    ##############################################################################

    if ($vs_2017_missing -And $VS2017.IsPresent -And !$SkipVS.IsPresent) {
        Write-Output "==> Create/update VS2017 installer (this will take some time)"
        if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }

        # Create an offline installer for Visual Studio 2017
        .\create-vs2017-offline.ps1
        Write-Output ""

        Write-Output "==> Run VS2017 installer (this will take some time)"
        if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
        pushd .\vs2017offline\
          cmd /c .\vs_community.exe --passive --norestart --wait
        popd
        Write-Output ""
    } elseif ($vs_2019_missing -And $VS2019.IsPresent -And !$SkipVS.IsPresent) {
        Write-Output "==> Create/update VS2019 installer (this will take some time)"
        if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }

        # Create an offline installer for Visual Studio 2019
        .\create-vs2019-offline.ps1
        Write-Output ""

        Write-Output "==> VS2019 will require updating.  Ctrl+C now if you don't want that."

        pushd .\vs2019offline\
          Write-Output "==> Run VS2019 installer to update (this will take some time)"
          if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
          cmd /c .\vs_community.exe update --passive --norestart --wait

          Write-Output "==> Run VS2019 installer to add missing workloads (this will take some time)"
          if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
          cmd /c .\vs_community.exe --passive --norestart --wait
        popd
        Write-Output ""
    } elseif ($vs_2022_missing -And $VS2022.IsPresent -And !$SkipVS.IsPresent) {
        Write-Output "==> Create/update VS2022 installer (this will take some time)"
        if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }

        # Create an offline installer for Visual Studio 2022
        .\create-vs2022-offline.ps1
        Write-Output ""

        Write-Output "==> VS2022 will require updating.  Ctrl+C now if you don't want that."

        pushd .\vs2022offline\
          Write-Output "==> Run VS2022 installer to update (this will take some time)"
          if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
          cmd /c .\vs_community.exe update --passive --norestart --wait

          Write-Output "==> Run VS2022 installer to add missing workloads (this will take some time)"
          if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
          cmd /c .\vs_community.exe --passive --norestart --wait
        popd
        Write-Output ""
    } elseif ($vs_2026_missing -And $VS2026.IsPresent -And !$SkipVS.IsPresent) {
        Write-Output "==> Create/update VS2026 installer (this will take some time)"
        if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }

        # Create an offline installer for Visual Studio 2026
        .\create-vs2026-offline.ps1
        Write-Output ""

        Write-Output "==> VS2026 will require updating.  Ctrl+C now if you don't want that."

        pushd .\vs2026offline\
          Write-Output "==> Run VS2026 installer to update (this will take some time)"
          if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
          cmd /c .\vs_community.exe update --passive --norestart --wait

          Write-Output "==> Run VS2026 installer to add missing workloads (this will take some time)"
          if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
          cmd /c .\vs_community.exe --passive --norestart --wait
        popd
        Write-Output ""
    } else {
        Write-Output "Skipping Visual Studio installer"
        Write-Output ""
    }

    ##############################################################################
    # Create user property directory/files if missing

    if ($VS2017.IsPresent) {
        $vcver = "2017"
        Write-Output "==> Creating VS$vcver user property directory if missing"
        Write-Output "Looking for VCVARS$bitness.BAT via $CpuArch*Native*$vcver.lnk shortcut search"
        # Write-Output ("$CpuArch" + '*Native*2017.lnk')
        $vcvars = FindVCVARS ("$CpuArch" + '*Native*2017.lnk')
        Write-Output "Found VCVARS$bitness.BAT file : $vcvars"
        $vcvars_cmd = "$vcvars"
        $vcvars_cmd = $vcvars_cmd.Replace("`"","")
    } elseif ($VS2019.IsPresent) {
        $vcver = "2019"
        Write-Output "==> Creating VS$vcver user property directory if missing"
        # $vcvars_cmd = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars$CpuArch.bat"

        Write-Output "Looking for VCVARS$bitness.BAT via $CpuArch*Native*$vcver.lnk shortcut search"
        # Write-Output ("$CpuArch" + '*Native*2019.lnk')
        $vcvars = FindVCVARS ("$CpuArch" + '*Native*2019.lnk')
        Write-Output "Found VCVARS$bitness.BAT file : $vcvars"
        $vcvars_cmd = "$vcvars"
        $vcvars_cmd = $vcvars_cmd.Replace("`"","")
    } elseif ($VS2022.IsPresent) {
        $vcver = "2022"
        Write-Output "==> Creating VS$vcver user property directory if missing"

        Write-Output "Looking for VCVARS$bitness.BAT via $CpuArch*Native*$vcver.lnk shortcut search"
        $vcvars = FindVCVARS 'x64*Native*2022.lnk'
        Write-Output "Found VCVARS$bitness.BAT file : $vcvars"
        $vcvars_cmd = "$vcvars"
        $vcvars_cmd = $vcvars_cmd.Replace("`"","")

#        $vcvars_c_cmd = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
#        if (Test-Path -Path "$vcvars_c_cmd" -PathType leaf ) {
#            Write-Output "==> Found vcvars64.bat on drive C:"
#            $vcvars_cmd = "$vcvars_c_cmd"
#        }
#        $vcvars_d_cmd = "D:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
#        if (Test-Path -Path "$vcvars_d_cmd" -PathType leaf ) {
#            Write-Output "==> Found vcvars64.bat on drive D:"
#            $vcvars_cmd = "$vcvars_d_cmd"
#        }
    } elseif ($VS2026.IsPresent) {
        $vcver = "2026"
        Write-Output "==> Creating VS$vcver user property directory if missing"

        Write-Output "Looking for VCVARS$bitness.BAT via $CpuArch*Native*$vcver.lnk shortcut search"
        $vcvars = FindVCVARS 'x64*Native*VS 18*.lnk'
        Write-Output "Found VCVARS$bitness.BAT file : $vcvars"
        $vcvars_cmd = "$vcvars"
        $vcvars_cmd = $vcvars_cmd.Replace("`"","")
    } else {
        Write-Error "Error: Inconsistent VS2017/VS2019/VS2022/VS2026 options"
        Exit 3
    }

    "setlocal" | Out-File -FilePath $rebuild_filename -Append
    "" | Out-File -FilePath $rebuild_filename -Append
    "set HERCULES_HELPER_BUILD_DIR=$hercules_dir" | Out-File -FilePath $rebuild_filename -Append
    "set HERCULES_HELPER_VCVARS_CMD=$vcvars_cmd" | Out-File -FilePath $rebuild_filename -Append

    if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }

    $props_dir = "$HOME\AppData\Local\Microsoft\MSBuild\v4.0"
    Write-Output "Visual Studio User Properties directory: $props_dir"

    $dir = (New-Item -ItemType Directory -Force -Path "$props_dir").ToString()

    Write-Output "Creating user property files if missing"
    if (!(Test-Path -Path "$props_dir\Microsoft.Cpp.x64.user.props" -PathType leaf )) {
        try {
            Write-Output "Creating missing $props_dir\Microsoft.Cpp.x64.user.props"
            Copy-Item '.\goodies\Microsoft.Cpp.x64.user.props' -destination "$props_dir"
        } catch {
            throw $_.Exception.Message
        }
    } else {
        Write-Output 'Microsoft.Cpp.x64.user.props already exists'
        Write-Output 'Checking contents'
        $include_found = (Get-Content "$user_dir\AppData\Local\Microsoft\MSBuild\v4.0\Microsoft.Cpp.x64.user.props" | %{$_ -match "\$\(INCLUDE\)\;"}) -contains $true
        if ($include_found) {
            Write-Output "Existing Microsoft.Cpp.x64.user.props contains `$(INCLUDE);"
        } else {
            Write-Output "Existing Microsoft.Cpp.x64.user.props does not contain `$(INCLUDE);"
            WriteGreenOutput "*** Microsoft.Cpp.x64.user.props will need to be edited manually ***"

            WriteGreenOutput "        Stop now (Ctrl+C) to edit the props file."

            if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
        }
    }

    Write-Output ""

    ##############################################################################
    # Dig the path environment variable out of the registry and put it into effect
    #

    Write-Output "Adding the PATH that the Visual Studio installer created"
    $new_path = (Get-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Environment').Path
    $new_local_path = (Get-ItemProperty -Path 'HKCU:\Environment').Path
    $env:Path = "$new_path;$new_local_path"

    Write-Output "Adding the INCLUDE environment variable for the Windows SDK v7.1A"
    Write-Output "... C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Include"
    Add-EnvInclude -Path "C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Include" -Container "User"
    Write-Output ""

    "set INCLUDE=$env:Include" | Out-File -FilePath $rebuild_filename -Append

    ##############################################################################
    # Download Hercules and related packages from GitHub 
    #

    pushd "$hercules_dir"

    if ($SourceDir -ne "") {
        $getfrom = "$SourceDir directory"
        $gethow = "Copy-item"
        $getto = "$Flavor directory"
        $getverb = "Copy"
    } else {
        $getfrom = "GitHub"
        $gethow = "git clone"
        $getto = "git repo"
        $getverb = "Clone"
    }
    Write-Output "==> $getverb Hercules from $getfrom and download other packages"
    if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }

    # If hyperion repo directory already exists, and -ForceClone is
    # specified, delete it.
    #
    if ( Test-Path -Path "$Flavor" -PathType Container ) {
        if ($ForceClone.IsPresent) {
            Write-Output "-ForceClone specified: removing existing $Flavor directory"
            Write-Output ""

            do { $input = Read-Host -Prompt "Remove existing Hercules $getto? [y/N]" }
            until ("", "yes", "no", "YES", "NO", "y", "Y", "n", "N" -ccontains $input)

            if ( $input.ToLower() -eq 'y') {
                Remove-Item -path "$Flavor" -Recurse -Force
            } else {
                Write-Output "Quitting"
                Exit 3
            }
        }
    }

    if ( -not (Test-Path -Path "$Flavor" -PathType Container) ) {
        if ($SourceDir -ne "") {
            Copy-item -Force -Recurse "$SourceDir" -Destination "$Flavor"
        } else {
            # (git clone  https://github.com/SDL-Hercules-390/hyperion.git 2>&1) | Out-Default
            $cmd = "git clone $GitRepo $Flavor"

            if (! [string]::IsNullOrEmpty($GitBranch)) {
                $cmd = "git clone -b $GitBranch $GitRepo $Flavor"
            }

            Write-Output "$cmd"
            Invoke-Expression -Command "$cmd"

            if (! [string]::IsNullOrEmpty($GitCommit)) {
                pushd $Flavor
                $cmd = "git checkout $GitCommit"
                Write-Output "$cmd"
                Invoke-Expression -Command "$cmd"
                popd
            }
        }
    } else {
        Write-Output "$Flavor directory exists, skipping '$gethow'."
    }
    Remove-Variable -Name getfrom, gethow, getto, getverb

    cd $Flavor

    Write-Output "Downloading packages"
    $dir = New-Item -ItemType Directory -Force -Path "winbuild"
    pushd winbuild
        $zipfile = "ZLIB1-1.2.11-bin-lib-inc-vc2008-x86-x64.zip"
        if (!(Test-Path -Path $zipfile -PathType leaf )) {
            $cmd = "$wget_exe -nc http://www.softdevlabs.com/downloads/$zipfile"
            Write-Output $cmd
            Invoke-Expression -Command "$cmd"
        } else {
            Write-Output "$zipfile is already present, not retrieving"
        }

        $zipfile ="BZIP2-1.0.6-bin-lib-inc-vc2008-x86-x64.zip"
        if (!(Test-Path -Path $zipfile -PathType leaf )) {
            $cmd ="$wget_exe -nc http://www.softdevlabs.com/downloads/$zipfile"
            Write-Output $cmd
            Invoke-Expression -Command "$cmd"
            } else {
            Write-Output "$zipfile is already present, not retrieving"
        }

        $zipfile = "PCRE-6.4.1-bin-lib-inc-vc2008-x86-x64.zip"
        if (!(Test-Path -Path $zipfile -PathType leaf )) {
            $cmd = "$wget_exe -nc http://www.softdevlabs.com/downloads/$zipfile"
            Write-Output $cmd
            Invoke-Expression -Command "$cmd"
        } else {
            Write-Output "$zipfile is already present, not retrieving"
        }

        Write-Output ""
        Write-Output "Unzipping packages"

        # if paths already exist, don't recreate or re-untar
        if (!(Test-Path 'bzip2')) {
            $dir = New-Item bzip2 -ItemType Directory -ErrorAction SilentlyContinue
            pushd bzip2
                $cmd = "$unzip_exe ..\BZIP2-1.0.6-bin-lib-inc-vc2008-x86-x64.zip 2>&1"
                Write-Output $cmd
                Invoke-Expression -Command "$cmd"
            popd # winbuild
        } else {
            Write-Output "bzip2 directory is already present, not un-tarring"
        }

        if (!(Test-Path 'zlib')) {
            $dir = New-Item zlib -ItemType Directory -ErrorAction SilentlyContinue
            pushd zlib
                $cmd = "$unzip_exe ..\ZLIB1-1.2.11-bin-lib-inc-vc2008-x86-x64.zip 2>&1"
                Write-Output $cmd
                Invoke-Expression -Command "$cmd"
            popd # winbuild
        } else {
            Write-Output "zlib directory is already present, not un-tarring"
        }

        if (!(Test-Path 'pcre')) {
            $dir = New-Item pcre -ItemType Directory -ErrorAction SilentlyContinue
            pushd pcre
                $cmd = "$unzip_exe ..\PCRE-6.4.1-bin-lib-inc-vc2008-x86-x64.zip 2>&1"
                Write-Output $cmd
                Invoke-Expression -Command "$cmd"
            popd # winbuild
        } else {
            Write-Output "pcre directory is already present, not un-tarring"
        }

    popd # hyperion
    Write-Output ""
    ##############################################################################

    popd # builder

    Write-Output "Preparation is complete!  Proceeding to Step 2 in a Visual Studio CMD shell"
    Write-Output ""

    $env:HERCULES_HELPER_BUILD_DIR = "$hercules_dir"
    $env:HERCULES_HELPER_VCVARS_CMD = "$vcvars_cmd"

    "" | Out-File -FilePath $rebuild_filename -Append
    "pushd ""%HERCULES_HELPER_BUILD_DIR%\$Flavor""" | Out-File -FilePath $rebuild_filename -Append
    "set HERCULES_BUILD_DIR=%cd%\msvc.AMD64.bin" | Out-File -FilePath $rebuild_filename -Append
    "call ""%HERCULES_HELPER_VCVARS_CMD%""" | Out-File -FilePath $rebuild_filename -Append
    "" | Out-File -FilePath $rebuild_filename -Append
    ":: set /P dummy=" | Out-File -FilePath $rebuild_filename -Append
    "call makefile.bat RETAIL-X64 makefile.msvc 8 -title ""*** Hercules-Helper Test Build ***"" -a" | Out-File -FilePath $rebuild_filename -Append
    "" | Out-File -FilePath $rebuild_filename -Append
    "echo on" | Out-File -FilePath $rebuild_filename -Append

    ":: Uncomment line below to run tests" | Out-File -FilePath $rebuild_filename -Append
    ":: call tests\runtest.cmd -n * -t 2 -d ..\$Flavor\tests" | Out-File -FilePath $rebuild_filename -Append
    "" | Out-File -FilePath $rebuild_filename -Append
    "popd" | Out-File -FilePath $rebuild_filename -Append
    "endlocal" | Out-File -FilePath $rebuild_filename -Append
    "" | Out-File -FilePath $rebuild_filename -Append

    # cmd /k "$vcvars_cmd"
    # Invoke-Expression -Command "cmd /c hercules-step2.cmd"
    # cmd.exe /c hercules-step2.cmd 2`>`&1 | Tee-Object -FilePath "hercules-helper-build.log"
    cmd.exe /c hercules-step2.cmd $Flavor $CpuArch.ToUpper() $NoPrompt 2`>`&1 | Tee-Object -Variable dummy

    if ($LASTEXITCODE -ne 0) {
        Write-Output "... BUILD FAILED!"
        Write-Output "LASTEXITCODE from build process: $LASTEXITCODE"
        Write-Output ""
    }

    Write-Output "... back from build steps"
    Write-Output ""

    ##############################################################################
    if ($Firewall.IsPresent) {
        Write-Output '==> Windows Firewall rules'
        if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }

        $hercules_exedir = Resolve-Path "$hercules_dir\$Flavor\msvc.AMD64.bin"
        # Write-Output "Hercules exe directory : $hercules_exedir"
        $hercules_exe = "$hercules_exedir\hercules.exe"

        if (!(Test-Path -Path "$hercules_exe" -PathType leaf )) {
            WriteGreenOutput "$hercules_exe does not exist.  Skipping firewall rules."
        } else {
            Write-Output ""
            Write-Output "Checking for existing Hercules firewall rules... (this may take a while)"

            # $r = Get-NetFirewallRule -DisplayName 'The Hercules 390 Emulator' 2> $null; 
            $r = (( (Get-NetFirewallRule  | Get-NetFirewallApplicationFilter).Program ) -match 'hercules.exe').Length

            if ($r -gt 0) { 
                Write-Output "Existing 'hercules.exe' firewall rules found.  Skipping"; 
            } else { 
                Write-Output "Existing 'hercules.exe' firewall rules NOT found."; 
                Write-Output ""

                do { $input = Read-Host -Prompt "Create Windows Firewall rule for Hercules? [y/N]" }
                until ("", "yes", "no", "YES", "NO", "y", "Y", "n", "N" -ccontains $input)

                if ( $input.ToLower() -eq 'y') {
                    WriteGreenOutput "This phase will not be logged (due to Administrator rights)."

                    $pwd_dir = Resolve-Path "."
                    Start-Process -Wait powershell -Verb RunAs -ArgumentList "-file $pwd_dir\setup-firewall-rules.ps1 $hercules_exe"

                    Write-Output ""
                    Write-Output "Windows Firewall rules have been created."
                    if (!$NoPrompt) { $input = Read-Host -Prompt 'Press return to continue' }
                }
            }
        }
    }

    ##############################################################################
    Write-Output ""
    WriteGreenOutput "Done!"
    Write-Output ""
} finally {
    Stop-Transcript
    Set-Location -Path $startup_dir
}

Write-Output ""
