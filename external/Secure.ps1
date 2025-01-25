<#
.LINK
Description: ChrisTitusTech powershell-profile
Url: <https://github.com/ChrisTitusTech/powershell-profile>
Retrieved: 2025_01_24
#>

# opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable(
        'POWERSHELL_TELEMETRY_OPTOUT',
        'true',
        [System.EnvironmentVariableTarget]::Machine
    )
}

Set-PSReadLineOption -AddToHistoryHandler {
    Param($Line)
    $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
    $hasSensitive = $sensitive | Where-Object { $Line -match $_ }
    return ($null -eq $hasSensitive)
}

