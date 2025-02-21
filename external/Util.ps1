<#
.LINK
Description: ChrisTitusTech powershell-profile
Url: <https://github.com/ChrisTitusTech/powershell-profile>
Retrieved: 2025-01-24
#>

# Custom completion for common commands
Register-ArgumentCompleter `
    -Native `
    -CommandName git, npm, deno, cargo `
    -ScriptBlock {
        Param($wordToComplete, $commandAst, $cursorPosition)

        $customCompletions = @{
            'git' = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout')
            'npm' = @('install', 'start', 'run', 'test', 'build')
            'deno' = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
            'cargo' = @(
                'build', 'check', 'clean', 'doc', 'new', 'init', 'add', 'remove', 'run', 'test', 'bench',
                'update', 'search', 'publish', 'install', 'uninstall'
            )
        }

        $command = $commandAst.CommandElements[0].Value

        if ($customCompletions.ContainsKey($command)) {
            $customCompletions[$command] |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        }
    }

Register-ArgumentCompleter `
    -Native `
    -CommandName dotnet `
    -ScriptBlock {
        Param($wordToComplete, $commandAst, $cursorPosition)

        dotnet complete --position $cursorPosition $commandAst.ToString() |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
    }

function Move-ItemToRecyleBin {
    Param(
        [Parameter(ValueFromPipeline)]
        $Path
    )

    Process {
        foreach ($subitem in @($Path)) {
            $fullPath = (Resolve-Path -Path $subitem).Path

            if (-not (Test-Path $fullPath)) {
                Write-Output "Error: Item '$fullPath' does not exist."
                return
            }

            $item = Get-Item $fullPath

            if ($null -eq $item) {
                Write-Output "Error: Could not find the item '$fullPath' to trash."
                return
            }

            $parentPath = Split-Path $fullPath -Parent
            $shell = New-Object -ComObject 'Shell.Application'

            $shellItem = $shell.
                NameSpace($parentPath).
                ParseName($item.Name)

            $shellItem.InvokeVerb('delete')
            Write-Output "'$fullPath' has been moved to the Recycle Bin."
        }
    }
}

function Clear-Cache {
    Param(
        [Switch]
        $WhatIf
    )

    # Add clear-cache logic here
    Write-Output "$($PsStyle.Foreground.Cyan)Clearing cache...$($PsStyle.Reset)"

    # Clear Windows Prefetch
    Write-Output "$($PsStyle.Foreground.Yellow)Clearing Windows Prefetch...$($PsStyle.Reset)"

    Remove-Item `
        -Path "$env:SystemRoot\Prefetch\*" `
        -Force `
        -ErrorAction SilentlyContinue `
        -WhatIf:$WhatIf

    # Clear Windows Temp
    Write-Output "$($PsStyle.Foreground.Yellow)Clearing Windows Temp...$($PsStyle.Reset)"

    Remove-Item `
        -Path "$env:SystemRoot\Temp\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue `
        -WhatIf:$WhatIf

    # Clear User Temp
    Write-Output "$($PsStyle.Foreground.Yellow)Clearing User Temp...$($PsStyle.Reset)"

    Remove-Item `
        -Path "$env:TEMP\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue `
        -WhatIf:$WhatIf

    # Clear Internet Explorer Cache
    Write-Output "$($PsStyle.Foreground.Yellow)Clearing Internet Explorer Cache...$($PsStyle.Reset)"

    Remove-Item `
        -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue `
        -WhatIf:$WhatIf

    Write-Output "$($PsStyle.Foreground.Green)Cache clearing completed.$($PsStyle.Reset)"
}

