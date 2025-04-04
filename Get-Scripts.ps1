<#
.HOWTO
$getScripts = "$pathTo\Get-Scripts.ps1"
& $getScripts | foreach { . $_ }

.LINK
Url: <https://stackoverflow.com/questions/65462679/why-powershell-exe-there-is-no-way-to-dot-source-a-script>
Retrieved: 2022-10-09
#>

return `
    @(dir "$PsScriptRoot\script\*.ps1" -EA Silent) +
    @(dir "$PsScriptRoot\script\$($PsVersionTable.PsVersion.Major)\*.ps1" -EA Silent) +
    @(dir "$PsScriptRoot\external\*.ps1" -EA Silent)

