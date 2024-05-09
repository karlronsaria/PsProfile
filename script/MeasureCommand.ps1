function ConvertFrom-Json {
    [CmdletBinding(
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=2096606',
        RemotingCapability = 'None'
    )]
    Param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [AllowEmptyString()]
        [String]
        ${InputObject},

        [Switch]
        ${AsHashtable},

        [ValidateRange([System.Management.Automation.ValidateRangeKind]::Positive)]
        [Int]
        ${Depth},

        [Switch]
        ${NoEnumerate}
    )

    Begin {
        try {
            $outBuffer = $null

            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Utility\ConvertFrom-Json',
                [System.Management.Automation.CommandTypes]::Cmdlet
            )

            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline(
                $myInvocation.CommandOrigin
            )

            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }

        if ($null -eq $global:ImportModule_CallCount) {
            $global:ImportModule_CallCount = 0
        }

        $activity = "Calling ``ConvertFrom-Json``..."

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -PercentComplete 0

        $time = [Diagnostics.Stopwatch]::StartNew()
        $list = @()

        Write-Host "PsProfile MeasureCommand: ConvertFrom-Json" `
            -Foreground 'Yellow'
    }

    Process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }

        $list += @($InputObject)
    }

    End {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }

        $global:ImportModule_CallCount++

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -PercentComplete 100 `
            -Complete

        $maxlen = 75
        $json = $list -join ' '
        $json = $json -replace "\s+", " "
        $len = $json.Length

        if ($json.Length -gt $maxlen) {
            $json = "$($json.Substring(0, $maxlen - 3))..."
        }

        Write-Host "  Time: $($time.Elapsed.Milliseconds) ms" `
            -Foreground 'DarkYellow'

        Write-Host "  Json: $json ($len)" `
            -Foreground 'DarkYellow'

        Write-Host "  Number of calls: $global:ImportModule_CallCount" `
            -Foreground 'DarkYellow'
    }

    Clean {
        if ($null -ne $steppablePipeline) {
            $steppablePipeline.Clean()
        }
    }

<#
.ForwardHelpTargetName Microsoft.PowerShell.Utility\ConvertFrom-Json
.ForwardHelpCategory Cmdlet
#>
}

function Import-Module {
    [CmdletBinding(DefaultParameterSetName='Name', HelpUri='https://go.microsoft.com/fwlink/?LinkID=2096585')]
    Param(
        [switch]
        ${Global},

        [ValidateNotNull()]
        [string]
        ${Prefix},

        [Parameter(ParameterSetName='Name', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Parameter(ParameterSetName='PSSession', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Parameter(ParameterSetName='CimSession', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Parameter(ParameterSetName='WinCompat', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string[]]
        ${Name},

        [Parameter(ParameterSetName='FullyQualifiedName', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Parameter(ParameterSetName='FullyQualifiedNameAndPSSession', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Parameter(ParameterSetName='FullyQualifiedNameAndWinCompat', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Microsoft.PowerShell.Commands.ModuleSpecification[]]
        ${FullyQualifiedName},

        [Parameter(ParameterSetName='Assembly', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [System.Reflection.Assembly[]]
        ${Assembly},

        [ValidateNotNull()]
        [string[]]
        ${Function},

        [ValidateNotNull()]
        [string[]]
        ${Cmdlet},

        [ValidateNotNull()]
        [string[]]
        ${Variable},

        [ValidateNotNull()]
        [string[]]
        ${Alias},

        [switch]
        ${Force},

        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='FullyQualifiedName')]
        [Parameter(ParameterSetName='ModuleInfo')]
        [Parameter(ParameterSetName='Assembly')]
        [Parameter(ParameterSetName='PSSession')]
        [Parameter(ParameterSetName='CimSession')]
        [Parameter(ParameterSetName='FullyQualifiedNameAndPSSession')]
        [switch]
        ${SkipEditionCheck},

        [switch]
        ${PassThru},

        [switch]
        ${AsCustomObject},

        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='PSSession')]
        [Parameter(ParameterSetName='CimSession')]
        [Parameter(ParameterSetName='WinCompat')]
        [Alias('Version')]
        [version]
        ${MinimumVersion},

        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='PSSession')]
        [Parameter(ParameterSetName='CimSession')]
        [Parameter(ParameterSetName='WinCompat')]
        [string]
        ${MaximumVersion},

        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='PSSession')]
        [Parameter(ParameterSetName='CimSession')]
        [Parameter(ParameterSetName='WinCompat')]
        [version]
        ${RequiredVersion},

        [Parameter(ParameterSetName='ModuleInfo', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [psmoduleinfo[]]
        ${ModuleInfo},

        [Alias('Args')]
        [System.Object[]]
        ${ArgumentList},

        [switch]
        ${DisableNameChecking},

        [Alias('NoOverwrite')]
        [switch]
        ${NoClobber},

        [ValidateSet('Local','Global')]
        [string]
        ${Scope},

        [Parameter(ParameterSetName='PSSession', Mandatory=$true)]
        [Parameter(ParameterSetName='FullyQualifiedNameAndPSSession', Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.Runspaces.PSSession]
        ${PSSession},

        [Parameter(ParameterSetName='CimSession', Mandatory=$true)]
        [ValidateNotNull()]
        [CimSession]
        ${CimSession},

        [Parameter(ParameterSetName='CimSession')]
        [ValidateNotNull()]
        [uri]
        ${CimResourceUri},

        [Parameter(ParameterSetName='CimSession')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CimNamespace},

        [Parameter(ParameterSetName='WinCompat', Mandatory=$true)]
        [Parameter(ParameterSetName='FullyQualifiedNameAndWinCompat', Mandatory=$true)]
        [Alias('UseWinPS')]
        [switch]
        ${UseWindowsPowerShell}
    )

    Begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Core\Import-Module',
                [System.Management.Automation.CommandTypes]::Cmdlet
            )

            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }

        if ($null -eq $global:ImportModule_CallCount) {
            $global:ImportModule_CallCount = 0
        }

        $activity = "Calling ``Import-Module``..."

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -PercentComplete 0

        $time = [Diagnostics.Stopwatch]::StartNew()
        $list = @()

        Write-Host "PsProfile MeasureCommand: Import-Module" `
            -Foreground 'Yellow'
    }

    Process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }

        $list += @($InputObject)
    }

    End {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }

        $global:ImportModule_CallCount++

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -PercentComplete 100 `
            -Complete

        $maxlen = 75
        $json = $list -join ' '
        $json = $json -replace "\s+", " "
        $len = $json.Length

        if ($json.Length -gt $maxlen) {
            $json = "$($json.Substring(0, $maxlen - 4)) ..."
        }

        Write-Host "  Time: $($time.Elapsed.Milliseconds) ms" `
            -Foreground 'DarkYellow'

        $out = if ($null -ne $Name) {
            "Name: $Name"
        }
        elseif ($null -ne $FullyQualifiedName) {
            "FullyQualifiedName: $FullyQualifiedName"
        }
        elseif ($null -ne $Assembly) {
            "Assembly: $Assembly"
        }
        elseif ($null -ne $ModuleInfo) {
            "ModuleInfo: $ModuleInfo"
        }

        if ($null -ne $out) {
            Write-Host "  $out" `
                -Foreground 'DarkYellow'
        }

        Write-Host "  Number of calls: $global:ImportModule_CallCount" `
            -Foreground 'DarkYellow'
    }

    Clean {
        if ($null -ne $steppablePipeline) {
            $steppablePipeline.Clean()
        }
    }

<#
.ForwardHelpTargetName Microsoft.PowerShell.Core\Import-Module
.ForwardHelpCategory Cmdlet
#>
}

