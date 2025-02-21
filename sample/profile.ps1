$log = "$PsScriptRoot/log/log_-_$(Get-Date -f yyyy-MM-dd)_profile.log" # Uses DateTimeFormat

filter Get-__CommandLog__ {
    Param(
        [ScriptBlock]
        $Command,

        $Measure
    )

    $str = $Command.ToString()
    $milliseconds = "{0:d6}" -f [int][math]::Floor($Measure.TotalMilliseconds)

    if ($Measure.TotalMilliseconds -ge 1000) {
        $substr = if ($str.Length -gt 30) {
            $str.Substring(0, 26) + "... "
        }
        else {
            $str
        }

        Write-Host `
            "Command {" `
            -Foreground 'Green' `
            -NoNewLine

        Write-Host `
            $substr `
            -Foreground 'Magenta' `
            -NoNewLine

        Write-Host `
            "} is being horrible right now." `
            -Foreground 'Green'
    }

    "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff') I: $milliseconds - ````$str````" |
        Out-File -Path $log -Encoding Ascii -Append -Force
}

$loc = "$($env:OneDrive)\Documents\WindowsPowerShell"

$myScripts = @(
    "$loc\Scripts\PsFrivolous\script\Draw.ps1"
    "$loc\Scripts\PsFrivolous\script\PsalmOfTheDay.ps1"
    # # (karlr 2025-01-25)
    "$loc\Scripts\PsFrivolous\script\MoonPhase.ps1"
)

$myScriptModules = @(
    "$loc\Scripts\PsProfile\Get-Scripts.ps1"
    "\shortcut\dos\pwsh\ShortcutGoogleChrome\Get-Scripts.ps1"
)

$commands = @(
    { ipmo Posh-Git }
    # { ipmo Terminal-Icons }
    # { iex (& { zoxide init --cmd z powershell | Out-String }) }
    # { iex (& { zoxide init powershell | Out-String }) }
    # # link: starship
    # # - url: <https://starship.rs/>
    # # - retrieved: 2024-09-22
    # { iex (& starship init powershell) }
    # # link: oh-my-posh theme
    # # - url: <https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json>
    # # - retrieved: 2025-01-25
    { oh-my-posh init pwsh --config "$loc\Scripts\PsProfile\res\oh-my-posh\cobalt2.omp.json" | iex }
    { $myScripts | foreach { . $_ } }
    { $myScriptModules | foreach { iex $_ } | foreach { . $_ } }
    { Get-ScriptModuleSourceCommand -ShowProgress | iex }
)

$commands | foreach -Begin {
    $count = 0
} -Process {
    Write-Progress `
        -Activity 'Loading' `
        -Status $_ `
        -PercentComplete (100 * $count / $commands.Count)

    $measure = Measure-Command $_
    Get-__CommandLog__ -Command $_ -Measure $measure
    $count++
}

Remove-Item -Path function:Get-ScriptModuleSourceCommand
Remove-Item -Path function:Get-__CommandLog__
Remove-Variable -Name commands
Set-PsReadLineOption -EditMode Vi

Write-Progress `
    -Activity 'Loading' `
    -Completed

New-Alias `
    -Name 'gchrome' `
    -Value 'Run-ShortcutGoogleChromeProfile'

New-Alias `
    -Name 'gchromepanic' `
    -Value 'Stop-ShortcutGoogleChrome'

# # Store previous command's output in ``$__``
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'

# # link
# # - url: <https://stackoverflow.com/questions/40098771/changing-powershells-default-output-encoding-to-utf-8>
# # - retrieved: 2023-01-16
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

