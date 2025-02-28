<#
.LINK
Description: ChrisTitusTech powershell-profile
Url: <https://github.com/ChrisTitusTech/powershell-profile>
Retrieved: 2025-01-24
#>

# Custom completion for common commands
Register-ArgumentCompleter `
    -Native `
    -CommandName `
        git, npm, deno, cargo, netsh `
    -ScriptBlock {
        Param($wordToComplete, $commandAst, $cursorPosition)

        $customCompletions = @{
            'git' = @(
                'status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout'
            )
            'npm' = @('install', 'start', 'run', 'test', 'build')
            'deno' = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
            'cargo' = @(
                'build', 'check', 'clean', 'doc', 'new', 'init', 'add', 'remove', 'run', 'test', 'bench',
                'update', 'search', 'publish', 'install', 'uninstall'
            )
            # (karlr 2025-02-27)
            'netsh' = @(
                'wlan', 'show', 'connect', 'disconnect', 'profiles', 'add', 'delete', 'set', 'exec',
                'trace', 'interface'
            )
        }

        $elements = $commandAst.CommandElements.Value
        $command = $elements[0]
        $suggests = @()

        if (@($elements).Count -gt 1) {
            $suggests = switch ($command) {
                'git' {
                    if ($elements[1] -ne 'checkout') {
                        break
                    }

                    git status *>&1 |
                        Out-String |
                        where { $_ -notmatch "fatal" } |
                        foreach { git branch } |
                        foreach { [Regex]::Match($_, "\S+$").Value } |
                        foreach { "`"$_`"" }

                    break
                }

                'netsh' {
                    if ($elements[1] -ne 'wlan' -or $elements[2] -ne 'connect') {
                        break
                    }

                    netsh wlan show profiles |
                        Select-String "(?<= : ).*$" |
                        foreach { $_.Matches.Value } |
                        foreach { "`"$_`"" }

                    break
                }
            }
        }

        if (@($suggests | where { $_ }).Count -eq 0) {
            $suggests = if ($customCompletions.ContainsKey($command)) {
                $customCompletions[$command]
            }
        }

        $suggests |
            Where-Object { "$_" -match "^`"?$wordToComplete.*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }

        # # (karlr 2025-02-27)
        #
        # if ($customCompletions.ContainsKey($command)) {
        #     $customCompletions[$command] |
        #     Where-Object { "$_" -match "^`"?$wordToComplete.*" } |
        #     ForEach-Object {
        #         [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        #     }
        # }
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

