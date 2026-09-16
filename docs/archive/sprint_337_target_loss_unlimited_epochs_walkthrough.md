# Sprint 337: Target Loss-Driven Continuous Training, Unlimited Epochs & Mid-Epoch Early Stopping

## Executive Summary
Sprint 337 addresses user flow control during neural training in GeoMind. Previously, training defaulted to a strict 3-epoch limit and only supported `-target-loss` and `-tl` aliases, causing training to terminate after 3 epochs even if the target loss threshold was not achieved. Sprint 337 introduces `-training-loss` and `-loss` parsing, eliminates the default epoch ceiling (defaulting to unlimited / `1000000.0` epochs), adds mid-epoch early stopping at the 50-chunk reporting interval, and supports continuous multi-epoch training with geometric learning rate decay until convergence.

---

## Key Modifications

### 1. CLI Parsing Expansion (`test/geomind/main.car`)
- Enhanced `get_cli_target_loss` to recognize `-training-loss` and `-loss` in addition to `-target-loss` and `-tl`.
- Implemented `has_cli_epochs(arg_count)` to determine whether the user explicitly provided an epoch count via `-epochs` or `-ep`.
- Updated `--train-pre`, `--train-cloze`, `--train-ce`, and `--train-sft` to default `epochs = 1000000.0` when `-epochs` is omitted, running continuously until target loss is reached.
- Updated `--help` dialogue documentation.

### 2. Continuous Multi-Epoch & Mid-Epoch Stopping Engine (`test/geomind/train.cl`)
- Default `epochs` updated to `1000000.0` if `<= 0.0`.
- Telemetry banner shows `Epochs: Unlimited (Until Target Loss Hit)` when `epochs >= 100000.0`.
- Added `target_hit` state tracking across chunk, dataset, and epoch loops.
- Added mid-epoch convergence check at the 50-chunk reporting interval:
  ```cartan
  if (total_chunks_ep >= 10.0 && (tl <= t_loss || smoothed_loss <= t_loss)) {
      printf("[Steady-State Stage: %s] Target loss reached during Epoch %s (TL: %s, Smoothed: %s <= Target: %s)! Early stopping triggered.\n",
          stage_name, cartan_float_to_string(ep), cartan_float_to_string(tl),
          cartan_float_to_string(smoothed_loss), cartan_float_to_string(t_loss));
      target_hit = 1.0;
      final_loss = tl;
      train_sync_weights_gpu_to_host();
      cartan_safetensors_save_tensor_f32(ckpt_path, "model.weights", g_cortical_weights);
  }
  ```
- If target loss is not yet reached at epoch completion, the loop increments `ep = ep + 1.0` and anneals the learning rate (`lr = lr * 0.90` down to `0.0001` floor).

### 3. Binary Compilation & 4-Way Synchronization
- Native executable compiled with `cartanc.exe` using `-O3 LTO Vectorized Pass Pipeline`.
- Synchronized across all 4 production targets with 100% SHA-256 parity:
  - `bin/geomind.exe`: `CAA6F966D55D91010C6525AB56832D9047B8B2F348D80B8ECE361FFCE32F23CA`
  - `geomind.exe`: `CAA6F966D55D91010C6525AB56832D9047B8B2F348D80B8ECE361FFCE32F23CA`
  - `build/geomind.exe`: `CAA6F966D55D91010C6525AB56832D9047B8B2F348D80B8ECE361FFCE32F23CA`
  - `test/geomind/geomind.exe`: `CAA6F966D55D91010C6525AB56832D9047B8B2F348D80B8ECE361FFCE32F23CA`
