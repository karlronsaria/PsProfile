function Invoke-WebRequest {
<#
.ForwardHelpTargetName Microsoft.PowerShell.Utility\Invoke-WebRequest
.ForwardHelpCategory Cmdlet
#>

    [CmdletBinding(DefaultParameterSetName='StandardMethod', HelpUri='https://go.microsoft.com/fwlink/?LinkID=2097126')]
    param(
        [switch]
        ${UseBasicParsing},

        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [uri]
        ${Uri},

        [version]
        ${HttpVersion},

        [Microsoft.PowerShell.Commands.WebRequestSession]
        ${WebSession},

        [Alias('SV')]
        [string]
        ${SessionVariable},

        [switch]
        ${AllowUnencryptedAuthentication},

        [Microsoft.PowerShell.Commands.WebAuthenticationType]
        ${Authentication},

        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [switch]
        ${UseDefaultCredentials},

        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint},

        [ValidateNotNull()]
        [X509Certificate]
        ${Certificate},

        [switch]
        ${SkipCertificateCheck},

        [Microsoft.PowerShell.Commands.WebSslProtocol]
        ${SslProtocol},

        [securestring]
        ${Token},

        [string]
        ${UserAgent},

        [switch]
        ${DisableKeepAlive},

        [Alias('TimeoutSec')]
        [ValidateRange(0, 2147483647)]
        [int]
        ${ConnectionTimeoutSeconds},

        [ValidateRange(0, 2147483647)]
        [int]
        ${OperationTimeoutSeconds},

        [System.Collections.IDictionary]
        ${Headers},

        [switch]
        ${SkipHeaderValidation},

        [switch]
        ${AllowInsecureRedirect},

        [ValidateRange(0, 2147483647)]
        [int]
        ${MaximumRedirection},

        [ValidateRange(0, 2147483647)]
        [int]
        ${MaximumRetryCount},

        [switch]
        ${PreserveAuthorizationOnRedirect},

        [ValidateRange(1, 2147483647)]
        [int]
        ${RetryIntervalSec},

        [Parameter(ParameterSetName='StandardMethod')]
        [Parameter(ParameterSetName='StandardMethodNoProxy')]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        ${Method},

        [Parameter(ParameterSetName='CustomMethod', Mandatory=$true)]
        [Parameter(ParameterSetName='CustomMethodNoProxy', Mandatory=$true)]
        [Alias('CM')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${CustomMethod},

        [switch]
        ${PreserveHttpMethodOnRedirect},

        [ValidateNotNullOrEmpty()]
        [System.Net.Sockets.UnixDomainSocketEndPoint]
        ${UnixSocket},

        [Parameter(ParameterSetName='CustomMethodNoProxy', Mandatory=$true)]
        [Parameter(ParameterSetName='StandardMethodNoProxy', Mandatory=$true)]
        [switch]
        ${NoProxy},

        [Parameter(ParameterSetName='StandardMethod')]
        [Parameter(ParameterSetName='CustomMethod')]
        [uri]
        ${Proxy},

        [Parameter(ParameterSetName='StandardMethod')]
        [Parameter(ParameterSetName='CustomMethod')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${ProxyCredential},

        [Parameter(ParameterSetName='StandardMethod')]
        [Parameter(ParameterSetName='CustomMethod')]
        [switch]
        ${ProxyUseDefaultCredentials},

        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        ${Body},

        [System.Collections.IDictionary]
        ${Form},

        [string]
        ${ContentType},

        [ValidateSet('chunked','compress','deflate','gzip','identity')]
        [string]
        ${TransferEncoding},

        [ValidateNotNullOrEmpty()]
        [string]
        ${InFile},

        [ValidateNotNullOrEmpty()]
        [string]
        ${OutFile},

        [switch]
        ${PassThru},

        [switch]
        ${Resume},

        [switch]
        ${SkipHttpErrorCheck}
    )

    begin
    {
        $logPath = "$PsScriptRoot/../log"

        if (-not (Test-Path $logPath)) {
            mkdir $logPath | Out-Null
        }

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Invoke-WebRequest', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $line = "[$(get-date -Format "yyyy-MM-dd HH:mm:ss")] ${env:ComputerName}/${env:UserName}: Invoke-WebRequest"

            # Uses DateTimeFormat
            $line | Out-File `
                -FilePath "$logPath/$(Get-Date -Format "yyyy-MM-dd").log" `
                -Append

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

<#
    clean
    {
        if ($null -ne $steppablePipeline) {
            $steppablePipeline.Clean()
        }
    }
#>
}

