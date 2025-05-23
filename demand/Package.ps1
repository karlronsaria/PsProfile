<#
Requires: PowerShellGet
- Uses: Get-InstalledModule
- Retrieved: 2023-12-20

Tags: package json installed powershell module
#>
function New-PackageJson {
    Param(
        $Path,

        [Switch]
        $PassThru
    )

    if (-not $Path) {
        $Path = "$PsScriptRoot/../res"
    }

    $getModules = if ($null -ne (
        Get-Command 'Get-InstalledModule' `
            -ErrorAction 'SilentlyContinue'
    )) {
        'Get-Module -ListAvailable'
    }
    else {
        'Get-InstalledModule'
    }

    $list = iex $getModules |
        select Name, Version, Repository, ModuleType |
        foreach {
            [PsCustomObject]@{
                Name = $_.Name
                Version = $_.Version.ToString()
                Repository = $_.Repository
                ModuleType = $_.ModuleType
            }
        }

    if ($PassThru) {
        Write-Output $list
    }

    $obj = [PsCustomObject]@{
        DateTime = Get-Date
        Packages = $list
    }

    $obj `
        | ConvertTo-Json `
        | Out-File (Join-Path $Path "package.json")
}

<#
.DESCRIPTION
Requires: PsTool
- Uses: Out-FileUnix
- Retrieved: 2023-12-20

Tags: choco chocolatey local package list json
#>
function New-ChocoLocalPackageList {
  [CmdletBinding()]
  Param(
    [Alias('Path')]
    [String]
    $FilePath,

    [Switch]
    $PassThru
  )

  $dst = (Get-Content "$PsScriptRoot/../res/setting.json" |
    ConvertFrom-Json).
    Package.
    Choco.
    FileName

  if ([String]::IsNullOrWhiteSpace($FilePath)) {
    $FilePath = Join-Path `
      $(Get-Location).Path `
      $dst
  }

  $command = "choco list"

  $obj =
  [PsCustomObject]@{
    Name = 'chocolatey'
    Packages = $(
      iex $command |
      foreach -Begin {
        $obj = [PsCustomObject]@{}
      } -Process {
        $capture = [Regex]::Match(
          $_, "^(?<name>\S+)\s+(?<version>(\d|\.)+)$"
        )

        if (-not $capture.Success) {
          return
        }

        $obj | Add-Member `
          -MemberType NoteProperty `
          -Name "$($capture.Groups['name'].Value)" `
          -Value "^$($capture.Groups['version'].Value)"
      } -End {
        $obj
      }
    )
  }

  $write = if ($null -ne (
    Get-Command 'Out-FileUnix' `
      -ErrorAction 'SilentlyContinue'
  )) {
    'Out-FileUnix'
  }
  else {
    'Out-File'
  }

  $obj |
    ConvertTo-Json |
    & $write -FilePath $FilePath

  $dir = dir $FilePath

  if ($PassThru) {
    return $([PsCustomObject]@{
      Location = $dir
      Object = $obj
    })
  }

  $dir
}

<#
.DESCRIPTION
Tags: choco chocolatey local package install json
#>
function Install-ChocoLocalPackageList {
  [CmdletBinding()]
  Param(
    [Alias('Path')]
    [String]
    $FilePath,

    [Switch]
    $Confirm
  )

  function Out-Color {
    Param(
      [String]
      $InputObject,

      [Int]
      $Red,

      [Int]
      $Green,

      [Int]
      $Blue
    )

    $esc = [char]27

    $(
      $InputObject.
      GetEnumerator() |
      foreach {
        "$esc[38;2;$Red;$Green;$($Blue)m$_$esc[0m"
      }
    ) -join ""
  }

  $dst = (Get-Content "$PsScriptRoot/../res/setting.json" |
    ConvertFrom-Json).
    Package.
    Choco.
    FileName

  if ([String]::IsNullOrWhiteSpace($FilePath)) {
    $FilePath = Join-Path `
      (Get-Location).Path `
      $dst
  }

  if (-not (Test-Path $FilePath)) {
    $FilePath = "$PsScriptRoot/../res/$dst"
  }

  $packages = (Get-Content $FilePath |
    ConvertFrom-Json).
    Packages

  $command = "choco install$(
    if ($Confirm) {
      " -y"
    }
  )"

  $activity = "Installing Chocolatey package"
  $count = 0

  try {
    foreach ($package in $packages) {
      $progress = @{
        Activity = $activity
        Status = $package.Name
        PercentComplete = 100 * $count / $packages.Count
      }

      Write-Progress @progress
      iex "$command $package"
      $count = $count + 1
    }
  }
  catch {
    throw
  }
  finally {
    Write-Progress `
      -Activity $activity `
      -PercentComplete 100 `
      -Complete

    Out-Color `
      -InputObject `
        "$count/$($packages.Count) packages installed" `
      -Red 255 `
      -Green 255 `
      -Blue 75
  }
}

