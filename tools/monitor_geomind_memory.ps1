# tools/monitor_geomind_memory.ps1
# Continuous Memory Growth & Crash Diagnostics Monitor for GeoMind
# Tracks WorkingSet, PrivateCommit, VirtualMemory, Checkpoints, and OS Crash Events

param (
    [string]$LogFile = "logs/geomind_memory_monitor.log",
    [int]$IntervalSec = 10
)

$ckptPath = "test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin"
$dateStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$initMsg = "[$dateStr] Starting GeoMind Continuous Memory Monitor (Interval: " + $IntervalSec + "s)"
Add-Content -Path $LogFile -Value "`n================================================================================"
Add-Content -Path $LogFile -Value $initMsg
Add-Content -Path $LogFile -Value "================================================================================"
Write-Host $initMsg -ForegroundColor Cyan

$proc = Get-Process -Name "geomind" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) {
    $warn = "[" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + "] Waiting for geomind process..."
    Add-Content -Path $LogFile -Value $warn
    Write-Host $warn -ForegroundColor Yellow
    while (-not $proc) {
        Start-Sleep -Seconds 2
        $proc = Get-Process -Name "geomind" -ErrorAction SilentlyContinue | Select-Object -First 1
    }
}

$pidNum = $proc.Id
$baseWS = [math]::Round($proc.WorkingSet64 / 1MB, 2)
$basePM = [math]::Round($proc.PrivateMemorySize64 / 1MB, 2)
$startMsg = "[" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + "] Hooked geomind PID $pidNum | Initial WS: " + $baseWS + " MB | Initial Commit: " + $basePM + " MB"
Add-Content -Path $LogFile -Value $startMsg
Write-Host $startMsg -ForegroundColor Green

$lastCkptTime = [DateTime]::MinValue
$lastCkptSize = 0

while (-not $proc.HasExited) {
    try {
        $p = Get-Process -Id $pidNum -ErrorAction Stop
        $ws = [math]::Round($p.WorkingSet64 / 1MB, 2)
        $pm = [math]::Round($p.PrivateMemorySize64 / 1MB, 2)
        $vm = [math]::Round($p.VirtualMemorySize64 / 1MB, 2)
        $cpu = [math]::Round($p.CPU, 1)
        $wsDelta = [math]::Round($ws - $baseWS, 2)
        $pmDelta = [math]::Round($pm - $basePM, 2)

        $ckptInfo = "No ckpt change"
        if (Test-Path $ckptPath) {
            $f = Get-Item $ckptPath
            if ($f.LastWriteTime -ne $lastCkptTime) {
                $lastCkptTime = $f.LastWriteTime
                $lastCkptSize = [math]::Round($f.Length / 1MB, 2)
                $ckptInfo = "Ckpt: " + $lastCkptSize + "MB at " + $lastCkptTime.ToString('HH:mm:ss')
            }
        }

        # System commit headroom
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $sysFreeMB = 0
        if ($os) {
            $sysFreeMB = [math]::Round($os.FreeVirtualMemory / 1024, 0)
        }

        $curTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $line = "[$curTime] PID: $pidNum | WS: $ws MB (dWS: $wsDelta MB) | Commit: $pm MB (dPM: $pmDelta MB) | VM: $vm MB | CPU: ${cpu}s | SysFreeVM: $sysFreeMB MB | $ckptInfo"
        Add-Content -Path $LogFile -Value $line
        Write-Host $line
    } catch {
        break
    }
    Start-Sleep -Seconds $IntervalSec
}

$exitTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$exitMsg = "[$exitTime] Process geomind (PID $pidNum) has stopped."
Add-Content -Path $LogFile -Value $exitMsg
Write-Host $exitMsg -ForegroundColor Yellow

# Diagnostic check for crash/OOM events in Windows Event Log
$recentErrors = Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddMinutes(-5); Level=1,2} -ErrorAction SilentlyContinue
$recentOOM = Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=(Get-Date).AddMinutes(-5); Id=2004} -ErrorAction SilentlyContinue

if ($recentOOM) {
    $oomMsg = "[$exitTime] CRITICAL: Windows Resource Exhaustion Detector logged OOM event ID 2004 during execution:`n" + $recentOOM[0].Message
    Add-Content -Path $LogFile -Value $oomMsg
    Write-Host $oomMsg -ForegroundColor Red
} elseif ($recentErrors) {
    $crashMsg = "[$exitTime] WARNING: Application errors logged in Windows Event Viewer near exit:`n" + $recentErrors[0].Message
    Add-Content -Path $LogFile -Value $crashMsg
    Write-Host $crashMsg -ForegroundColor Red
} else {
    $cleanMsg = "[$exitTime] Process exited cleanly without OS crash or memory exhaustion errors detected."
    Add-Content -Path $LogFile -Value $cleanMsg
    Write-Host $cleanMsg -ForegroundColor Green
}
