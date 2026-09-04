# Sprint 299 Implementation Plan: Continuous Hopfield Episodic Memory Buffer

## Sprint Goal
Deliver Phase 59 Item 1: Connect persistent associative continuous Hopfield memory in VRAM/host to `--ingest` and conversational inference (`--chat`), enabling zero-backprop $\mathcal{O}(1)$ one-shot attractor basin insertion and associative recall with monotonic energy descent.

---

## Pre-Sprint Scrum & Code Review Findings
- **Audit Discovery (`[ISSUE-049]`)**:
  - `src/cartanc/geomind_runtime.c`: Attractor basin storage `g_hopfield_basins` lacked binary serialization/deserialization functions (`cartan_hopfield_save_basins`, `cartan_hopfield_load_basins`), and lacked direct `CartanVector*` insertion (`cartan_hopfield_store_hidden`). Capacity was restricted to 128 attractors.
  - `test/geomind/main.car`: `--ingest` created attractors in volatile memory without persisting them to disk (`test/geomind/trainingdata/hopfield_basins.bin`).
  - `test/geomind/chat.cl`: `geomind_chat_start` did not load saved basins. Prompt generation bypassed `cartan_hopfield_relax` and calculated flat $L_2$ norm energy instead of true Demircigil-Krotov-Hopfield log-sum-exp energy. No one-shot $\mathcal{O}(1)$ attractor insertion occurred during chat.
- **Dependency Graph**:
  - `src/std/resonator.cl` <--> `src/cartanc/geomind_runtime.c` (shared binary basin layout: `[count, dim]` + raw float array).
  - `src/cartanc/geomind_runtime.c` <--> `test/geomind/chat.cl` & `test/geomind/main.car`.
  - `test/compiler_suite/test_hopfield_buffer.car` (Target 51 regression harness).

---

## Tasks & Execution Steps

### 1. Extend C Runtime Attractor Engine (`src/cartanc/geomind_runtime.c`)
- Increase `CARTAN_MAX_HOPFIELD_BASINS` to 2048.
- Implement `cartan_hopfield_save_basins(const char* filepath) -> double`.
- Implement `cartan_hopfield_load_basins(const char* filepath) -> double`.
- Implement `cartan_hopfield_store_hidden(void* hidden_ptr) -> double`.

### 2. Wire Hopfield Episodic Memory into Conversational Inference (`test/geomind/chat.cl`)
- In `geomind_chat_start`: Attempt to load `test/geomind/trainingdata/hopfield_basins.bin`.
- In `geomind_chat_generate_reply`:
  - Relax `hidden_state` via `cartan_hopfield_relax(hidden_state, 1.0, 2.0)` before forward pass.
  - Compute authentic Hopfield energy via `cartan_hopfield_energy(relaxed_h)`.
  - Store `hidden_state` via `cartan_hopfield_store_hidden(hidden_state)` for $\mathcal{O}(1)$ one-shot learning.
  - Save updated bank to `test/geomind/trainingdata/hopfield_basins.bin`.
- In `geomind_chat_generate_reasoning_pass`: Evaluate authentic `cartan_hopfield_energy(h_vec)`.

### 3. Connect Hopfield Persistence to `--ingest` (`test/geomind/main.car`)
- In `--ingest` pipeline: After calling `cartan_hopfield_ingest(target_path)`, invoke `cartan_hopfield_save_basins("test/geomind/trainingdata/hopfield_basins.bin")`.

### 4. Create Regression Test Target 51 (`test/compiler_suite/test_hopfield_buffer.car`)
- Authentically verify:
  1. Attractor bank creation and normalization.
  2. Continuous Hopfield relaxation of noisy state vector into attractor basin with monotonic energy descent ($E_{\text{relaxed}} \le E_{\text{init}}$).
  3. Binary basin serialization and deserialization.
  4. $\mathcal{O}(1)$ one-shot attractor insertion without backpropagation.

### 5. Update Compiler Test Suite Harness & Run Empirical Verification
- Add Target 51 to `test/compiler_suite/run_tests.car`.
- Build and execute `geomind.exe` with `--ingest` and `--chat`.
- Run `scratch/run_tests.exe` and confirm 51/51 tests pass.
- Update `ROADMAP.md`, `ISSUES.md`, and `CHANGELOG.md`.
