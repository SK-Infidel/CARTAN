# Sprint 438 Task List: Full 42-Layer Sequential Pipeline Alignment

- [x] **Task 1: Full Architecture Audit & Startup Code Review**
  - [x] Trace complete logical dependency graph from compiler core through standard libraries and GeoMind.
  - [x] Inspect tensor layout and keys of Gemma 4-E4B safetensors.
  - [x] Identify Q-Norm, K-Norm, PLE per-layer embeddings, and global vs sliding attention head dimensions.
  - [x] Save startup code review to `docs/archive/startup_code_review_sprint438.md`.
  - [x] Log `[ISSUE-186]` in `ISSUES.md`.

- [x] **Task 2: Full 42-Layer Execution & Diagnostic Pipeline**
  - [x] Update `tools/test_full_42layers_hybrid.py` with authentic BPE tokenizer from `cache_google_gemma-4-E4B-it_tokenizer.json`.
  - [x] Wire up per-head Q-Norm and K-Norm RMSNorm.
  - [x] Implement dynamic head dimension switching (256 for sliding, 512 for global).
  - [x] Connect PLE gated per-layer embedding projections.
  - [x] Execute generation across 42 layers.

- [x] **Task 3: Empirical Generation Verification & Instruction Formatting**
  - [x] Format benchmark queries with Gemma `<start_of_turn>user\n...<end_of_turn>\n<start_of_turn>model\n`.
  - [x] Execute autoregressive generation on benchmark prompts:
    - [x] "What is the capital of France?" -> Verified generation: `Paris`
    - [x] "State the first law of thermodynamics." -> Verified generation: `The First Law of Thermodynamics states that energy cannot be created or destroyed; it can only be transformed from one form to another.`
    - [x] "Explain what neural networks are in one sentence." -> Verified generation: `Neural networks are complex systems designed to mimic the human brain's function.`

- [x] **Task 4: Sprint Documentation & Archiving**
  - [x] Save plan, task list, and walkthrough to artifacts and `docs/archive/`.
  - [x] Update `CHANGELOG.md` with Sprint 438 release notes.
