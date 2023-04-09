function New-PackageJson {
    Param(
        $Path,

        [Switch]
        $PassThru
    )

    if (-not $Path) {
        $Path = "$PsScriptRoot/../res"
    }

    $list = Get-InstalledModule `
        | select Name, Version, Repository `
        | foreach {
            [PsCustomObject]@{
                Name = $_.Name
                Version = $_.Version.ToString()
                Repository = $_.Repository
            }
        }

    if ($PassThru) {
        Write-Output $list
    }

    $list `
        | ConvertTo-Json `
        | Out-File (Join-Path $Path "package.json")
}
