. "$PsScriptRoot\Scripts\ActionItem.ps1"
. "$PsScriptRoot\Scripts\PsalmOfTheDay.ps1"
. "$PsScriptRoot\Scripts\Frivolous.ps1" # Imports Posh-Git module

# First script module
& "$PsScriptRoot\Scripts\PsProfile\Get-Scripts.ps1" | % { . $_ }
& "\shortcut\dos\ps\ShortcutGoogleChrome\Get-Scripts.ps1" | % { . $_ }

New-Alias `
    -Name 'gchrome' `
    -Value 'Run-ShortcutGoogleChromeProfile'

# Store previous command's output in `$__`
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'

# link
# - url: https://stackoverflow.com/questions/40098771/changing-powershells-default-output-encoding-to-utf-8
# - retrieved: 2023_01_16
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

Invoke-Expression (Get-ScriptModuleSourceCommand)

Set-PsReadLineOption -EditMode Vi
