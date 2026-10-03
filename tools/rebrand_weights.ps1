# Rebrand weights, checkpoints, training data, and cache files to sovereign GeoMind/Manifold names

# 1. Checkpoint layers: gemma4_layer_<N>.bin -> manifold_layer_<N>.bin
$layers = Get-ChildItem -Path "test/geomind/trainingdata/checkpoints/layers" -Filter "gemma4_layer_*.bin"
foreach ($f in $layers) {
    $newName = $f.Name -replace "gemma4_layer_", "manifold_layer_"
    Write-Host "Renaming $($f.Name) -> $newName"
    Rename-Item -Path $f.FullName -NewName $newName -Force
}

# 2. Vocab files
if (Test-Path "test/geomind/trainingdata/gemma_vocab_256k.txt") {
    Write-Host "Copying gemma_vocab_256k.txt -> geomind_vocab_256k.txt"
    Copy-Item "test/geomind/trainingdata/gemma_vocab_256k.txt" "test/geomind/trainingdata/geomind_vocab_256k.txt" -Force
    Remove-Item "test/geomind/trainingdata/gemma_vocab_256k.txt" -Force
}

if (Test-Path "test/geomind/trainingdata/gemma_vocab_262k.bin") {
    Write-Host "Copying gemma_vocab_262k.bin -> geomind_vocab_262k.bin"
    Copy-Item "test/geomind/trainingdata/gemma_vocab_262k.bin" "test/geomind/trainingdata/geomind_vocab_262k.bin" -Force
    Remove-Item "test/geomind/trainingdata/gemma_vocab_262k.bin" -Force
}

if (Test-Path "test/geomind/trainingdata/gemma_vocab_65k.bin") {
    Write-Host "Copying gemma_vocab_65k.bin -> geomind_vocab_65k.bin"
    Copy-Item "test/geomind/trainingdata/gemma_vocab_65k.bin" "test/geomind/trainingdata/geomind_vocab_65k.bin" -Force
    Remove-Item "test/geomind/trainingdata/gemma_vocab_65k.bin" -Force
}

# 3. SFT datasets: *_gemma.jsonl -> *_manifold.jsonl
$sftFiles = Get-ChildItem -Path "test/geomind/trainingdata/sft" -Filter "*_gemma.jsonl"
foreach ($f in $sftFiles) {
    $newName = $f.Name -replace "_gemma\.jsonl$", "_manifold.jsonl"
    Write-Host "Renaming $($f.Name) -> $newName"
    Rename-Item -Path $f.FullName -NewName $newName -Force
}

# 4. Root cache files (create zero-overhead hardlinks / aliases)
if (Test-Path "cache_model.safetensors") {
    if (-not (Test-Path "cache_geomind_model.safetensors")) {
        Write-Host "Creating hardlink cache_geomind_model.safetensors -> cache_model.safetensors"
        cmd /c "mklink /H cache_geomind_model.safetensors cache_model.safetensors"
    }
}

if (Test-Path "cache_google_gemma-4-E4B-it_tokenizer.json") {
    if (-not (Test-Path "cache_geomind_tokenizer.json")) {
        Write-Host "Creating hardlink cache_geomind_tokenizer.json -> cache_google_gemma-4-E4B-it_tokenizer.json"
        cmd /c "mklink /H cache_geomind_tokenizer.json cache_google_gemma-4-E4B-it_tokenizer.json"
    }
}

if (Test-Path "cache_google_gemma_config.json") {
    if (-not (Test-Path "cache_geomind_config.json")) {
        Write-Host "Creating hardlink cache_geomind_config.json -> cache_google_gemma_config.json"
        cmd /c "mklink /H cache_geomind_config.json cache_google_gemma_config.json"
    }
}

Write-Host "Filesystem rebrand completed successfully."
