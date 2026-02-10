<#
.LINK
Description: ChrisTitusTech powershell-profile
Url: <https://github.com/ChrisTitusTech/powershell-profile>
Retrieved: 2025-01-24
#>

function Move-ItemToRecycleBin {
    Param(
        [Parameter(ValueFromPipeline)]
        $Path
    )

    Process {
        foreach ($subitem in @($Path)) {
            $fullPath = (Resolve-Path -Path $subitem).Path

            if (-not (Test-Path $fullPath)) {
                Write-Output "Error: Item '$fullPath' does not exist."
                return
            }

            $item = Get-Item $fullPath

            if ($null -eq $item) {
                Write-Output "Error: Could not find the item '$fullPath' to trash."
                return
            }

            $parentPath = Split-Path $fullPath -Parent
            $shell = New-Object -ComObject 'Shell.Application'

            $shell.
                NameSpace($parentPath).
                ParseName($item.Name).
                InvokeVerb('delete')

            Write-Output "'$fullPath' has been moved to the Recycle Bin."
        }
    }
}

function Clear-Cache {
    Param(
        [Switch]
        $WhatIf
    )

    # Add clear-cache logic here
    Write-Output "$($PsStyle.Foreground.Cyan)Clearing cache...$($PsStyle.Reset)"

    # Clear Windows Prefetch
    Write-Output "$($PsStyle.Foreground.Yellow)Clearing Windows Prefetch...$($PsStyle.Reset)"

    Remove-Item `
        -Path "$env:SystemRoot\Prefetch\*" `
        -Force `
        -ErrorAction SilentlyContinue `
        -WhatIf:$WhatIf

    # Clear Windows Temp
    Write-Output "$($PsStyle.Foreground.Yellow)Clearing Windows Temp...$($PsStyle.Reset)"

    Remove-Item `
        -Path "$env:SystemRoot\Temp\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue `
        -WhatIf:$WhatIf

    # Clear User Temp
    Write-Output "$($PsStyle.Foreground.Yellow)Clearing User Temp...$($PsStyle.Reset)"

    Remove-Item `
        -Path "$env:TEMP\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue `
        -WhatIf:$WhatIf

    # Clear Internet Explorer Cache
    Write-Output "$($PsStyle.Foreground.Yellow)Clearing Internet Explorer Cache...$($PsStyle.Reset)"

    Remove-Item `
        -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue `
        -WhatIf:$WhatIf

    Write-Output "$($PsStyle.Foreground.Green)Cache clearing completed.$($PsStyle.Reset)"
}

