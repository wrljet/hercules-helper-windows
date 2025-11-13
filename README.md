# Hercules-Helper (Windows 10 64-bit version)

(preliminary Windows instructions)

Utility scripts to help with building and deploying the Hercules emulator

This is a testbed and will be updated occassionally and/or merged
into SDL-Hercules-390 and/or Hercules Aethra and their documentation
when completed.

The most recent version of this project can be obtained with:
```
   git clone https://github.com/wrljet/hercules-helper-windows.git
```
or, if you don't have git, or simply prefer:
```
   wget https://github.com/wrljet/hercules-helper-windows/archive/master.zip
```

Report errors in this to me so everyone can benefit.

Every attempt has been made to test this process, but better to be safe
than sorry.  BACK UP YOUR SYSTEM before running any of this!

**Please do not run this entire process as Administrator.  That can be damaging.
Windows will prompt for your permissions where required.**

(I don't really want to support Windows 7, but it does seem to work with
PowerShell 5.1 and VS2017)

## hercules-buildall.ps1

This PowerShell script will perform a complete build of Hercules and its external
packages, and run all the automated tests.  It will also install Visual Studio
2017, 2019, 2022, or 2026, or update an existing Visual Studio installation to add only
any require workloads that are missing.

The full process is:

### Step 1:

You will need a modern version of PowerShell, such as version 7.x.
PowerShell releases may be found in the Microsoft GitHub repo:

```
    https://github.com/PowerShell/PowerShell/releases
```

For Windows 7, PowerShell 5.1 may be found here (note: link may only work with Microsft Edge or IE):
```
    https://www.microsoft.com/en-us/download/details.aspx?id=54616&6B49FDFB-8E5B-4B07-BC31-15695C5A2143=1
```

Out of the box, a fresh Windows 10 installation will not allow you to run
PowerShell scripts, for security reasons.  We need to relax that.
This step will only need to be performed once, the first time you
use Hercules-Helper.

Open a PowerShell prompt "As Administrator", and run:

```
Set-ExecutionPolicy RemoteSigned
```
Answer Yes when prompted.

For Windows 7 and PowerShell 5.1, also run:
```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

Close the PowerShell window.

### Step 2:

Get the Hercules-Helper project onto your system.

This can be done by navigating a web browser to GitHub and downloading
from there.  Put the zipfile in a convenient place on your filesystem.

Sometimes when files are copied to Windows, it will decide they have
come from an untrusted remote system, and a directory bit will be set
to remember this fact.  This will cause Windows to not allow them to
be executed.

Right-click on the hercules-helper.zip file and select Properties.
At the bottom ofthe Properties dialog, you may see a warning about
the file coming from a remote system.   Click the button to Unblock
the file.  Close this dialog.

Unzip the file someplace where you wish to work.
Such as:

```
C:\hercules-helper
```

### Step 3:

After building Hercules, this process will run the automated tests.
Doing so requires REXX support.  So REXX must be installed before
we get to that point.  We will install ooRexx.

Navigate to hercules-helper-windows\goodies, where you will find
the ooRexx-5.0.0-12583.windows.x86_64.exe installer.

Run the installer.  I've found just accepting all the defaults
works well.

This of course only needs to be done once, the first time you use
Hercules-Helper.

### Step 4:

Open a PowerShell window and cd to your directory where you unzipped
Hercules-Helper.  And cd into the windows subdirectory.

Decide where you want Hercules to be built.  In this example I am using C:\hercules.

Decide if you prefer to use Visual Studio 2017, 2019, or 2022.


```
cd c:\hercules-helper-windows
.\hercules-buildall.ps1 -VS2017 -BuildDir c:\hercules
```

The ```-Flavor``` option may be used to build from among the various forks
of Hercules 4. Presently, Aethra and SDL-Hyperion are supported.  For example:

```
.\hercules-buildall.ps1 -VS2017 -BuildDir c:\hercules -Flavor Aethra
```

If the ```-GitBranch``` option is specified, a branch other
than ```master``` may be checked-out.
Such as:

```
.\hercules-buildall.ps1 -VS2017 -BuildDir c:\hercules -Flavor SDL-Hyperion -GitBranch develop
```

Similarly, the ```-GitCommit``` option is specified, a specific commit
may be checked-out.

The script will not overwrite an existing git clone directory,
to protect local changes you may have.  To force an overwrite,
add the ```-ForceClone``` option to the command line.

Say you wanted to be able to build Hercules without committing changes to your clone of
the SDL Hyperion repo...

Use the ```-SourceDir``` option to specify the location of the directory where the source code
should be copied from. After the copying, all processing is just the same as if the
code had been cloned from GitHub.  Thank you to Ross Patterson for this feature.

```-SourceDir``` is mutually incompatible with ```-GitRepo```, ```-GitBranch```, and ```-GitCommit```,
and the code reports an error and quits if they are specified together.

If the ```-Firewall``` option is specified, Windows Firewall rules
to allow Hercules will be added.

```-NoPrompt``` will skip the 'Press return to continue' prompts
except for overwriting an existing repo.  Thank you to Ross Patterson for this feature.

If the ```-DebugInfo``` option is specified debugging information
will be output along the way.

From here on everything should be completely automatic.

You will be prompted to hit the Enter key a number of times,
with prompts informing you what the next part of the process
will be.  And you will need to answer Yes to Admin rights for
a few of the operations.  Part way through, it will shift from
PowerShell to a "DOS" command shell to run the actual builder.

If anything seems to go wrong, please stop and ask questions at that point.
Your repair attempts may destroy evidence that would be useful in improving
this process for others.

Enjoy!

