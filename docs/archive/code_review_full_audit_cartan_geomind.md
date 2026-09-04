# Full Codebase Line-by-Line Code Review Audit & Logical Dependency Tree

**Date**: 2026-09-04  
**Audit Scope**: Complete CARTAN Compiler Core (`src/cartanc/`), Standard Libraries (`src/std/`), and GeoMind Model Suite (`test/geomind/`).  
**Objective**: Comprehensive line-by-line verification for stubbed code, pseudo-code, placeholders, mocks, simulated math/loops violating the **STRICT ZERO-MOCK AND ZERO-SIMULATION RULE**, and full logical dependency graph construction.

---

## 1. Executive Summary

A complete, line-by-line inspection was executed across every source file in the repository without relying on comments or top-level greps alone. 

- **Compiler Integrity**: The compiler core is 100% self-hosted CARTAN emitting direct LLVM IR without linking `c_runtime.c`. However, 4 critical compiler bugs were detected: a drop in logical NOT tokenization (`!`), a broken scope table traversal in the type checker, string-serialized float literals in the constant folder, and an unresolved system wrapper symbol.
- **Strict Zero-Mock Compliance**: Widespread violations were uncovered in the AI libraries and GeoMind model test code. Multiple modules employ geometric decay multipliers (`current_loss *= 0.9968`) or linear synthetic metrics (`12.0f - l_val * 0.1f`) to fabricate loss curves, use hardcoded dummy outputs in tiled GEMM, or apply pass-through identity stubs instead of real matrix math.
- **Action Taken**: 20 concrete issues (`[ISSUE-029]` through `[ISSUE-048]`) have been formally registered in `ISSUES.md`.

---

## 2. Logical Dependency Tree

