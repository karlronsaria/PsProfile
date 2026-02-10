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
        git, npm, deno, cargo, netsh, vera `
    -ScriptBlock {
        Param($wordToComplete, $commandAst, $cursorPosition)
        
        $customCompletions = @{
            # (karlr 2026-01-23)
            'git' = @(
                git --help |
                Select-String "(?<=^ {3})\S+" |
                ForEach-Object Matches |
                ForEach-Object Value
            ) + @(
                'checkout'
            )
            # 'git' = @(
            #     'status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout'
            # )
            'npm' = @('install', 'start', 'run', 'test', 'build')
            # 'npm' = @(npm --help | ForEach-Object { [regex]::Matches($_, "((?<=, )[^, ]+)|([^, ]+(?=,))").Value })
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
            # (karlr 2025-02-27): 'vera' an alias for 'veracrypt'
            'vera' = @(
                '/auto', '/beep', '/cache', '/dismount', '/explore', '/force', '/hash', '/help',
                '/history', '/keyfile', '/letter', '/mountoption', '/password', '/pim', '/quit',
                '/silent', '/tokenpin', '/volume', '/wipecache', '/tryemptypass', '/nowaitdig',
                '/secureDesktop', '/disableDeviceUpdate', '/protectMemory', 'signalExit', '/unmount'
            )
        }

        $elements = $commandAst.CommandElements.Value
        $command = @($elements.Split(' '))[0]
        $suggests = @()
        
        if (@($elements).Count -gt 1) {
            $suggests = switch ($command) {
                'git' {
                    if ($elements[1] -eq 'checkout') {
                        git status *>&1 |
                            Out-String |
                            Where-Object { $_ -notmatch "fatal" } |
                            ForEach-Object { git branch } |
                            ForEach-Object { [Regex]::Match($_, "\S+$").Value } |
                            ForEach-Object {
                                if ($_ -like "* *") {
                                    "`"$_`""
                                }
                                else {
                                    $_
                                }
                            }
                    }

                    break
                }

                'netsh' {
                    if ($elements[1] -eq 'wlan' -and $elements[2] -eq 'connect') {
                        netsh wlan show profiles |
                            Select-String "(?<= : ).*$" |
                            ForEach-Object { $_.Matches.Value } |
                            ForEach-Object {
                                if ($_ -like "* *") {
                                    "`"$_`""
                                }
                                else {
                                    $_
                                }
                            }
                    }

                    break
                }
                
                'vera' {
                    if ($elements[-1] -eq "/letter") {
                        @('A', 'B') + @('D' .. 'Z')
                    }
                    
                    break
                }
            }
        }

        if (@($suggests | Where-Object { $_ }).Count -eq 0) {
            $suggests = if ($customCompletions.ContainsKey($command)) {
                $customCompletions[$command]
            }
        }

        $suggests |
            Where-Object { "$_" -like "$wordToComplete*" } |
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
