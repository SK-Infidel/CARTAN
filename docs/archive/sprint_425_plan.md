# Sprint 425 Plan: Dynamic $\gamma$ Domain Isolation & Double-Buffer EOF Wrap-Around

## 1. Objectives & Scope
- **Sprint**: 425
- **Focus**: Training Engine Integrity & Convergence Stability
- **Target Issues**:
  - `[ISSUE-166]`: Cross-Domain Surge False-Positives in Dynamic $\gamma$
  - `[ISSUE-167]`: Same-Domain EOF Wrap-Around in Double-Buffering
  - Backlog logged for next sprint: `[ISSUE-168]` (Root Invariant Erosion in Chat RLHF) & `[ISSUE-169]` (Per-Turn Vector Leak in Interactive Chat)

## 2. Logical Dependency Tree & Root Causes
```
train.cl (streaming training loop)
├── train_update_dynamic_gamma(active_d, ent, cert, d_loss, d_ema)
│   └── dynamic_gamma_compute(cfg, active_domain, cur_entropy, cur_certainty, cur_loss, ema_loss)
│       └── Problem: cur_loss previously received previous chunk loss from domain D_prev, 
│                    and ema_loss was global mixture EMA rather than domain D's own EMA baseline.
│       └── Solution: Pass active domain's previous loss (domain_prev_losses[active_d_idx]) 
│                    or prequential val loss (vl) and active domain's baseline EMA (domain_losses[active_d_idx]).
└── Double-buffering CPU/GPU pipelining
    └── geomind_slice_and_tokenize_chunk(st_content, st_content_len, st_start, standby_tokens)
        └── Problem: When standby_d_idx == active_d_idx and active_next_line_start >= st_content_len (EOF),
                     st_start was passed past EOF without wrapping to 0.0, causing 0 tokens and pipeline stalls.
        └── Solution: Wrap st_start to 0.0 immediately and reset domain_has_prev[standby_d_idx] = 0.0.
```

## 3. Implementation Steps
1. **Dynamic $\gamma$ Domain Isolation (`test/geomind/train.cl`, `src/std/dynamic_gamma.cl`)**:
   - Introduce `domain_prev_train_loss` tracking vector initialized with each domain's initial loss.
   - In `train_update_dynamic_gamma`: retrieve `d_ema = domain_losses[active_d_idx]` (fallback to `ema_train_loss` if unset) and `d_loss = domain_prev_train_loss[active_d_idx]` (or `vl`).
   - Eliminate cross-domain loss leakage so surges are measured strictly against the domain's own baseline.
2. **Same-Domain Double-Buffer EOF Wrap (`test/geomind/train.cl`)**:
   - In the standby buffer pre-tokenization block:
     ```cartan
     if (standby_d_idx == active_d_idx) {
         st_start = active_next_line_start;
     }
     if (st_start >= st_content_len) {
         st_start = 0.0;
         cartan_vec_set_f32(domain_has_prev, standby_d_idx, 0.0);
     }
     ```
   - Ensure `standby_tokens` always receives valid tokens and never stalls at dataset boundaries.
3. **Verification**:
   - Create automated test harness `test/geomind/nses/test_sprint12_dynamic_gamma_and_eof_wrap.car`.
   - Verify with `cartanc.exe` and test binary execution.
   - Build `geomind.exe` and verify `--verify`, `--sleep`, and clean startup.