```
CARTAN Codebase Architecture
├── Compiler Core (`src/cartanc/`)
│   ├── `types.ch` (TokenType, AST node tags, Type descriptors)
│   ├── `ast.ch` (Program, FunctionDecl, Stmt, Expr structs)
│   ├── `core_runtime.car` (Injected pure CARTAN primitives: string, tree, mem)
│   ├── `lexer.car` ──> `types.ch`, `core_runtime.car`
│   ├── `parser.car` ──> `lexer.car`, `ast.ch`, `types.ch`
│   ├── `type_checker.car` ──> `ast.ch`, `types.ch`, `parser.car`
│   ├── `optimizer.car` ──> `ast.ch`
│   ├── `llvm_codegen.car` ──> `ast.ch`, `types.ch` (Emits IR + 13 LLVM primitives)
│   ├── `wgsl_codegen.car` ──> `ast.ch`
│   └── `main.car` ──> All compiler modules + `tools/zig_wrapper.py`
│
├── Standard Library (`src/std/`)
│   ├── Layer 0 (Foundation)
│   │   ├── `constants.ch` (Physical, mathematical, astronomical constants)
│   │   ├── `core_runtime.car` (Auto-injected tree/string/memory runtime)
│   │   ├── `math.cl` ──> C-ABI libc math functions (`sin`, `cos`, `pow`, etc.)
│   │   └── `string.cl` ──> `core_runtime.car`
│   ├── Layer 1 (Systems, I/O & Data Structures)
│   │   ├── `fs.cl` ──> libc I/O primitives
│   │   ├── `io.cl` ──> libc console + `core_runtime.car`
│   │   ├── `collections.cl` ──> `core_runtime.car` (Dynamic list, stack, queue, slicing)
│   │   ├── `env.cl` ──> libc `getenv` + CLI parsing
│   │   ├── `net.cl` ──> Berkeley/Winsock socket bindings
│   │   ├── `http.cl` ──> `net.cl`, `string.cl`
│   │   ├── `xml.cl` ──> `string.cl`, `collections.cl`
│   │   └── `ingest.cl` ──> `fs.cl`, `string.cl`, `http.cl`
│   ├── Layer 2 (Mathematics, Simulation & Physics)
│   │   ├── `calculus.cl` ──> `math.cl` (Simpson integration, RK4, RKF45)
│   │   ├── `physics.cl` ──> `math.cl`, `constants.ch` (Gravitation, relativistic mechanics)
│   │   ├── `geom.cl` ──> `math.cl` (Euclidean, Hyperbolic, Lie groups, quaternions)
│   │   └── `tensor.cl` ──> `collections.cl`, `math.cl` (Strided ND-arrays, DLPack FFI)
│   └── Layer 3 (AI, Vision & Optimization)
│       ├── `gpu.cl` ──> `core_runtime.car` (WebGPU compute pipelines)
│       ├── `autotune.cl` ──> `tensor.cl` (Tiled GEMM micro-kernels)
│       ├── `hub.cl` ──> `fs.cl`, `string.cl`, `tensor.cl` (Safetensors parsing)
│       ├── `tokenizer.cl` ──> `string.cl`, `collections.cl` (BPE subword tokenizer)
│       ├── `semantics.cl` ──> `fs.cl`, `string.cl` (WordNet/SlangNet taxonomy graph)
│       ├── `fusion.cl` ──> `tensor.cl`, `math.cl` (SLERP, TIES, DARE weight merging)
│       ├── `distill.cl` ──> `tensor.cl`, `math.cl` (KL divergence distillation loss)
│       ├── `resonator.cl` ──> `tensor.cl`, `math.cl` (Continuous Hopfield attractors)
│       ├── `reasoning.cl` ──> `io.cl`, `fs.cl` (AZR self-play verification)
│       ├── `es_opt.cl` ──> `tensor.cl`, `math.cl` (CMA-ES, PEPG evolution strategies)
│       ├── `wann.cl` ──> `collections.cl`, `math.cl` (Weight-Agnostic Neural Networks)
│       ├── `dip.cl` ──> `tensor.cl`, `math.cl` (Deep Image Prior)
│       ├── `elm.cl` ──> `tensor.cl`, `math.cl` (Extreme Learning Machines)
│       ├── `esn.cl` ──> `tensor.cl`, `math.cl` (Echo State Networks)
│       ├── `evolution.cl` ──> `es_opt.cl`, `wann.cl` (Evolutionary dispatch)
│       ├── `vision.cl` ──> `tensor.cl`, `math.cl` (Image convolutions, resize)
│       ├── `security.cl` ──> `core_runtime.car` (VRAM write-locks, SWMR fences)
│       └── `async.cl` ──> `core_runtime.car` (Async coroutines: spawn, yield, await)
│
└── GeoMind Model Suite (`test/geomind/`)
    ├── `geomind_runtime.c` (Standalone C AI runtime: OpenCL, Safetensors, sockets)
    ├── `logger.cl` ──> `io.cl`, `string.cl` (Telemetry output)
    ├── `geometry.cl` / `geom.cl` ──> `src/std/geom.cl`, `math.cl`
    ├── `ode_solver.cl` ──> `src/std/calculus.cl` (RK4 state propagation)
    ├── `ising_state_machine.cl` ──> `math.cl` (Ising spin lattice simulation)
    ├── `e8_attention_engine.cl` ──> `src/std/resonator.cl`, `tensor.cl`
    ├── `moe.cl` ──> `geom.cl`, `tensor.cl` (Sasaki 4-quadrant router)
    ├── `streams.cl` ──> `geom.cl`, `tensor.cl` (8-stream Lie cortical dispatch)
    ├── `cloze_engine.cl` ──> `src/std/semantics.cl` (Halliday cloze bridges)
    ├── `sft_train.cl` ──> `streams.cl`, `moe.cl`, `tensor.cl`
    ├── `azr_engine.cl` ──> `src/std/reasoning.cl`, `fs.cl`, `io.cl`
    ├── `merge_model_weights.cl` ──> `src/std/fusion.cl` (Gemma 4 checkpoint merging)
    ├── `webgpu_causal_engine.cl` ──> `src/std/gpu.cl`, `streams.cl`, `moe.cl`
    ├── `chat.cl` ──> `e8_attention_engine.cl`, `moe.cl`, `streams.cl`, `tokenizer.cl`
    └── `main.car` ──> Integrates all GeoMind modules into unified CLI binary
```

---

## 3. Line-by-Line Code Review Findings & Identified Deficiencies

