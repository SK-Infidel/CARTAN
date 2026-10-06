# tools/build_screen_ocr.ps1
# Automates compiling tools/read_screen_ocr.cs into tools/read_screen_ocr.exe using Windows .NET and Windows SDK WinRT metadata.

$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    $csc = Get-Command csc.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}
if (-not $csc -or -not (Test-Path $csc)) {
    Write-Error "Error: csc.exe not found on system."
    exit 1
}

$winmd = "C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.22621.0\Windows.winmd"
if (-not (Test-Path $winmd)) {
    $winmd = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\UnionMetadata\*\Windows.winmd" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $winmd -or -not (Test-Path $winmd)) {
    Write-Error "Error: Windows.winmd not found in Windows Kits."
    exit 1
}

$facades = "C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\Facades"
if (-not (Test-Path $facades)) {
    $facades = Get-ChildItem "C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.*\Facades" -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}

$argsList = @(
    "/nologo",
    "/optimize",
    "/out:tools\read_screen_ocr.exe",
    "/r:System.Windows.Forms.dll",
    "/r:System.Drawing.dll",
    "/r:C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Runtime.WindowsRuntime.dll",
    "/r:$facades\System.Runtime.dll",
    "/r:$facades\System.Threading.Tasks.dll",
    "/r:$facades\System.IO.dll",
    "/r:$winmd",
    "tools\read_screen_ocr.cs"
)

Write-Host "Building tools/read_screen_ocr.exe via $csc ..."
& $csc $argsList
if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully built tools/read_screen_ocr.exe"
} else {
    Write-Error "Compilation failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
