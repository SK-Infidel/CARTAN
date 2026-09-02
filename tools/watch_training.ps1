# tools/watch_training.ps1
# Live Screen Dashboard & Telemetry Monitor for GeoMind Training
# Uses 0 LLM Quota / 0 API Tokens - Pure Local Screen Dashboard

param (
    [string]$LogPath = "logs/stage2_ce_training.log"
)

$host.UI.RawUI.WindowTitle = "GeoMind Training Live Telemetry Dashboard"

if (-not (Test-Path $LogPath)) {
    Write-Host "Waiting for training log at '$LogPath'..." -ForegroundColor Yellow
    while (-not (Test-Path $LogPath)) {
        Start-Sleep -Milliseconds 500
    }
}

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "             GEOMIND NEURAL MANIFOLD REAL-TIME TRAINING DASHBOARD              " -ForegroundColor White
Write-Host "                  Zero-Quota Local Screen Telemetry Monitor                     " -ForegroundColor DarkGray
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to exit monitor (Training continues running in background)`n" -ForegroundColor DarkGray

Get-Content -Path $LogPath -Wait -Tail 15 | ForEach-Object {
    $line = $_
    if ($line -match "Progress:\s+(\d+)\s+/\s+(\d+)\s+\(\s*([\d\.]+)%\)") {
        $curr = [int]$matches[1]
        $total = [int]$matches[2]
        $pct = [double]$matches[3]
        
        $barWidth = 24
        $filled = [int](($pct / 100.0) * $barWidth)
        if ($filled -gt $barWidth) { $filled = $barWidth }
        $empty = $barWidth - $filled
        $progressBar = "[" + ("=" * $filled) + (" " * $empty) + "]"

        # Colorize loss metrics
        Write-Host "$line" -ForegroundColor Green
    } elseif ($line -match "STARTING|COMPLETE|Milestone|Best Model|Target-Loss") {
        Write-Host "$line" -ForegroundColor Yellow
    } elseif ($line -match "Mounted|GPU|Safetensors") {
        Write-Host "$line" -ForegroundColor Cyan
    } else {
        Write-Host "$line" -ForegroundColor Gray
    }
}
