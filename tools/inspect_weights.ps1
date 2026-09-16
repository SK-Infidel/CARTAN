$file = 'test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin'
if (-not (Test-Path $file)) {
    Write-Output "File not found: $file"
    exit 1
}
$bytes = [System.IO.File]::ReadAllBytes($file)
$count = [int]($bytes.Length / 8)
$arr = New-Object double[] $count
[Buffer]::BlockCopy($bytes, 0, $arr, 0, $bytes.Length)

$min = [double]::MaxValue
$max = [double]::MinValue
$sum = 0.0
$sqsum = 0.0
$zero_count = 0

for ($i = 0; $i -lt $count; $i++) {
    $v = $arr[$i]
    if ($v -lt $min) { $min = $v }
    if ($v -gt $max) { $max = $v }
    if ([Math]::Abs($v) -lt 1e-12) { $zero_count++ }
    $sum += $v
    $sqsum += $v * $v
}

$mean = $sum / $count
$var = ($sqsum / $count) - ($mean * $mean)
$std = [Math]::Sqrt([Math]::Max(0.0, $var))

Write-Output "Element Count: $count"
Write-Output "Min: $min"
Write-Output "Max: $max"
Write-Output "Mean: $mean"
Write-Output "StdDev: $std"
Write-Output "Near Zero Count: $zero_count"

# Sample first 10 weights
Write-Output "Sample first 10 weights:"
for ($i = 0; $i -lt 10; $i++) {
    Write-Output "  [$i] = $($arr[$i])"
}
