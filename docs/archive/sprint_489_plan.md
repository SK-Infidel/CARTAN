# Sprint 489 Plan: Standard Library Hub Rigor & Legacy Training Manifold Alignment

**Goal:** Eradicate hollow mocks and placeholder structs in `src/std/hub.cl` ([ISSUE-311](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md)), replace synthetic trigonometric activations in `test/geomind/streams.cl` and `test/geomind/train.cl` with authentic Riemannian metric contractions ([ISSUE-312](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md)), upgrade regression Targets 33 and 46, and execute 3-stage bootstrap fixpoint convergence.

---

## Architecture & Implementation Strategy

### Gate 1: Authentic HuggingFace Hub & Safetensors Introspection (`src/std/hub.cl`)
1. **Authentic Safetensors Header Key Extraction**:
   - Parse JSON object keys from safetensors header to enumerate actual tensor names into a `cartan_tree` instead of pushing hardcoded `"model.safetensors.default"`.
2. **Authentic `hub_automodel_from_pretrained`**:
   - Inspect local repository or cached path for `config.json`.
   - Parse `num_hidden_layers`, `hidden_size`, `vocab_size` directly from JSON key-values.
   - If missing, fail gracefully with explicit error logging rather than returning fake 32-layer/4096-dim constants.
3. **Authentic `hub_autotokenizer_from_pretrained`**:
   - Inspect `tokenizer_config.json` or `tokenizer.json` for vocabulary size and special token definitions.
   - Initialize authentic BPE/SentencePiece vocabulary metadata.
4. **Authentic `hub_load_dataset`**:
   - Parse actual line-delimited records (JSONL or CSV) into dataset tree and report true record count.

### Gate 2: Refactoring Compiler Suite Target 33 (`test/compiler_suite/test_hf_hub.car`)
1. Remove circular assertions against hardcoded constants (`vocab_size == 32000.0`, `num_layers == 32.0`, `num_samples == 1000.0`).
2. Verify authentic safetensors header parsing, real tensor offset calculation, and genuine config loading.

### Gate 3: Eradicate Synthetic Trigonometry in Cortical Streams (`test/geomind/streams.cl` & `train.cl`)
1. **Riemannian Metric Contractions**:
   - Replace toy `cos(...) * 0.25 + 0.75` and `sin(...) * 0.20 + 0.80` with authentic Cartan Killing-form metric tensor projections $g_{ij} v^j$ and geodesic retractions.
   - Stream 0: Linear geodesic contraction under Killing-Cartan metric.
   - Stream 1: Continuous state-space recurrence with genuine exponential decay $e^{-\Delta t A}$.
   - Stream 2: Genuine discrete Fourier/spectral decomposition or DCT filterbank.
   - Stream 3: Exact Poincare hyperbolic conformal retraction $v / (1 + \sqrt{1 - \|v\|^2})$.
   - Stream 4: Exact simplicial boundary operator and Hodge Laplacian $L = d \delta + \delta d$.
   - Stream 5: Eikonal ray arrival time under gradient of eikonal action $|\nabla S| = n$.
   - Stream 6: Continuous heat diffusion semigroup $e^{-t L} v$.
   - Stream 7: Symplectic phase rotation in $\mathfrak{sp}(2n, \mathbb{R})$.
2. **Compute Shaders Alignment (`test/geomind/train.cl`)**:
   - Update `webgpu_get_lie_streams_shader()` and `geomind_streams_backward` to compute authentic metric contractions and exponential projections rather than ad-hoc sine/cosine polynomials.

### Gate 4: Refactoring Compiler Suite Target 46 (`test/compiler_suite/test_lie_streams.car`)
1. Update assertions in Target 46 to verify authentic metric contraction, energy preservation, and boundary operator properties.
2. Confirm 100% compilation and pass under JIT and native execution.

### Gate 5: 3-Stage Bootstrap Fixpoint Rebuild & Regression Clearance
1. Rebuild compiler via 3-stage bootstrap:
   - `cartanc_stage1.exe` -> `cartanc_fresh.exe` -> `cartanc_stage3.exe`.
2. Prove bitwise fixpoint parity: `SHA256(cartanc_fresh.ll) == SHA256(cartanc_stage3.ll)`.
3. Promote Stage 2 binary to `cartanc.exe` and `bin/cartanc.exe`.
4. Run full regression test suite (`tools/run_affected_tests.ps1 -All`): 88/88 passing.
5. Verify unprimed chat inference on `build/geomind.exe`.
6. Update `CHANGELOG.md` to `[8.447.0]` and mark [ISSUE-311] and [ISSUE-312] as FIXED.
