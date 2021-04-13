# setup-firewall-rules.ps1 -- Part of Hercules-Helper
#
# SDL-Hercules-390 builder
# Updated: 22 FEB 2021
#
# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com

$hercules_exe = $args[0]
Write-Output "setup-firewall-rules.ps1: $hercules_exe"
# $input = Read-Host -Prompt 'Press return to continue'

$hercules_name = 'The Hercules 390 Emulator'
$hercules_desc = 'The Hercules 390 Emulator'

Write-Output 'Create rule: Private TCP Allow'
(New-NetFirewallRule `
    -Group Hercules `
    -DisplayName "$hercules_name" `
    -Description "$hercules_desc" `
    -Program "$hercules_exe" `
    -Enabled True `
    -Direction Inbound `
    -Profile Private `
    -Protocol TCP `
    -Action Allow
  ).Status
Write-Output ''

Write-Output 'Create rule: Private UDP Allow'
(New-NetFirewallRule `
    -Group Hercules `
    -DisplayName "$hercules_name" `
    -Description "$hercules_desc" `
    -Program "$hercules_exe" `
    -Enabled True `
    -Direction Inbound `
    -Profile Private `
    -Protocol UDP `
    -Action Allow
  ).Status
Write-Output ''

Write-Output 'Create rule: Public TCP Block'
(New-NetFirewallRule `
    -Group Hercules `
    -DisplayName "$hercules_name" `
    -Description "$hercules_desc" `
    -Program "$hercules_exe" `
    -Enabled True `
    -Direction Inbound `
    -Profile Public `
    -Protocol TCP `
    -Action Block
  ).Status
Write-Output ''

Write-Output 'Create rule: Public UDP Block'
(New-NetFirewallRule `
    -Group Hercules `
    -DisplayName "$hercules_name" `
    -Description "$hercules_desc" `
    -Program "$hercules_exe" `
    -Enabled True `
    -Direction Inbound `
    -Profile Public `
    -Protocol UDP `
    -Action Block
  ).Status
Write-Output ''

Write-Output "Please note: this step is not included in the log file"
Write-Output "because it is run As Administrator"
Write-Output ""

$input = Read-Host -Prompt 'Press return to continue'