### Category A: Compiler Core Deficiencies (`src/cartanc/`)

1. **`[ISSUE-029]` Lexer Logical NOT `!` Token Drop (`src/cartanc/lexer.car:276-280`)**:
   Scanning `!` when not followed by `=` leaves `ttype_op` unassigned, defaulting to `TokenType::EOF`. Consequently, logical NOT expressions (`!x`) fail to lex into `TokenType::Not` (137.0).
2. **`[ISSUE-030]` TypeChecker Scope Stack & `resolve_var` Disconnection (`src/cartanc/type_checker.car:65-88`)**:
   `push_scope` appends to `symbol_table`, while `resolve_var` traverses `current_scope` (which remains initialized to null `0.0`). Scoped local variables are never found, breaking semantic checks.
3. **`[ISSUE-031]` AST Optimizer Constant Folding Serializes Float as String (`src/cartanc/optimizer.car:26, 32, 38, 44`)**:
   `optimize_expr` stores `cartan_float_to_string(val_l + val_r)` in `Expr::Float` rather than the raw numerical float, corrupting downstream AST node representations.
4. **`[ISSUE-032]` Compiler Subcommand Stubs (`src/cartanc/main.car:245, 322-340`)**:
   `cartan lsp` prints a hardcoded JSON snippet and exits; `cartan pkg` writes a manifest lockfile with a dummy checksum string `"e8_root_l0_hash_ok"`.
5. **`[ISSUE-033]` Pure CARTAN Core Runtime Async & Sandbox Fencing Stubs (`src/cartanc/core_runtime.car:622-631`)**:
   `cartan_async_*`, `cartan_rt_lock_swmr`, and `cartan_rt_check_vram_access` return dummy `1.0`. Fencing functions (`vram_lock`, `vram_unlock`, `unlock_swmr`) are empty `{}`.
6. **`[ISSUE-034]` Missing Command Wrapper `cartan_system` in Core Runtime (`src/std/io.cl:6`, `src/cartanc/core_runtime.car:41`)**:
   `io_exec` binds to `extern fn cartan_system`, but `core_runtime.car` only exports `system`, leading to undefined reference errors during linking.
7. **`[ISSUE-035]` Missing Hardware & Backend Environment Primitives (`src/std/env.cl:6-11`)**:
   `cartan_detect_hardware`, `cartan_mount_backend`, `cartan_get_arg_*` are declared externs with no backing implementation.

---

### Category B: Strict Zero-Mock & Zero-Simulation Violations (`src/std/` & `test/geomind/`)

8. **`[ISSUE-036]` Simulated Distillation Student Logit Loop (`test/geomind/main.car:249-275`)**:
   `--train-distill` fills student logits with `0.5` and increments `current_student_val += 0.04` across 50 steps to artificially decrease loss without forward passes or training.
9. **`[ISSUE-037]` Simulated Loss Multipliers in SFT & CE Pre-Training (`test/geomind/sft_train.cl:80, 149-150`)**:
   `current_loss *= 0.9968` and `ce_loss *= 0.9965` simulate training convergence via artificial geometric decay instead of executing tensor backpropagation.
10. **`[ISSUE-038]` Simulated WebGPU Cross-Entropy Loss & Fake Sasaki MoE Telemetry (`test/geomind/webgpu_causal_engine.cl:132, 307-310`)**:
    - `causal_loss_fwd` computes token loss using `(12.0f - l_val * 0.1f) * ic` instead of genuine $-\log(P(y))$.
    - Biological telemetry generates synthetic MoE quadrant loads using trigonometric waves (`q0 = 30.0 + sin(...) * 5.0`).
11. **`[ISSUE-039]` Hardcoded Dummy Matrix Multiplication (`src/std/autotune.cl:46-53`)**:
    `autotune_matmul_tiled` ignores input matrices `A` and `B` and matrix dimensions, returning fixed 4-element tree `[0.5, 0.2, 0.8, 0.1]`.
12. **`[ISSUE-040]` Sliding Window Attention Identity Copy Dummy (`test/geomind/e8_attention_engine.cl:25-35`)**:
    `e8_multihead_sliding_window_attention` copies `h_vec` element-by-element into `out_vec`, performing zero attention calculations.
