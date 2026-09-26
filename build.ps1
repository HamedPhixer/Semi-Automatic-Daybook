<#
  build.ps1 - make the two downloads into dist\

    Daybook-<version>.zip            the app, for people who have AutoHotkey v1
    Daybook-<version>-portable.zip   the same plus AutoHotkeyU64.exe, its
                                     licence and "Start Daybook.bat" - nothing
                                     to install, runs out of the folder
    notes.md                         this version's section of CHANGELOG.md
                                     with the two checksums under it, which is
                                     what the release page shows

  The version comes from DaybookVersion in lib\Config.ahk. On GitHub the tag
  that started the build must match it (v0.9.0-beta.1 for "0.9.0-beta.1"), or
  nothing is built - a release can never carry the wrong number.

  .\build.ps1 -AhkDir <folder with AutoHotkeyU64.exe and its license.txt>
#>
param([Parameter(Mandatory = $true)][string]$AhkDir)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$dist = Join-Path $root "dist"

$m = Select-String -Path (Join-Path $root "lib\Config.ahk") -Pattern 'DaybookVersion := "([^"]+)"'
if (-not $m) { throw "DaybookVersion not found in lib\Config.ahk" }
$version = $m.Matches[0].Groups[1].Value
if ($env:GITHUB_REF_NAME -and $env:GITHUB_REF_NAME -like "v*" -and $env:GITHUB_REF_NAME -ne "v$version") {
    throw "Tag $($env:GITHUB_REF_NAME) does not match DaybookVersion $version in lib\Config.ahk"
}

# the release notes: this version's section of CHANGELOG.md, from its "## "
# heading to the next one. A version without notes is not built - a release
# with nothing said about it is not worth publishing.
$log = Get-Content (Join-Path $root "CHANGELOG.md") -Encoding UTF8
$start = -1
for ($i = 0; $i -lt $log.Count; $i++) { if ($log[$i] -match "^## \[?$([regex]::Escape($version))\]?(\s|$)") { $start = $i; break } }
if ($start -lt 0) { throw "CHANGELOG.md has no section for $version" }
$end = $log.Count
for ($i = $start + 1; $i -lt $log.Count; $i++) { if ($log[$i] -match "^## ") { $end = $i; break } }
$notes = ($log[($start + 1)..($end - 1)] -join "`n").Trim()

$exe = Join-Path $AhkDir "AutoHotkeyU64.exe"
$lic = @("license.txt", "AutoHotkey license.txt") | % { Join-Path $AhkDir $_ } | ? { Test-Path $_ } | Select-Object -First 1
if (-not (Test-Path $exe)) { throw "No AutoHotkeyU64.exe in $AhkDir" }
if (-not $lic) { throw "No AutoHotkey licence (license.txt) in $AhkDir" }

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory $dist | Out-Null
$stage = Join-Path $dist "stage\Daybook"
New-Item -ItemType Directory -Force (Join-Path $stage "lib") | Out-Null

# the app: what a user needs, nothing of tests\ or docs\. No Daybook.ini -
# it writes its own on the first run, commented, which is the only copy that
# is ever right for the machine it is on.
Copy-Item (Join-Path $root "Daybook.ahk"), (Join-Path $root "README.md"), (Join-Path $root "LICENSE") $stage
Copy-Item (Join-Path $root "lib\*.ahk") (Join-Path $stage "lib")

$plain = Join-Path $dist "Daybook-$version.zip"
Compress-Archive -Path $stage -DestinationPath $plain

# and the same folder again with AutoHotkey itself in it
Copy-Item $exe $stage
Copy-Item $lic (Join-Path $stage "AutoHotkey license.txt")
Copy-Item (Join-Path $root "portable\Start Daybook.bat") $stage
$portable = Join-Path $dist "Daybook-$version-portable.zip"
Compress-Archive -Path $stage -DestinationPath $portable

function Sha($path) { (Get-FileHash $path -Algorithm SHA256).Hash.ToLower() }

# What the release page says: which file to take, then the changelog, then the
# checksums - because these zips carry an unsigned .exe and anyone who wants to
# check what they downloaded should not have to ask.
$head = @"
**Daybook-$version-portable.zip** - unzip it, run **Start Daybook.bat**. Nothing to install.
**Daybook-$version.zip** - the app on its own, if you already have AutoHotkey v1.1.

---
"@
# Folded, like the long half of the changelog: there for anyone checking a
# download, out of the way of everyone reading what changed.
$sums = @"

<details>
<summary>SHA-256 checksums</summary>

    $(Sha $portable)  Daybook-$version-portable.zip
    $(Sha $plain)  Daybook-$version.zip

</details>
"@
[IO.File]::WriteAllText((Join-Path $dist "notes.md"), "$head`n$notes`n$sums`n", (New-Object Text.UTF8Encoding $false))

Remove-Item (Join-Path $dist "stage") -Recurse -Force
Get-ChildItem $dist | ForEach-Object { "{0,-44} {1,10:N0} bytes" -f $_.Name, $_.Length }
