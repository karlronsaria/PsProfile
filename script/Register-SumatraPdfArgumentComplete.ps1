<#
.LINK
Url: <https://www.sumatrapdfreader.org/docs/Command-line-arguments>
Retrieved: 2026-02-04
#>

Register-ArgumentCompleter `
    -Native `
    -Command `
        sumatra, "sumatra.bat" `
    -ScriptBlock {
        Param($wordToComplete, $commandAst, $cursorPosition)

        $options = @(
            "-presentation",
            "-fullscreen",
            "-new-window",
            "-appdata",
            "-restrict",

            "-named-dest",
            "-page",
            "-view",

            "-reuse-instance",
            "-zoom",
            "-scroll",
            "-search",
            "-dde",
            "-print-to-default",
            "-print-to",
            "-forward-search",
            "-inverse-search",
            "-fwdsearch-offset",
            "-fwdsearch-width",
            "-fwdsearch-color",
            "-fwdsearch-permanent",

            "-console",
            "-stress-test",
            "-bench",

            "-h",
            "--help"
        )
        
        $whenPrint = @(
            "-print-settings",
            "-silent",
            "-print-dialog",
            "-exit-when-done"
        )
        
        $views = @(
            "single page",
            "continuous single page",
            "facing",
            "continuous facing",
            "book view",
            "continuous book view"
        )
        
        $printSetting = @(
            "even",
            "odd",
            "portrait",
            "landscape",
            "noscale",
            "shrink",
            "fit",
            "color",
            "monochrome",
            "duplex",
            "duplexshort",
            "duplexlong",
            "simplex",
            "bin=",
            "paper=A2",
            "paper=A3",
            "paper=A4",
            "paper=A5",
            "paper=A6",
            "paper=letter",
            "paper=legal",
            "paper=tabloid",
            "paper=statement"
        )

        $commands = $commandAst.CommandElements.Extent.Text
        
        $all = $options | Where-Object {
            $_ -notin $commands
        }
        
        if (@($commands) -contains '-print-default' -or @($commands) -contains '-print-to') {
            $all += @($whenPrint)
        }
        
        if (@($commands).Count -gt 1) {
            $command = $commands[-1]
            
            switch ($command) {
                '-page' {
                    return '1'
                }

                '-appdata' {
                    return (Get-ChildItem)
                }
                
                '-named-dest' {
                    return (Get-ChildItem)
                }

                '-view' {
                    return $(
                        $views |
                        ForEach-Object {
                            if ($_ -like "* *") {
                                "`"$_`""
                            }
                            else {
                                $_
                            }
                        }
                    )
                }
                
                '-zoom' {
                    return $(
                        0 .. 10 | ForEach-Object { 10 * $_ }
                        1 .. 10 | ForEach-Object { 100 + 50 * $_ }
                        @("`"fit page`"", "`"fit width`"", "`"fit content`"")
                    )
                }
                
                '-scroll' {
                    return "0,0"
                }
                
                '-search' {
                    return (Get-ChildItem)
                }
                
                '-dde' {
                    return "'[]'"
                }
                
                '-print-to' {
                    return $(
                        wmic printer get Name |
                            Select-Object -Skip 1 |
                            Where-Object { $_ } |
                            ForEach-Object { "`"$($_.Trim())`"" }
                    )
                }
                
                '-print-settings' {
                    return "`"`""
                }
                
                '-stress-test' {
                    return (Get-ChildItem)
                }

                '-bench' {
                    return (Get-ChildItem)
                }
            }
        }
        
        if ($wordToComplete -like "-*") {
            return @(
                $all |
                Where-Object { "$_" -like "$wordToComplete*" } |
                ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            )
        }

        $suggests = $(
            Write-Progress `
                -Activity "Searching for PDF's" `
                -PercentComplete 0 |
                Out-Null

            Get-ChildItem /lit/*.pdf, /doc/*.pdf, /note/*.pdf -Recurse |
            ForEach-Object FullName |
            ForEach-Object {
                if ($_ -like "* *") {
                    "`"$_`""
                }
                else {
                    $_
                }
            }

            Write-Progress `
                -Activity "Searching for PDF's" `
                -Completed |
                Out-Null
        )
        
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
    }
