$file = 'test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin'
if (-not (Test-Path $file)) {
    Write-Output "File not found: $file"
    exit 1
}
$bytes = [System.IO.File]::ReadAllBytes($file)
$count = [int]($bytes.Length / 8)
$arr = New-Object double[] $count
[Buffer]::BlockCopy($bytes, 0, $arr, 0, $bytes.Length)

for ($i = 0; $i -lt $count; $i++) {
    $arr[$i] = $arr[$i] * 8.0
}

[Buffer]::BlockCopy($arr, 0, $bytes, 0, $bytes.Length)
[System.IO.File]::WriteAllBytes($file, $bytes)

Write-Output "Rescaled $count weights by 8.0x successfully."
