# run-tests.ps1 - check that the whole app loads, then run every *.test.ahk
# beside this file and print what they say.
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

# ---- does it even load? -----------------------------------------------------
# /iLib makes AutoHotkey read the script and everything it includes, and stop
# before running a line of it. It is the only thing that looks at all 25 files
# in lib\ at once, and it catches the whole class of mistakes that a test of
# the rules never will: a typo in a file nothing here includes, a function
# called by a name that no longer exists. The list it writes is thrown away -
# it is the exit code that matters.
$entry = Join-Path (Split-Path $here -Parent) "Daybook.ahk"
$ilib  = Join-Path $env:TEMP "daybook-ilib.ahk"
$log   = Join-Path $env:TEMP "daybook-ilib-out.txt"
Start-Process -FilePath $Exe -ArgumentList @("/iLib", "`"$ilib`"", "/ErrorStdOut", "`"$entry`"") `
              -Wait -NoNewWindow -RedirectStandardOutput $log | Out-Null
# quoted, because Get-Content -Raw on an empty file hands back $null, and
# $null has no .Trim()
$err = if (Test-Path $log) { "$(Get-Content $log -Raw)".Trim() } else { "" }
if ($err) {
    Write-Host "load   : FAILED" -ForegroundColor Red
    $err -split "`r?`n" | ForEach-Object { Write-Host "  $_" }
    $failed++
} else {
    Write-Host "load   : Daybook.ahk and all of lib\ parse" -ForegroundColor Green
}
Remove-Item $ilib, $log -ErrorAction SilentlyContinue
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
