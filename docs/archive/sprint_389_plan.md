# Sprint 389 Plan: Interleaved Multi-Dataset Pre-Training & Unified Domain Streaming

## 1. Objective & Rationale
Replace sequential dataset ingestion (processing entire 38 MB files sequentially) with balanced round-robin interleaving across all registered datasets in [`corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json). This guarantees continuous exposure to all domain registers (educational web, dialogue, encyclopedic, narrative, and cloze syntactic scaffolding) simultaneously, eliminating the "washboarding" effect (periodic loss spikes and recency forgetting at file boundaries).

---

## 2. Technical Architecture

### 2.1 Multi-Dataset Offset Vector
- Upgrade manifest tracking in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) to persist per-dataset byte offsets (`dataset_offsets: [offset_0, ..., offset_N-1]`) alongside `current_dataset_index` and `current_epoch`.
- Preserve full backward compatibility with legacy single-offset manifests.

### 2.2 Round-Robin Interleaved Ingestion Loop
- Instead of exhausting an entire file to EOF before advancing `d_idx`:
  - Each rotation ingests an interleaved slice of $K$ chunks (e.g. 50 chunks / ~12.8 KB) from `datasets[d_idx]`.
  - Saves the updated offset for `d_idx`.
  - Advances $d\_idx = (d\_idx + 1) \pmod N$ and streams the next slice from the next domain.
  - When an individual dataset reaches EOF, its offset wraps to 0.0 with full epoch tracking.

### 2.3 Unified Pre-Training Stream
- The 6 syntactic cloze datasets (`mined_expanded_corpus_cloze_part01..06.txt`) are interleaved directly into the pre-training stream alongside prose datasets (`fineweb_edu_curated.txt`, `openwebtext_curated.txt`, `wikitext103_structural.txt`, `storytelling_corpus_clean.txt`).
- Eliminates the need for a separate, disconnected Cloze pre-training stage.

---

## 3. Sprint Tasks
1. **Task 1: Manifest Schema & Per-Dataset Offset Persistence (`test/geomind/train.cl`)**:
   - Implement `geomind_manifest_parse_offsets` and update `geomind_manifest_save` to serialize and restore per-dataset offsets.
2. **Task 2: Interleaved Streaming Ingestion Engine (`test/geomind/train.cl`)**:
   - Refactor `geomind_train_streaming_steady_state` inner loop to execute round-robin slice streaming across datasets.
   - Maintain recurrent hidden context correctly across slices.
3. **Task 3: Compiler Verification & Parity**:
   - Compile via self-hosting compiler `cartanc.exe`.
   - Synchronize and verify SHA-256 binary parity across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
4. **Task 4: Analogy Verification & Empirical Trial**:
   - Verify 4/4 semantic vector analogies pass at Rank 1.
   - Run initial interleaved pre-training trial and verify smooth, non-washboarding loss progression.
5. **Task 5: Documentation & Archive**:
   - Record in `CHANGELOG.md`, update `ISSUES.md`, and archive walkthrough.
