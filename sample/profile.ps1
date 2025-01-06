Import-Module Posh-Git

$loc = "$($env:OneDrive)\Documents\WindowsPowerShell"

$myScripts = @(
    "$loc\Scripts\PsFrivolous\script\Draw.ps1"
    "$loc\Scripts\PsFrivolous\script\PsalmOfTheDay.ps1"
)

$myScriptModules = @(
    "$loc\Scripts\PsProfile\Get-Scripts.ps1"
    "\shortcut\dos\pwsh\ShortcutGoogleChrome\Get-Scripts.ps1"
)

$myScripts | foreach { . $_ }
$myScriptModules | foreach { iex $_ } | foreach { . $_ }

New-Alias `
    -Name 'gchrome' `
    -Value 'Run-ShortcutGoogleChromeProfile'

New-Alias `
    -Name 'gchromepanic' `
    -Value 'Stop-ShortcutGoogleChrome'

# Store previous command's output in `$__`
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'

# link
# - url: <https://stackoverflow.com/questions/40098771/changing-powershells-default-output-encoding-to-utf-8>
# - retrieved: 2023_01_16
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# (karlr 2024_09_22)
# link
# - url: <https://starship.rs/>
# - retrieved: 2024_09_22
Invoke-Expression (& starship init powershell)

Invoke-Expression (Get-ScriptModuleSourceCommand -ShowProgress)
Remove-Item -Path function:Get-ScriptModuleSourceCommand
Set-PsReadLineOption -EditMode Vi

