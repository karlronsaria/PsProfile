function New-Closure {
    Param(
        [ScriptBlock]
        $ScriptBlock,

        $Parameters
    )

    return $(& {
Param($Parameters)
return $ScriptBlock.GetNewClosure()
} $Parameters)
}

class ProgressRunner {
    [ScriptBlock[]] $Subscribers
    [String[]] $Names
    [ScriptBlock] $Command

    ProgressRunner() {
        $this.Subscribers = @()
    }

    ProgressRunner([ScriptBlock] $Command) {
        $this.Command = New-Closure `
            -ScriptBlock $Command

        $this.Subscribers = @()
    }

    [ProgressRunner] Add([Hashtable] $Parameters) {
        $this.Names += @($Parameters.Name -join " ")

        $this.Subscribers += @(New-Closure `
            -Parameters ([PsCustomObject]@{
                Command = $this.Command
                BoundParameters = $Parameters `
            }) `
            -ScriptBlock {
$params = $Parameters.BoundParameters
& $Parameters.Command @params
})

        return $this
    }

    [ProgressRunner] Add([ScriptBlock] $Subscriber) {
        $this.Subscribers += @($Subscriber)
        return $this
    }

    [Object[]] Run([String] $Activity) {
        $list = @()

        $this.Subscribers |
        foreach -Begin {
            $count = 0
        } -Process {
            Write-Progress `
                -Activity $Activity `
                -Status $this.Names[$count] `
                -PercentComplete `
                    (100 * $count++ / @($this.Subscribers).Count)

            $temp = $_.Invoke()[0]

            if ($null -ne $temp) {
                $list += @($temp)
            }
        }

        Write-Progress `
            -Activity $Activity `
            -Complete

        if ($list.Count -eq 0) {
            return $null
        }

        return $list
    }
}

function Start-ModuleImportProgressRunner {
    $command = {
        [CmdletBinding(DefaultParameterSetName='Name', HelpUri='https://go.microsoft.com/fwlink/?LinkID=2096585')]
        param(
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

        begin
        {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }

                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Core\Import-Module', [System.Management.Automation.CommandTypes]::Cmdlet)
                $scriptCmd = {& $wrappedCmd @PSBoundParameters }

                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)
            } catch {
                throw
            }
        }

        process
        {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }

        end
        {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }

        clean
        {
            if ($null -ne $steppablePipeline) {
                $steppablePipeline.Clean()
            }
        }
    }

    Set-Variable `
        -Scope Global `
        -Name _Import_Module_Progress_Runner_ `
        -Value ([ProgressRunner]::new($command))

    function global:Import-Module {
        [CmdletBinding(DefaultParameterSetName='Name', HelpUri='https://go.microsoft.com/fwlink/?LinkID=2096585')]
        param(
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

        $_Import_Module_Progress_Runner_.Add($PsBoundParameters) |
            Out-Null
    }
}

function Stop-ModuleImportProgressRunner {
    $_Import_Module_Progress_Runner_.Run(
        "Importing modules"
    )

    Remove-Variable `
        -Scope Global `
        -Name _Import_Module_Progress_Runner_

    function global:Import-Module {
        [CmdletBinding(DefaultParameterSetName='Name', HelpUri='https://go.microsoft.com/fwlink/?LinkID=2096585')]
        param(
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

        begin
        {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }

                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Core\Import-Module', [System.Management.Automation.CommandTypes]::Cmdlet)
                $scriptCmd = {& $wrappedCmd @PSBoundParameters }

                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)
            } catch {
                throw
            }
        }

        process
        {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }

        end
        {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }

        clean
        {
            if ($null -ne $steppablePipeline) {
                $steppablePipeline.Clean()
            }
        }
    }
}

