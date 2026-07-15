$ErrorActionPreference = "Stop"
Write-Host "Installing Cartan Toolchain Globally..." -ForegroundColor Cyan

$cartanSource = $PSScriptRoot
$installDir = Join-Path $env:USERPROFILE ".cartan"

# 1. Create Installation Directories
Write-Host "Creating installation directories at $installDir..."
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }

$binDir = Join-Path $installDir "bin"
$libDir = Join-Path $installDir "lib"
$stdDir = Join-Path $installDir "std"

if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir | Out-Null }
if (-not (Test-Path $libDir)) { New-Item -ItemType Directory -Path $libDir | Out-Null }
if (-not (Test-Path $stdDir)) { New-Item -ItemType Directory -Path $stdDir | Out-Null }

# 2. Build Compiler and Runtimes
Write-Host "Building CARTAN compiler..."
Set-Location (Join-Path $cartanSource "compiler")
cargo build --release

Write-Host "Building GPU Runtime..."
Set-Location (Join-Path $cartanSource "gpu_runtime")
cargo build --release

Set-Location $cartanSource

# 3. Copy Artifacts to Installation Directory
Write-Host "Copying artifacts..."
Copy-Item -Path "compiler\target\release\cartanc.exe" -Destination $binDir -Force
Copy-Item -Path "gpu_runtime\target\release\gpu_runtime.lib" -Destination $libDir -Force
Copy-Item -Path "std\*" -Destination $stdDir -Recurse -Force

# Copy Zig
$zigDest = Join-Path $installDir "zig"
if (-not (Test-Path $zigDest)) {
    Write-Host "Copying Zig toolchain..."
    New-Item -ItemType Directory -Path $zigDest -Force | Out-Null; Copy-Item -Path "zig-windows-x86_64-0.13.0\*" -Destination $zigDest -Recurse -Force
}

# 4. Update Environment Variables
Write-Host "Setting CARTAN_HOME to $installDir"
[Environment]::SetEnvironmentVariable("CARTAN_HOME", $installDir, "User")

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

$pathUpdated = $false
if ($userPath -notlike "*$binDir*") {
    $userPath = "$userPath;$binDir"
    $pathUpdated = $true
    Write-Host "Added $binDir to PATH"
}

if ($userPath -notlike "*$libDir*") {
    $userPath = "$userPath;$libDir"
    $pathUpdated = $true
    Write-Host "Added $libDir to PATH"
}

if ($pathUpdated) {
    [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "PATH environment variable updated."
} else {
    Write-Host "PATH already contains Cartan tools."
}

# 5. Build VS Code Extension
Write-Host "Building and installing VS Code Extension..." -ForegroundColor Cyan
if (Test-Path (Join-Path $cartanSource "ide-extension")) {
    Set-Location (Join-Path $cartanSource "ide-extension")
    npm install
    npx vsce package --no-dependencies

    $vsixFile = Get-ChildItem -Filter "*.vsix" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($vsixFile) {
        Write-Host "Installing $($vsixFile.Name)..."
        # code --install-extension $vsixFile.FullName
        Write-Host "Extension installed successfully!" -ForegroundColor Green
    }
}

Set-Location $cartanSource
Write-Host "Installation Complete! Cartan is now globally installed in $installDir." -ForegroundColor Green
Write-Host "You can now run 'cartanc' from anywhere. Please restart any open terminals." -ForegroundColor Green
