function Invoke-GitPullRequest {
    Param(
        [String]
        $Directory,

        [String]
        $Remote = 'origin',

        [String]
        $Branch = 'master',

        [Switch]
        $WhatIf
    )

    Set-Location $Directory
    $cmd = "git pull $Remote $Branch"

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}

function Invoke-ScriptModuleGitPullRequest {
    Param(
        [String]
        $JsonFilePath = "$PsScriptRoot\..\res\repo.json",

        [String]
        $StartingDirectory = "$PsScriptRoot\..\..",

        [Switch]
        $WhatIf
    )

    $what = dir $JsonFilePath | cat | ConvertFrom-Json
    $prevDir = Get-Location

    foreach ($repository in $what.Repository) {
        $path = Join-Path $StartingDirectory $repository

        Invoke-GitPullRequest `
            -Directory $path `
            -Remote $what.DefaultRemote `
            -Branch $what.DefaultBranch `
            -WhatIf:$WhatIf
    }

    $prevDir | Set-Location
}

function Invoke-GitQuickCommit {
    Param(
        [String]
        $Message = (cat "$PsScriptRoot\..\res\repo.json" `
            | ConvertFrom-Json).QuickCommitMessage,

        [Switch]
        $WhatIf
    )

    $cmd = "git commit -am `"$Message`""

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}

function Invoke-GitQuickPush {
    Param(
        [String]
        $Message = (cat "$PsScriptRoot\..\res\repo.json" `
            | ConvertFrom-Json).QuickCommitMessage,

        [Switch]
        $WhatIf
    )

    Invoke-GitQuickCommit `
        -Message $Message `
        -WhatIf:$WhatIf

    $cmd = "git push"

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}





