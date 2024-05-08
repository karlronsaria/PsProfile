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

    Begin
    {
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

        if ($null -eq $global:ConvertFromJson_CallCount) {
            $global:ConvertFromJson_CallCount = 0
        }

        $activity = "Calling ``ConvertFrom-Json``..."

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -PercentComplete 0

        $time = [Diagnostics.Stopwatch]::StartNew()
    }

    Process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    End
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }

        $global:ConvertFromJson_CallCount++

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -PercentComplete 100 `
            -Complete

        Write-Host "PsProfile MeasureCommand: ConvertFrom-Json" `
            -Foreground 'Yellow'

        Write-Host "  Time: $($time.Elapsed)" `
            -Foreground 'DarkYellow'

        Write-Host "  Number of calls: $global:ConvertFromJson_CallCount" `
            -Foreground 'DarkYellow'
    }

    Clean
    {
        if ($null -ne $steppablePipeline) {
            $steppablePipeline.Clean()
        }
    }

<#
.ForwardHelpTargetName Microsoft.PowerShell.Utility\ConvertFrom-Json
.ForwardHelpCategory Cmdlet
#>
}

