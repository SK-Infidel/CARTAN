# Sprint 72 Implementation Plan: Native RLAIF & AI Judge Orchestration

## 1. Objectives
- **Stochastic Temperature Differentiation**: Update `test/geomind/chat.car` so that varying `temp` ($T=0.35$ vs $T=0.85$) produces distinct, non-identical candidate outputs ($R_A$ vs $R_B$).
- **RLAIF CLI Execution Mode (`geomind.exe --rlaif [prompt]`)**: Implement `--rlaif` flag in `test/geomind/main.car` to generate and display dual candidate responses ($R_A$ focused vs $R_B$ exploratory).
- **Preference Optimization & Reward Feedback**: Enable preference scoring and reinforcement training via SFT backpropagation loop (`geomind_sft_train_run`) on the winning candidate response.

---

## 2. Logical Dependency Tree
- `src/std/tokenizer.car` (`tokenizer_sample_topk`)
  └── `test/geomind/chat.car` (`geomind_chat_generate_reply` with temperature-weighted offset jitter)
      └── `test/geomind/main.car` (`--rlaif` CLI driver flag)
          └── `CARTAN Subagent` (AI Judge: compares $R_A$ vs $R_B$, selects $R_{\text{win}}$, triggers SFT preference update)

---

## 3. Step-by-Step Execution Plan
1. **`test/geomind/chat.car`**:
   - Incorporate `temp` into per-step token offset sampling jitter when `temp > 0.5`.
   - Ensure $T_A = 0.35$ produces precise focused outputs while $T_B = 0.85$ produces exploratory outputs.
2. **`test/geomind/main.car`**:
   - Add `--rlaif` CLI flag handling.
   - Output Candidate A ($T=0.35$) and Candidate B ($T=0.85$) under prompt argument or default prompt.
3. **Rebuild & Synchronize**:
   - Compile via `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
   - Copy `geomind.exe` to root and `bin/` directories.
4. **Subagent QA Verification**:
   - Launch subagent as AI Judge to execute `geomind.exe --rlaif "Explain the link between gravity and living organisms"`.
   - Judge candidates, report preference score, and confirm zero errors.
5. **Documentation & Changelog**:
   - Update `CHANGELOG.md` and `docs/ROADMAP.md`.
