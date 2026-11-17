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

Write-Host "Done. Open build/web/index.html via a local static server, or push to main for GitHub Pages."
Write-Host "Example: npx --yes serve build/web"
