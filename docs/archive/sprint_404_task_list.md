# Sprint 404 Task List: Prequential Stream Validation Architecture & Low-Entropy Codebase Cleanup

- [x] Task 1: Clean up redundant validation holdout functions (`geomind_init_val_cache`, `geomind_free_val_cache`, `geomind_compute_validation_loss`, `geomind_get_domain_family`) and buffers (`g_buf_val_prev_h`, `g_val_has_prev`, `g_buf_saved_train_h`) in `test/geomind/train.cl` <!-- id: 0 -->
- [x] Task 2: Implement prequential upcoming-chunk forward validation ($T=1.0, lr=0.0$) in `geomind_train_streaming_steady_state` using warm domain state <!-- id: 1 -->
- [x] Task 3: Clean up legacy holdout files and scratch artifacts <!-- id: 2 -->
- [x] Task 4: Compile with `cartanc.exe` and synchronize binary parity across all 3 targets <!-- id: 3 -->
- [x] Task 5: Verify analogy evaluation benchmark (4/4 PASS at Rank 1) <!-- id: 4 -->
- [x] Task 6: Test responsive prequential streaming execution with clean reset <!-- id: 5 -->
- [x] Task 7: Update `CHANGELOG.md`, `ISSUES.md`, and write `sprint_404_walkthrough.md` <!-- id: 6 -->
