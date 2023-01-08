. "$PsScriptRoot\Git.ps1"

<#
.LINK
- Url: https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil
- Retrieved: 2023_01_04
#>
function Test-RoleIsAministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole($adminRole)
}

function Get-ProfileLocation {
    return Split-Path $PROFILE -Parent
}

# karlr (2022_02_23)
function Get-ConsoleHostHistory {
    Param(
        [Switch]
        $FilePath
    )

    $path = "$($env:APPDATA)\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

    if ($FilePath) {
        return $path
    }

    cat $path
}

function Run-MyCommand {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $Command,

        [Object[]]
        $ArgumentList
    )

    Invoke-Command `
        -ScriptBlock ([ScriptBlock]::Create($Command.Trim('"'))) `
        -ArgumentList:$ArgumentList
}

function Get-ScriptModuleSourceCommand {
    Param(
        [String]
        $InfoDir,

        [String]
        $StartingDirectory
    )

    if (-not $InfoDir) {
        $InfoDir = "$PsScriptRoot\..\res"
    }

    if (-not $StartingDirectory) {
        $StartingDirectory = "$PsScriptRoot\..\.."
    }

    $command = @"
`$repo = dir '$InfoDir\repo.json' | cat | ConvertFrom-Json;

foreach (`$module in `$repo.ScriptModule) {
    iex "$StartingDirectory\`$module\Get-Scripts.ps1" | % { . `$_ }
};

if ((Test-RoleIsAministrator)) {
    foreach (`$module in `$repo.ElevatedScriptModule) {
        iex "$StartingDirectory\`$module\Get-Scripts.ps1" | % { . `$_ }
    }
};
"@

    return $command
}

New-Alias `
    -Name 'Pull-ScriptModule' `
    -Value 'Start-ScriptModuleGitPullRequest'

New-Alias `
    -Name 'Commit-Quick' `
    -Value 'Invoke-GitQuickCommit'

New-Alias `
    -Name 'Push-Quick' `
    -Value 'Invoke-GitQuickPush'

