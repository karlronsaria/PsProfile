function Start-GitPullRequest {
    Param(
        [String]
        $Directory,

        [String]
        $Remote = 'origin',

        [String]
        $Branch = 'master'
    )

    Set-Location $Directory
    Invoke-Expression "git pull"
}

function Start-ScriptModuleGitPullRequest {
    Param(
        [String]
        $Directory = "$PsScriptRoot\..\res"
    )

    $what = Join-Path $Directory 'repo.json' `
        | Get-Item `
        | Get-Content `
        | ConvertFrom-Json

    foreach ($repository in $what.Repository) {
        $path = Join-Path $Directory $repository

        Start-GitPullRequest `
            -Directory $path `
            -Remote $what.DefaultRemote `
            -Branch $what.DefaultBranch
    }
}
