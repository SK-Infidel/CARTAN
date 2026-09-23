# Sprint 387 Plan: Non-Overlapping Multi-Domain Validation Holdout, Velocity-Governed Divergence Controller & Calibrated Manifold Weight Decay

## 1. Problem & Root Cause Analysis
1. **Validation Holdout Contamination & Recency Turnaround**:
   - 50 of the 100 lines in `pretrain_validation_holdout.txt` were verbatim duplicates of the first 9.4 KB of `sft/fineweb_edu_curated.txt` (Dataset 0).
   - In the first ~500 KB, the model overfit to this shared text ($VPPL \to 126$). As training progressed into MB 5-15 of FineWeb-Edu, the model experienced natural recency decay on that initial 9 KB passage, causing validation loss to drift upward ($126 \to 135$).
2. **Hyper-Sensitive Divergence Controller Lock**:
   - `train.cl` treated any natural generalization gap ($val\_gap > 0.03\text{ nats} \approx 3\%\text{ PPL}$) as an emergency divergence.
   - It permanently braked `LR` to the floor ($0.00081$), pinned `TEMP` to maximum ($1.35$), and froze progress annealing, starving the model of gradient energy.
3. **Unbounded Logit Growth from Zero Weight Decay**:
   - `decay_factor = 1.0` was set in Sprint 379 to stop unscaled per-token erosion ([ISSUE-129]). Over millions of streaming steps, LM head weights slowly expand in norm, sharpening output logits and penalizing unseen holdout tokens.

## 2. Implementation Specifications

### Task 1: Generate Clean, Multi-Domain Non-Overlapping Holdout Set
- **Target**: `test/geomind/trainingdata/pretrain_validation_holdout.txt`
- Extract 100 clean, unique lines (25 each) from 4 genuine holdout sources completely absent from `corpus.json`:
  1. `test/geomind/trainingdata/gutenberg_classics.txt` (Literature / Classical Prose)
  2. `test/geomind/trainingdata/sft/tinystories_narratives.txt` (Narrative Fiction / Dialogue)
  3. `test/geomind/trainingdata/physics_and_cartan_knowledge.txt` (Physics & Technical Discourse)
  4. `test/geomind/trainingdata/multi_domain_corpus.txt` (General Multi-Domain Discourse)
- Verify 0% line overlap with any training dataset in `corpus.json`.

### Task 2: Velocity-Governed Divergence & Temperature Controller
- **Target**: `test/geomind/train.cl` (`geomind_train_streaming_steady_state`)
- Replace the hyper-sensitive static gap trigger ($val\_gap > 0.03\text{ nats}$) with a **validation velocity trigger**:
  - Track moving velocity: $\Delta AVL = ema\_val\_loss - prev\_ema\_val\_loss$.
  - Engage braking only when validation loss is actively climbing ($\Delta AVL > 0.005\text{ nats}$).
  - Allow natural generalization gaps ($AVL - ATL \in [0.15, 0.50\text{ nats}]$) without false-alarm throttling.
  - Unlock progress annealing: allow `lr` to smoothly follow the target-loss schedule when validation loss is stable or descending.
  - Keep baseline `TEMP = 1.0`; scale up gently only during positive velocity divergence.

### Task 3: Calibrated LR-Coupled Weight Decay
- **Target**: `test/geomind/train.cl` (`geomind_train_chunk_gpu_pipelined`)
- Couple decay factor strictly to the active learning rate:
  $$decay\_factor = 1.0 - \text{lr} \times 0.00005$$
  - At $\text{lr} = 0.0022$: decay per step is $1 - 1.1 \times 10^{-7}$; per 256-step chunk is $1 - 2.8 \times 10^{-5}$.
  - Over 100,000 steps, weights retain $> 98.9\%$ of baseline norm while preventing long-term drift.
  - Fixes [ISSUE-129] per-token erosion while providing required regularization.

## 3. Verification Protocol
1. Verify 0 matches of new holdout lines against all `corpus.json` datasets via python verification script.
2. Compile cleanly via `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
3. Verify bit-for-bit SHA-256 binary parity across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
4. Run `--eval-analogy` to confirm 4/4 semantic vector analogies pass at Rank 1.
5. Update `CHANGELOG.md` (`[8.345.0]`) and `ISSUES.md`.
