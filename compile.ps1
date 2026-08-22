# Compile MCBEPlay locally with Aut2Exe (no UPX).
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$candidates = @(
    "${env:ProgramFiles(x86)}\AutoIt3\Aut2Exe\Aut2exe.exe",
    "$env:ProgramFiles\AutoIt3\Aut2Exe\Aut2exe.exe"
)
$aut2exe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $aut2exe) {
    Write-Error "Aut2Exe not found. Install AutoIt from https://www.autoitscript.com/site/autoit/downloads/"
}

$iconFile = Join-Path $PSScriptRoot 'icon.ico'
if (-not (Test-Path -LiteralPath $iconFile)) {
    Write-Error "icon.ico not found in $PSScriptRoot"
}

function Invoke-Aut2Exe {
    param(
        [Parameter(Mandatory = $true)][string]$InFile,
        [Parameter(Mandatory = $true)][string]$OutFile
    )
    Write-Host "Compiling $InFile -> $OutFile (icon.ico)"
    # Aut2Exe often leaves $LASTEXITCODE empty when invoked with &; wait on the process instead.
    # #AutoIt3Wrapper_Icon is SciTE-only; raw Aut2Exe needs /icon.
    $p = Start-Process -FilePath $aut2exe -ArgumentList @('/in', $InFile, '/out', $OutFile, '/icon', $iconFile, '/nopack') -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
        throw "Aut2Exe failed for $InFile (exit $($p.ExitCode))"
    }
    if (-not (Test-Path -LiteralPath $OutFile)) {
        throw "Aut2Exe reported success but $OutFile was not created"
    }
}

Invoke-Aut2Exe -InFile 'mcbeplay.au3' -OutFile 'mcbeplay.exe'
Invoke-Aut2Exe -InFile 'bds.au3' -OutFile 'bds.exe'
Write-Host "Done. Copy only these two .exe files into C:\MCBEPlay (do not overwrite options.txt)."