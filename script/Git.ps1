function Get-GitPendingRepo {
    Param(
        $Path,

        [ValidateSet('All', 'OnlyRepo', 'OnlyPendingReview')]
        $Show = 'OnlyRepo'
    )

    if (-not $Path) {
        $Path = (Get-Location).Path
    }

    $ignorePattern = "^__|external|InstalledScriptInfos"
    $normalStatusPattern = "fatal: not a git repository"
    $normalStatusCount = 4

    $command =
@"
dir $Path ``
    -Directory |
where {
    `$_.Name -notmatch `"$ignorePattern`"
} |
foreach {
    cd `$_.FullName

    [PsCustomObject]@{
        Name = `$_.Name
        Status = git status 2>&1
        Directory = `$_
    }
} |
where {
    `"`$(`$_.Status)`" -notmatch `"$normalStatusPattern`" -and
    `$_.Status.Count -notin @($normalStatusCount)
} |
ConvertTo-Json
"@

    Write-Progress `
        -Id 1 `
        -Activity "Running PowerShell subshell" `
        -PercentComplete 50 `

    $repoTest = powershell -NoProfile -Command $command |
        ConvertFrom-Json

    Write-Progress `
        -Id 1 `
        -Activity "Running PowerShell subshell" `
        -Complete

    $repoTest |
    foreach {
        $_.Status =
            if ($null -ne $_.Status.Exception) {
                'NoRepo'
            }
            elseif (@($_.Status)[-1] -match "nothing to commit, working tree clean") {
                'UpToDate'
            }
            else {
                'PendingReview'
            }
    }

    return $(
        switch ($Show) {
            'All' {
                $repoTest
            }

            'OnlyRepo' {
                $repoTest |
                where {
                    $_.Status -ne 'NoRepo'
                }
            }

            'OnlyPendingReview' {
                $repoTest |
                where {
                    $_.Status -eq 'PendingReview'
                }
            }
        }
    )

    return $repoTest
}

function Invoke-GitPullRequest {
    Param(
        [String]
        $Directory,

        [String]
        $Remote = (Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultRemote,

        [String]
        $Branch = (Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultBranch,

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
        $JsonFilePath = "$PsScriptRoot\..\res\repo.setting.json",

        [String]
        $StartingDirectory = "$PsScriptRoot\..\..",

        [Switch]
        $WhatIf
    )

    $what = dir $JsonFilePath | Get-Content | ConvertFrom-Json
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
        $Message = (Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).QuickCommitMessage,

        [Switch]
        $WhatIf
    )

    $cmd = "git add .; git commit -m `"$Message`""

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}

function Invoke-GitQuickPush {
    Param(
        [String]
        $Message = (Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
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

function Get-GitCurrentBranch {
    $branchInfo = Invoke-Expression "git branch"

    if ($null -eq $branchInfo) {
        return
    }

    if (@($branchInfo).Count -gt 1) {
        $branchInfo = @($branchInfo | where { $_ -match "^\* " })[0]
    }

    return [Regex]::Match($branchInfo, "(\w|\d)+")
}

function Get-GitLateralBranches {
    Param(
        [Switch]
        $LocalGitSettings
    )

    $settings = Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
        | ConvertFrom-Json

    $localFilePath = Join-Path `
        (Get-Location).Path `
        $settings.LocalGitSettingsFileName

    $lateralBranches =
        if ($LocalGitSettings -and (Test-Path $localFilePath)) {
            $local = Get-Content $localFilePath | ConvertFrom-Json
            @($local.Lateral | where { $_ -ne $currentBranch })
        } else {
            @()
        }

    return $lateralBranches
}

function Invoke-GitQuickMerge {
    Param(
        [String]
        $MasterBranch = (Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultBranch,

        [String]
        $Remote = (Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultRemote,

        [Switch]
        $WhatIf,

        [Switch]
        $IgnoreLocalGitSettings
    )

    $capture = Get-GitCurrentBranch

    if (-not $capture.Success) {
        Write-Output "Branch name could not be captured"
        git branch
        return
    }

    $currentBranch = $capture.Value

    $lateralBranches = Get-GitLateralBranches `
        -LocalGitSettings:$(-not $IgnoreLocalGitSettings)

    $cmd = @(
        "git checkout $MasterBranch"
        "git pull"
        "git merge $currentBranch"
        "git push $Remote $MasterBranch"
    )

    foreach ($branch in $lateralBranches) {
        $cmd += @(
            "git checkout $branch"
            "git pull $Remote $currentBranch"
            "git push $Remote $branch"
        )
    }

    $cmd += @(
        "git checkout $currentBranch"
    )

    if ($WhatIf) {
        return $cmd
    }

    $cmd | foreach {
        Invoke-Expression $_
    }
}

function Invoke-GitLateralPull {
    Param(
        [String]
        $Remote = (Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultRemote,

        [Switch]
        $WhatIf,

        [Switch]
        $IgnoreLocalGitSettings
    )

    $capture = Get-GitCurrentBranch

    if (-not $capture.Success) {
        Write-Output "Branch name could not be captured"
        git branch
        return
    }

    $currentBranch = $capture.Value

    $lateralBranches = Get-GitLateralBranches `
        -LocalGitSettings:$(-not $IgnoreLocalGitSettings)

    foreach ($branch in $lateralBranches) {
        $cmd += @(
            "git checkout $branch"
            "git pull $Remote $branch"
        )
    }

    $cmd += @(
        "git checkout $currentBranch"
    )

    if ($WhatIf) {
        return $cmd
    }

    $cmd | foreach {
        Invoke-Expression $_
    }
}

function Invoke-GitReplaceBranchContent {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            return git status *>&1 |
                Out-String |
                where { $_ -notmatch "fatal" } |
                foreach { git branch } |
                foreach { [Regex]::Match($_, "\S+$").Value } |
                where { $_ -like "$C*" }
        })]
        [String]
        $Branch,

        [String]
        $Source = (Get-Location).Path,

        [String]
        $Message = (Get-Content "$PsScriptRoot\..\res\repo.setting.json" |
            ConvertFrom-Json).QuickCommitMessage,

        [Switch]
        $WhatIf,

        [Switch]
        $NoRemoveTemp,

        [Switch]
        $NoConfirm
    )

    $capture = Get-GitCurrentBranch

    if (-not $capture.Success) {
        Write-Output "Branch name could not be captured"
        git branch
        return
    }

    $currentBranch = $capture.Value

    $settings = Get-Content "$PsScriptRoot\..\res\repo.setting.json" `
        | ConvertFrom-Json

    $temp = $settings.TempPath
    $temp = iex "& { $temp }"

    $cmd = @()

    if (-not (Test-Path $temp)) {
        $cmd += @("mkdir $temp -Force")
    }

    $dateStr = Get-Date -f 'yyyy_MM_dd'
    $dst = Join-Path $temp $dateStr

    if (-not (Test-Path $dst)) {
        $cmd += @("mkdir $dst -Force")
    }

    $parent = $dst
    $container = Split-Path $Source -Leaf
    $dst = Join-Path $dst $container

    if ((Test-Path $dst)) {
        $cmd += @("Remove-Item $dst -Recurse -Force")
    }

    $cmd += @("git clone $Source $dst")
    $cmd += @("Push-Location $dst")
    $cmd += @("git checkout $Branch")

    $cmd += @"
Get-ChildItem "$dst\*.*" -Recurse ``
    | ? Name -ne ".git" ``
    | Remove-Item -Recurse
Get-ChildItem $dst -Recurse ``
    | ? Name -ne ".git" ``
    | Remove-Item -Recurse
Get-ChildItem $Source ``
    | ? Name -ne ".git" ``
    | Copy-Item ``
        -Destination $dst ``
        -Recurse ``
        -Force
"@

    $needConfirm += Invoke-GitQuickPush `
        -Message:$Message `
        -WhatIf

    $afterConfirm = @("Pop-Location")

    if (-not $NoRemoveTemp) {
        $afterConfirm += @("Remove-Item $dst -Recurse -Force")
    }

    if ($WhatIf) {
        return $cmd + $needConfirm + $afterConfirm
    }

    $cmd | foreach {
        Invoke-Expression $_
    }

    if (-not $NoConfirm) {
        Write-Output ""
        Write-Output "Confirm"
        Write-Output "Do you want to push changes for branch '$Branch'?"

        $confirmMessage = @"
[Y] Yes  [N] No
(default is "Y")
"@

        do {
            $confirm = Read-Host $confirmMessage
        }
        while ($confirm.ToUpper() -notin @('N', 'Y'));

        if ($confirm -eq 'Y') {
            $needConfirm | foreach {
                Invoke-Expression $_
            }
        }

        $afterConfirm | foreach {
            Invoke-Expression $_
        }
    }
}

