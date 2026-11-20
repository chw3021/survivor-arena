# Local Web export helper for Survivor Arena (Godot 4.7)
# Requires: Godot on PATH + matching export templates installed.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$OutDir = Join-Path $Root "build\web"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Exporting Web build to $OutDir ..."
godot --headless --path $Root --export-release "Web" (Join-Path $OutDir "index.html")
if ($LASTEXITCODE -ne 0) {
	throw "Godot web export failed (exit $LASTEXITCODE). Install Web export templates in Godot first."
}

$PlayHtml = Join-Path $OutDir "play.html"
$IndexHtml = Join-Path $OutDir "index.html"
Move-Item -Force $IndexHtml $PlayHtml
Copy-Item -Force (Join-Path $Root "site\index.html") $IndexHtml
$DocsDir = Join-Path $OutDir "docs"
New-Item -ItemType Directory -Force -Path $DocsDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $Root "site\docs\*") $DocsDir

# HTML5 BGM (PCK 밖 URL). play.html 기준 bgm/arena.wav
$BgmOut = Join-Path $OutDir "bgm"
New-Item -ItemType Directory -Force -Path $BgmOut | Out-Null
Copy-Item -Force (Join-Path $Root "assets\bgm\*.wav") $BgmOut

Write-Host "Done. Hub: build/web/index.html | Play: build/web/play.html | Docs: build/web/docs/ | BGM: build/web/bgm/"
Write-Host "Example: npx --yes serve build/web"
