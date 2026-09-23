# Sprint 389 Walkthrough: Interleaved Round-Robin Streaming & Online Prequential Validation

## Mission Objective
Eliminate domain-sequential washboarding across training datasets, replace static holdouts with genuine online prequential out-of-sample validation, and symmetrize training/validation EMA tracking to remove step-1 cold-start pollution.

## Completed Tasks

### 1. Interleaved Round-Robin Multi-Domain Streaming
- **Implementation**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl)
- **Mechanism**:
  - Replaced monolithic per-dataset loops with round-robin rotation every $K = 50$ chunks (~12.8 KB).
  - Maintained persistent per-dataset offset tracking via `offsets` list in [`test/geomind/trainingdata/corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json).
  - Implemented `geomind_manifest_parse_offsets` and `geomind_manifest_save_interleaved`.

### 2. Zero-Latency In-Memory Ingestion
- **Implementation**: Pre-loaded all 10 registered datasets into `cached_contents` and `cached_lengths` (~126 MB total) at engine start.
- **Impact**: Zero disk I/O seek latency during high-frequency domain interleaving.

### 3. Online Prequential Next-Chunk Validation Engine
- **Implementation**: On chunk 0 of each domain slice, executes forward probe with `lr = 0.0` before applying training updates.
- **Impact**: Computes genuine out-of-sample prediction loss ($VL, IVPPL, AVPPL, VENT, VCERT$) across all 10 active domains without external holdout divergence, dataset distribution mismatch, or VRAM swapping overhead.

### 4. Dual-EMA Parity & Clean Telemetry Standard
- **Implementation**:
  - Removed premature `d_chunks == 1.0` step-1 trigger that polluted running metrics ($ATPPL \approx 670$).
  - Symmetrized `ATL = ema_train_loss` with 0.70 EMA momentum matching `AVL = ema_val_loss`.
  - Standardized acronyms to `ITPPL`, `ATPPL`, `IVPPL`, `AVPPL`.

## Verification Results

### 1. Self-Hosting CARTAN Compilation & Native Pass
- `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe` passed cleanly with Zig -O3 LTO Vectorized pipeline.
- Fixed `offsets_list` and `cached_lengths` to utilize native scalar float vectors (`cartan_vec`), eliminating pointer-address accumulation and premature epoch termination.
- Eliminated duplicate epoch increment and reset offsets cleanly on epoch rollover.
- Synchronized bit-for-bit SHA-256 parity:
  - `test/geomind/geomind.exe`: `A326657BBC4A9DCED1CF4D7EEBE9B306EEBD2844D193AA31433358F96492BDF4`
  - `bin/geomind.exe`: `A326657BBC4A9DCED1CF4D7EEBE9B306EEBD2844D193AA31433358F96492BDF4`
  - `./geomind.exe`: `A326657BBC4A9DCED1CF4D7EEBE9B306EEBD2844D193AA31433358F96492BDF4`

### 2. Semantic Analogy Arithmetic Verification
- Command: `.\geomind.exe --eval-analogy`
- Results:
  - King - man + woman = `queen` (Rank 1, Cosine: 0.421, Margin: +0.109)
  - he - him + her = `she` (Rank 1, Cosine: 0.487, Margin: +0.111)
  - father - man + woman = `mother` (Rank 1, Cosine: 0.469, Margin: +0.098)
  - boy - man + woman = `girl` (Rank 1, Cosine: 0.580, Margin: +0.271)
  - Status: 4/4 PASS at Rank 1.

### 3. Baseline Training State Ready for User Launch
- Checkpoint status: `SUCCESS`
- Manifest: [`corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json) reset with zero offsets across all 10 datasets.
- Training binary is ready for user manual launch via `.\geomind.exe --train-ce`.
