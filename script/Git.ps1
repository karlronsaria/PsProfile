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
        $JsonFilePath = "$PsScriptRoot\..\res\repo.json",

        [String]
        $StartingDirectory = "$PsScriptRoot\..\.."
    )

    $what = dir $JsonFilePath | cat | ConvertFrom-Json

    foreach ($repository in $what.Repository) {
        $path = Join-Path $StartingDirectory $repository

        Start-GitPullRequest `
            -Directory $path `
            -Remote $what.DefaultRemote `
            -Branch $what.DefaultBranch
    }
}
