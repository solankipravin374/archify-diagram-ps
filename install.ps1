# Install the archify-diagram-ps skill into your Claude skills directory.
# Usage: ./install.ps1
#        $env:CLAUDE_SKILLS_DIR = "C:\path"; ./install.ps1   (custom location)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src = Join-Path $ScriptDir "skills\archify-diagram-ps"

if ($env:CLAUDE_SKILLS_DIR) {
    $DestRoot = $env:CLAUDE_SKILLS_DIR
} else {
    $DestRoot = Join-Path $HOME ".claude\skills"
}
$Dest = Join-Path $DestRoot "archify-diagram-ps"

if (-not (Test-Path $Src)) {
    Write-Error "Cannot find $Src"
    exit 1
}

New-Item -ItemType Directory -Force -Path $DestRoot | Out-Null
if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
Copy-Item -Recurse $Src $Dest

Write-Host "Installed archify-diagram-ps -> $Dest" -ForegroundColor Green

$ArchifyPath = Join-Path $DestRoot "archify"
if (-not (Test-Path $ArchifyPath)) {
    Write-Host ""
    Write-Host "WARNING: The 'archify' skill was not found in $DestRoot." -ForegroundColor Yellow
    Write-Host "  archify-diagram-ps needs it to render diagrams. Install it first:"
    Write-Host "    git clone https://github.com/tt-a1i/archify `"$ArchifyPath`""
    Write-Host "    cd `"$ArchifyPath`"; npm install"
}

Write-Host ""
Write-Host "Restart Claude Code, then try:  /archify-diagram-ps"
