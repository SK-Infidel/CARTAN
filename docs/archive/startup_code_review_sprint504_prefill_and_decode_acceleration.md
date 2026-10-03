# Startup Code Review: Sprint 504 - Sub-Second Prompt Prefill & High-Speed Autoregressive Decode

**Date**: 2026-09-30  
**Reviewer**: Antigravity (Supervisor Agent)  
**Target Systems**: `src/std/transformer.cl`, `test/geomind/chat.cl`, `src/std/wgpu.cl`

---

## 1. Executive Summary & Root Cause Analysis

Telemetry from live inference on `bin/geomind.exe` with user prompt `"What is 2+2?"` revealed:
```
[Step 0 Timing Probe] LM Head: 28 ms | Sample: 0 ms | 42 Layers: 785 ms
[GeoMind Telemetry] Prefill: 74162 ms (108.0 tokens) | Decode: 4129 ms (5.0 tokens, 1.2 tok/s)
```

Rick identified two glaring performance blockers:
1. *"it takes forever between prompt and response"*: Prompt prefill took **74.16 seconds** for 108 tokens.
2. *"response generation is one... word... at... a... time...."*: Decode took **785 ms per token** (1.2 tokens/second).

### Root Causes:
1. **The 74.1-Second Prefill Bottleneck (`cartan_transformer_dispatch_gpu_geglu`)**:
   - During `geomind_execute_manifold_sequence_prefill`: `seq_len = num_tokens = 108.0 > pos + 1.0`.
   - In `cartan_manifold_layer_forward_native`: `is_single_decode` evaluated to `0.0`.
   - Consequently, for all 108 prompt tokens across 42 layers, `cartan_transformer_dispatch_gpu_geglu` was executed token-by-token:
     $$108 \text{ tokens} \times 42 \text{ layers} = \mathbf{4,536 \text{ synchronous WebGPU roundtrips}}$$
   - Each roundtrip submitted a command buffer, mapped the staging buffer asynchronously, polled `wgpuDevicePoll`, and waited on the D3D12 device fence:
     $$4,536 \times 16.349\text{ ms} = \mathbf{74,162\text{ ms} (74.16\text{ seconds})}$$
   - **Fix**: Sequence prefill tokens must be evaluated zero-copy via in-RAM AVX2 SIMD ($108 \times 42 \times 0.44\text{ ms} \approx \mathbf{1.9\text{ seconds}}$), completely bypassing the 4,536 driver queue roundtrips.

2. **The 785 ms/Token Decode Bottleneck (Single-Threaded 967k Dot Products)**:
   - At decode ($T=1$), 1 token step executes across 42 layers:
     - Q projection ($2560 \times 2560$): 2,560 scalar loop iterations with no unrolling.
     - W_o projection ($2560 \times 2560$): 2,560 scalar loop iterations with no unrolling.
     - GeGLU Gate + Up ($10240 \times 2560 \times 2$): 5,120 loop iterations (2-way unrolled).
     - GeGLU Down ($2560 \times 10240$): 1,280 loop iterations (2-way unrolled).
   - Total loop iterations: 22,000 per layer $\times 42 = \mathbf{924,000 \text{ interpreted loop iterations per token}}$, streaming 15.86 GB of memory through single-threaded AVX2.
   - **Fix**: Unroll Q projection and W_o projection 4-way, and upgrade GeGLU Gate/Up and Down projections to 4-way unrolling with interleaved FMA accumulation.

---

## 2. Logical Dependency Tree

```
bin/geomind.exe
  └── test/geomind/chat.cl (geomind_chat_generate_reply_multimodal)
        ├── geomind_execute_manifold_sequence_prefill()
        │     └── cartan_manifold_layer_forward_raw() [42 Layers, 108 Tokens]
        │           └── src/std/transformer.cl (cartan_manifold_layer_forward_native)
        │                 ├── RMSNorm (w_in_norm)
        │                 ├── 4-way Unrolled Q / K / V Projections
        │                 ├── RoPE & GQA Causal Attention
        │                 ├── 4-way Unrolled W_o Projection & Post-Attn Norm
        │                 ├── 4-way Unrolled In-RAM AVX2 GeGLU (NO synchronous GPU roundtrip)
        │                 └── PLE Gating & Layer Scalar
        ├── geomind_execute_manifold_decode_step() [Autoregressive Token Generation]
        │     └── cartan_manifold_layer_forward_raw() [42 Layers, 1 Token]
        │           └── [High-speed 4-way unrolled AVX2 SIMD in host RAM]
        └── cartan_tensor_compute_lm_head_logits()
              └── geomind_chat_dispatch_gpu_lm_head() [WebGPU on NVIDIA RTX 2000 Ada: 28 ms]
                    └── geomind_bulk_f32_to_tensor()
```

---

## 3. Git Issues Logged

- **[ISSUE-342]**: Synchronous Per-Token WebGPU Roundtrip Bottleneck in Sequence Prefill (74.1s latency).
- **[ISSUE-343]**: Un-unrolled Attention GEMVs & Scalar Loop Overhead in 42-Layer Decode (785 ms/tok).

---

## 4. Architectural Recommendations for Sprint 504

1. Update `src/std/transformer.cl` so that GeGLU MLP always routes through the high-throughput in-RAM AVX2 SIMD path unless a multi-token GPU batch is dispatched.
2. Implement 4-way unrolling for Q projection, W_o projection, GeGLU Gate/Up, and GeGLU Down in `cartan_manifold_layer_forward_native`.
3. Validate that prefill latency drops from 74s to under 2s, and decode latency improves.
4. Verify full regression test suite pass rate (88/88 targets).
