$ErrorActionPreference = "Stop"
Write-Host "Installing Cartan Compiler and IDE Extension..." -ForegroundColor Cyan

# 1. Setup Environment Variables
$cartanPath = $PSScriptRoot
Write-Host "Setting CARTAN_PATH to $cartanPath"
[Environment]::SetEnvironmentVariable("CARTAN_PATH", $cartanPath, "User")

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$releasePath = Join-Path $cartanPath "compiler\target\release"
$zigPath = Join-Path $cartanPath "zig-windows-x86_64-0.13.0"

$pathUpdated = $false

if ($userPath -notlike "*$releasePath*") {
    $userPath = "$userPath;$releasePath"
    $pathUpdated = $true
    Write-Host "Added $releasePath to PATH"
}

if ($userPath -notlike "*$zigPath*") {
    $userPath = "$userPath;$zigPath"
    $pathUpdated = $true
    Write-Host "Added $zigPath to PATH"
}

if ($pathUpdated) {
    [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "PATH environment variable updated."
} else {
    Write-Host "PATH already contains Cartan tools."
}

# 2. Package and Install VS Code Extension
Write-Host "Building and installing VS Code Extension..." -ForegroundColor Cyan
Set-Location (Join-Path $cartanPath "ide-extension")

# Ensure dependencies are installed
Write-Host "Running npm install..."
npm install

# Build the extension (.vsix)
Write-Host "Packaging extension..."
npx vsce package --no-dependencies

# Find the built vsix file
$vsixFile = Get-ChildItem -Filter "*.vsix" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($vsixFile) {
    Write-Host "Installing $($vsixFile.Name)..."
    code --install-extension $vsixFile.FullName
    Write-Host "Extension installed successfully!" -ForegroundColor Green
} else {
    Write-Host "Failed to find the packaged .vsix file." -ForegroundColor Red
}

Write-Host "Installation Complete! Please restart any open VS Code windows or terminals to apply environment changes." -ForegroundColor Green
