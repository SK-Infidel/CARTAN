# Sprint 417 Plan: Rapid-Cadence Metacognitive Sleep & Reactive Loss-Spike Quenching

## Objective
Accelerate GeoMind's autonomous sleep consolidation engine from an arbitrary 500-chunk epoch delay to a tight, biologically grounded cadence:
1. **Regular Cadence**: Execute consolidation once every other dataset cycle (every 20 chunks / 2 full fleet rotations), continuously purging synaptic decay and reinforcing clean axiomatic invariants before gradient noise can accumulate.
2. **Reactive Quenching**: Trigger an adaptive micro-nap immediately whenever validation loss climbs across 2 consecutive checks ($\Delta VL > 0$) or when any domain exhibits an acute spike ($\Delta VL > 0.35$).
3. **Telemetry & Log Stream Integration**: Append sleep consolidation metrics (pruned synapses, retained edges, and imprinted rules) directly into `log_file` (`logs/stage2_ce_training.log`) as well as console `printf`.

---

## Logical Dependency Tree
```
┌────────────────────────────────────────────────────────┐
│ test/geomind/train.cl (geomind_train_streaming_steady) │
│ - sleep_cycle_interval = num_datasets * 2.0 (20 chunks)│
│ - val_climb_streak >= 2.0 || loss_spike > 0.35         │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────────┐ ┌──────────────────────────┐
│ Cadence Check             │ │ Reactive Trigger Check   │
│ total_chunks % 20 == 0    │ │ val_vel > 0 || spike     │
└─────────────┬─────────────┘ └───────────┬──────────────┘
              └─────────────┬─────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│ Metacognitive Sleep Consolidation Kernel               │
│ 1. train_sync_weights_gpu_to_host()                    │
│ 2. cargraph_sleep_consolidate_file (prune w < 1.001)   │
│ 3. cartan_sleep_consolidate_cycle (Hopfield basins)    │
│ 4. sleep_run_axiomatic_consolidation (NSES 42 rules)   │
│ 5. train_sync_weights_host_to_gpu()                    │
│ 6. cartan_append_file(log_file, sleep_log_entry)       │
└────────────────────────────────────────────────────────┘
```

---

## Tasks
1. Pre-Sprint Code Review & dependency check (Completed).
2. Update `test/geomind/train.cl`:
   - Initialize `val_climb_streak = 0.0`.
   - Update sleep trigger logic to run every `num_datasets * 2.0` chunks (20 chunks) or on reactive loss spike/climb.
   - Format and append consolidation metrics to `log_file`.
3. Compile and empirically verify `geomind.exe` with `cartanc.exe`.
4. Verify all 7 NSES test suites and `geomind.exe --verify`.
5. Author walkthrough, update task list, and prepend `[8.375.0]` to `CHANGELOG.md`.
