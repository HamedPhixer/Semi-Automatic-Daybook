# run-tests.ps1 - run every *.test.ahk beside this file and print what they say.
#
# Each test writes results-<name>.txt and exits; this reads them back, prints
# them, and sets the exit code so CI can tell. It finds AutoHotkey in the usual
# places, or you can pass -Exe with a path to one.
param([string]$Exe = "")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $Exe) {
    $candidates = @(
        "$here\..\AutoHotkeyU64.exe"
        "$env:ProgramFiles\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe"
        "$env:ProgramFiles\AutoHotkey\AutoHotkeyU64.exe"
        "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe"
    )
    foreach ($c in $candidates) { if (Test-Path $c) { $Exe = $c; break } }
}
if (-not $Exe) {
    Write-Host "No AutoHotkey v1 found. Pass one with -Exe." -ForegroundColor Red
    exit 2
}
Write-Host "AutoHotkey: $Exe`n"

$failed = 0
Get-ChildItem "$here\*.test.ahk" | Sort-Object Name | ForEach-Object {
    $name = $_.BaseName -replace '\.test$', ''
    $out  = Join-Path $here "results-$name.txt"
    if (Test-Path $out) { Remove-Item $out }

    # Start-Process -Wait, not "&": AutoHotkey.exe is a GUI-subsystem program,
    # and PowerShell does not wait for one of those to finish.
    Start-Process -FilePath $Exe -ArgumentList @("/ErrorStdOut", "`"$($_.FullName)`"") -Wait -NoNewWindow
    if (-not (Test-Path $out)) {
        Write-Host "$name : wrote no results - it did not finish" -ForegroundColor Red
        $failed++
        return
    }
    $lines = Get-Content $out
    $head  = $lines[0]
    if ($head -like "*FAILED*") {
        Write-Host "$name : $head" -ForegroundColor Red
        $lines | Where-Object { $_ -match "FAIL" } | ForEach-Object { Write-Host "  $_" }
        $failed++
    } else {
        $n = ($lines | Where-Object { $_ -match "^\s+ok" }).Count
        Write-Host "$name : $head ($n checks)" -ForegroundColor Green
    }
}

Write-Host ""
if ($failed) { Write-Host "$failed test file(s) failed" -ForegroundColor Red; exit 1 }
Write-Host "everything passed" -ForegroundColor Green
