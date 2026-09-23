# Sprint 387 Walkthrough: Validation Contamination Remediation, Velocity Controller & LR-Coupled Weight Decay

## Overview
Resolved the persistent perplexity divergence in GeoMind pre-training caused by the empirical triad: (1) contaminated validation holdout, (2) static gap controller throttle-lock, and (3) uncoupled weight decay.

## Key Changes Implemented

### 1. Zero-Overlap Multi-Domain Validation Holdout Set
- **Diagnostic Discovery**: 50 of the 100 lines in `pretrain_validation_holdout.txt` were verbatim duplicates of Dataset 0 (`sft/fineweb_edu_curated.txt`) within its first 9.4 KB. Model initially overfit these lines ($VPPL \to 126$), then suffered apparent "divergence" ($VPPL \to 135$) due to recency decay as training streamed into subsequent megabytes.
- **Solution**: Developed [`tools/build_clean_holdout.py`](file:///C:/Users/rich-/source/repos/CARTAN/tools/build_clean_holdout.py) and generated [`test/geomind/trainingdata/pretrain_validation_holdout.txt`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/pretrain_validation_holdout.txt) consisting of 100 clean lines sampled equally (25 each) across 4 external domains outside `corpus.json` (`arxiv_scientific_abstracts.txt`, `tinystories_narratives.txt`, `hf_alpaca_stories.txt`, `hf_roneneldan_TinyStories.txt`).
- **Verification**: Verified 0% overlap (0 matches) across all 10 training datasets in `corpus.json`.

### 2. Validation Velocity Controller
- **Problem**: The previous controller evaluated static cross-entropy gap ($val\_gap > 0.03\text{ nats}$, $\Delta PPL \approx 3\%$). Because natural unseen general-domain perplexity exceeds memorized in-domain train perplexity by $15\% - 40\%$, the controller permanently triggered, pinning LR to floor ($0.00081$), pinning temperature to ceiling ($1.35$), and permanently locking progress annealing.
- **Solution**:
  - Gated divergence and temperature scaling on validation velocity ($\Delta AVL > 0.005\text{ nats}$ over the last 100-chunk interval) rather than static gap, preventing throttle-lock on natural out-of-domain generalization offsets.
  - Added extreme safety valve at $val\_gap > 0.85\text{ nats}$.
  - Progress annealing is unlocked whenever validation loss is stable or descending ($\Delta AVL \le 0.005$).
  - Temperature cools smoothly back to base $1.0$ when validation is non-ascending.
- **Files Modified**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).

### 3. LR-Coupled Weight Decay
- **Problem**: Inner-loop decay ($0.99995$ applied 256 times per chunk) eroded cortical representations; removing decay caused unconstrained logit norm growth.
- **Solution**: Implemented `decay_factor = 1.0 - (lr * 0.00005)` applied once per 256-step chunk in both WebGPU SGD pipeline dispatch and CPU fallback, bounding logit norms without per-token weight erosion.
- **Files Modified**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl).

### 4. Telemetry Logging & CLI Enhancements
- Logged full metrics (Loss, Smoothed Loss, Perplexity, Entropy in bits, Top-1 Certainty %, Surprise in bits) for both Train and Val splits at every 100-chunk interval.
- Added `-temp <float>` CLI parameter override and `--train-pre` flag alias in [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car).

## Verification Results
1. **Compilation**: Clean compilation via `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
2. **SHA-256 Binary Parity**:
   `BA40D9BEFAE46FDB019DDF8A7E3B7CC6BD4C46BD16A734DAEBBA904C6553FF66` verified identical across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
3. **Semantic Analogy Benchmarks (`--eval-analogy`)**:
   - King - man + woman = queen (Rank 1, Cosine Sim 0.4214, Margin +0.1095)
   - he - him + her = she (Rank 1, Cosine Sim 0.4857, Margin +0.1101)
   - father - man + woman = mother (Rank 1, Cosine Sim 0.4687, Margin +0.0976)
   - boy - man + woman = girl (Rank 1, Cosine Sim 0.5800, Margin +0.2711)
