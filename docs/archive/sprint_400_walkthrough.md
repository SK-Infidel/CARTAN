# Sprint 400 Walkthrough: 2048-Token Context Scaling, Validation Recurrent Continuity & Holdout Tail Purge

## 1. Overview & Architectural Achievements
In Sprint 400, the sequence learning horizon and evaluation pipeline of the GeoMind engine were upgraded:
1. **2048-Token ($2\text{K}$) Context Scaling (`[ISSUE-150]`)**:
   - Upgraded OpenCL causal multi-head self-attention kernels (`geomind_causal_mha_step` and `geomind_causal_mha_backward`) to execute strided loops over history steps $s \in [0 \dots t]$ (up to 2048 steps) using 256-thread workgroups and tree reductions over local memory.
   - Expanded VRAM sequence memory `g_buf_chunk_seq_h` to $2048 \times 2560 \times 4$ ($20.97\text{ MB}$), loss buffer `g_buf_chunk_loss` to $2048 \times 4 \times 4$ ($32.768\text{ KB}$), and host buffer `g_host_chunk_loss` to $8192$ floats.
   - Scaled the sequence token clamp in `geomind_train_chunk_gpu_pipelined` from 256.0 to 2048.0.
2. **Validation Recurrent Continuity & Cold-Start Elimination (`[ISSUE-151]`)**:
   - Relocated validation recurrent state initialization (`g_has_prev_chunk_h = 0.0`) outside the chunk loop in `geomind_compute_validation_loss`, allowing validation to start cold exactly once on chunk 0 and maintain continuous narrative recurrence across subsequent chunks.
   - Updated `geomind_train_chunk_gpu_pipelined` to persist `g_buf_train_hidden` into `g_buf_prev_chunk_h` and set `g_has_prev_chunk_h = 1.0` unconditionally after every chunk completion (`lr >= 0.0`).
   - Pre-stashed training recurrent state into `g_buf_saved_train_h` prior to evaluation and cleanly restored training state and `saved_has_prev` post-validation, ensuring zero state contamination between training and evaluation while eliminating the per-chunk cold-start perplexity gap.
3. **Purged Dead Holdout Tails & Aligned Active Domains (`[ISSUE-152]`)**:
   - Purged all 50 dead Alpaca Q&A prompts and synthetic repetitive nursery rhyme templates from lines 51–100 of `pretrain_validation_holdout.txt`.
   - Replaced them with authentic, high-quality, multi-sentence paragraphs extracted directly from the out-of-sample held-out tails of the 5 active dataset families in `corpus.json` (FineWeb-Edu, OpenWebText, WikiText-103, Storytelling, and Mined Discourse).

---

## 2. Empirical Verification
- **Compiler Build & Binary Synchronization**:
  - Compiled using `cartanc.exe build test\geomind\main.car -o geomind.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
  - Verified SHA-256 bit-for-bit parity across all three deployment targets:
    - `./geomind.exe`: `3D520B45CCA3E5202C40D76316846382F92FF0C1ECCA498A366FB53DE40A2339`
    - `test/geomind/geomind.exe`: `3D520B45CCA3E5202C40D76316846382F92FF0C1ECCA498A366FB53DE40A2339`
    - `bin/geomind.exe`: `3D520B45CCA3E5202C40D76316846382F92FF0C1ECCA498A366FB53DE40A2339`
- **Semantic Vector Analogy Arithmetic (`--eval-analogy`)**:
  - `King - man + woman = queen` -> **PASS** (Rank 1, Cosine Sim: 0.4214, Margin: +0.1095)
  - `he - him + her = she` -> **PASS** (Rank 1, Cosine Sim: 0.4860, Margin: +0.1105)
  - `father - man + woman = mother` -> **PASS** (Rank 1, Cosine Sim: 0.4687, Margin: +0.0977)
  - `boy - man + woman = girl` -> **PASS** (Rank 1, Cosine Sim: 0.5800, Margin: +0.2711)
  - Result: 4/4 analogies passing cleanly at Rank 1.
- **Manifest Integrity**:
  - User training offsets in `test/geomind/trainingdata/corpus.json` preserved intact.
