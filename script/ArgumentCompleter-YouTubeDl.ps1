Register-ArgumentCompleter `
    -Native `
    -Command `
        'yt-dlp', 'yt-dlp.exe' `
    -ScriptBlock {
        Param($wordToComplete, $commandAst, $cursorPosition)

        $commands = $commandAst.CommandElements.Extent.Text

        $help = "$PsScriptRoot/../res/yt-dlp.man" |
            Get-Item |
            Get-Content |
            Where-Object { $_ -notlike "#*" } |
            Select-String "(?<=^\s{4})-((\S+ )+(?= )|(\S+ )*(\S+$))" |
            ForEach-Object Matches |
            ForEach-Object Value |
            ForEach-Object {
                $split = $_.Split(', ').Trim()
                $count = @($split).Count
                $params = @($split)[-1].Split(' ').Trim()
                $long = @($params)[0]
                $params = @(@($params) | Select-Object -Skip 1)

                [pscustomobject]@{
                    Short = if ($count -eq 1) { $null } else { @($split)[0] }
                    'Long' = $long
                    Params = $params
                }
            }

        if ($wordToComplete -like "-*") {
            return (@($help.Long) + @($help.Short)) |
                Where-Object {
                    $_ -like "$wordToComplete*"
                }
        }

        if (@($commands).Count -gt 1) {
            $command = $commands[-1]

            if ($command -in @('-f', '--format')) {
                return @(
                    'bestvideo+bestaudio'
                    'bestaudio'
                    'bestvideo'
                )
            }

            if ($command -eq '--cookies-from-browser') {
                # link: compatible browsers
                # - url: <https://www.reddit.com/r/youtubedl/comments/1klrnfl/ytdlp_wont_download/>
                # - retrieved: 2026-02-21
                return @(
                    'firefox'
                    'brave'
                    'edge'
                    'opera'
                    'safari'
                    'vivaldi'
                    'whale'
                    'chrome'
                    'chromium'
                )
            }
        }

        $url = 'https://www.youtube.com/watch?v='
        $shorts_url = 'https://www.youtube.com/shorts/'
        return "$url$($wordToComplete.Replace($url, '').Replace($shorts_url, ''))"
    }

