
# From:
# https://gist.github.com/mkropat/c1226e0cc2ca941b23a9

function Add-EnvInclude {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path,

        [ValidateSet('Machine', 'User', 'Session')]
        [string] $Container = 'Session'
    )

    if ($Container -ne 'Session') {
        $containerMapping = @{
            Machine = [EnvironmentVariableTarget]::Machine
            User = [EnvironmentVariableTarget]::User
        }
        $containerType = $containerMapping[$Container]

        $persistedPaths = [Environment]::GetEnvironmentVariable('INCLUDE', $containerType) -split ';'
        if ($persistedPaths -notcontains $Path) {
            $persistedPaths = $persistedPaths + $Path | where { $_ }
            [Environment]::SetEnvironmentVariable('INCLUDE', $persistedPaths -join ';', $containerType)
        }
    }

    $envPaths = $env:Include -split ';'
    if ($envPaths -notcontains $Path) {
        $envPaths = $envPaths + $Path | where { $_ }
        $env:INCLUDE = $envPaths -join ';'
    }
}

Add-EnvInclude -Path "C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Include" -Container "User"