13. **`[ISSUE-041]` Simulated AZR Proposer, Solver & Reward Verifier (`src/std/reasoning.cl:7-24`, `test/geomind/azr_engine.cl:21-50`)**:
    Proposer outputs canned string `fn solve() -> float { return ...; }`; verifier only checks file existence or string containment.
14. **`[ISSUE-042]` DARE Model Fusion Fixed Modulo 2 Dummy Dropout Mask (`src/std/fusion.cl:99`)**:
    `fusion_dare_rescale` drops every even index (`math_mod_val(i, 2.0) == 0.0`) rather than sampling Bernoulli drops with probability `drop_p`.
15. **`[ISSUE-043]` Hardcoded WordNet / SlangNet Keyword Table & Unused Taxonomy Ingest (`src/std/semantics.cl:41-64`)**:
    `semantics_get_concept_ic` matches against 10 hardcoded keywords (`star`, `photosynthesis`, etc.) with static floats; `semantics_load_taxonomy` reads and discards the file.
16. **`[ISSUE-044]` Mock XML Parser and Data Ingestion Line Validators (`src/std/xml.cl:9-27`, `src/std/ingest.cl:11-21`)**:
    `xml_parse` returns string length in a tree; `ingest_parse_csv_line` merely checks `len > 0`.
17. **`[ISSUE-045]` Untrained Network Inductive Biases (DIP, WANN, ELM, ESN) Pseudo-Implementations (`src/std/`)**:
    - `wann_evaluate_shared_weight`: ignores DAG edges, applies scalar `tanh(input[0] * w)`.
    - `dip_reconstruct_signal`: 3-tap moving average filter instead of network optimization.
    - `elm_fit_zero_shot`: scalar elementwise division instead of matrix pseudo-inverse.
    - `esn_step_forward`: scalar recurrence ignoring reservoir matrix.
18. **`[ISSUE-046]` Undefined Functions in `merge_model_weights.cl` (`test/geomind/merge_model_weights.cl:38, 41, 44, 47, 50, 53`)**:
    Calls non-existent functions `fusion_dare_merge`, `fusion_task_arithmetic`, `fusion_knots_orthogonal_merge`, etc.
19. **`[ISSUE-047]` Network Socket Stubs in C Runtime (`src/cartanc/geomind_runtime.c:104-116`)**:
    `cartan_socket_create`, `cartan_socket_connect`, `cartan_socket_send` unconditionally return `1.0` or string length without creating OS sockets.
20. **`[ISSUE-048]` Ignored Telemetry Parameters in Metric Logger (`test/geomind/logger.cl:12-15`)**:
    `geomind_log_step` receives 5 telemetry metrics and ignores all of them, printing a static string.

---

## 4. Remediation Plan & Sprint Alignment

To eliminate technical debt systematically without cascading bugs or regression:

- **Sprint 289 (Compiler Core Hardening)**:
  - Fix `[ISSUE-029]` (`lexer.car` `!` tokenization).
  - Fix `[ISSUE-030]` (`type_checker.car` scope resolution).
  - Fix `[ISSUE-031]` (`optimizer.car` float literal format).
  - Fix `[ISSUE-034]` (`cartan_system` wrapper in `core_runtime.car`).
  - Re-bootstrap compiler to verify bit-for-bit 3-stage parity.
- **Sprint 290 (Mathematics & Autotuning Engine)**:
  - Fix `[ISSUE-039]` by implementing genuine 2D tiled GEMM in `src/std/autotune.cl` and validating on real matrices.
  - Fix `[ISSUE-042]` with pseudo-random Bernoulli drop masking in `src/std/fusion.cl`.
- **Sprint 291 (GeoMind Model Zero-Mock Elimination)**:
  - Fix `[ISSUE-036]` and `[ISSUE-037]` by removing fake geometric multipliers and connecting genuine forward-backward gradient passes.
  - Fix `[ISSUE-038]` by calculating genuine log-softmax cross-entropy in WGSL compute shaders.
  - Fix `[ISSUE-040]` with authentic multi-head sliding window attention dot-product kernels.
