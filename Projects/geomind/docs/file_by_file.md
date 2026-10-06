# GeoMind Model File Reference

This document provides an exhaustive, 100% accurate file-by-file reference for the **GeoMind** neural model codebase in CARTAN. It reflects the pure-CARTAN sovereign implementation located in `test/geomind/`, standard library dependencies in `src/std/`, and auxiliary tools in `tools/`.

---

## 1. Top-Level Driver & Executables (`test/geomind/`)

| File | Purpose & Description | Key Functions / Symbols |
| :--- | :--- | :--- |
| [`main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car) | **Top-level CLI Driver, Interactive REPL & Biometrics.** Parses execution modes (`--chat`, `--train-pre`, `--train-cloze`, `--train-ce`, `--train-sft`, `--train-distill`, `--merge-slerp`, `--graft`, `--azr-selfplay`, `--ingest`, `--sleep`, `--train-webgpu`), handles hardware camera capture, extracts 320-D eikonal face embeddings, authenticates interlocutors against Domain 10, manages REPL slash commands, and non-blocking `/` key interruption. | `main`, `print_help_dialogue`, `geomind_chat_interactive_loop`, `is_pre_mode`, `is_cloze_mode`, `is_ce_mode`, `is_sft_mode` |
| [`sleep.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/sleep.car) | **Autonomous Metacognitive Sleep Memory Consolidation Driver.** Traverses newly accumulated interaction episodes from Domain 7 and updates Continuous Hopfield memory basins and Tier 2 SQLite tables. | `main`, `cartan_sleep_consolidate_cycle` |

---

## 2. Core Neuro-Symbolic Cognitive Modules (`test/geomind/`)

| File | Purpose & Description | Key Functions / Symbols |
| :--- | :--- | :--- |
| [`chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl) | **Multimodal Neuro-Symbolic Chat Engine & Agentic Dispatcher.** Implements dynamic JIT context grounding, minimal startup prefill ($\le 30$ tokens), on-demand Domain 10 user attribute retrieval, conditional tool schema loading, Continuous Hopfield associative memory relaxation, Sasaki Brainstem MoE routing, agentic tool execution (`read_file`, `write_file`, `exec_command`, `browse_web`, `read_screen`), HTML parsing, SSRF sandboxing, protocol thought suppression, and token generation decoding. | `geomind_chat_init`, `geomind_chat_build_cognitive_preamble`, `geomind_chat_retrieve_jit_user_context`, `geomind_chat_get_tool_definitions`, `geomind_chat_requires_tool_definitions`, `geomind_chat_generate_reply_multimodal`, `geomind_sanitize_output_for_display`, `geomind_execute_tool_call` |
| [`moe.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/moe.cl) | **Sasaki Brainstem Mixture of Experts (MoE) Dynamic Router.** Evaluates tangent bundle phase-space $T\mathcal{M} = (x, \dot{x}) \in \mathbb{R}^{5120}$ at Layer 24. Computes Riemannian Sasaki metric distances to expert prototypes and performs invariant-safe Fast Path bypass ($w^* \ge 0.35$ directly to Anchor Layer 41) or Complex Path execution ($w^* < 0.35$). | `geomind_sasaki_moe_route`, `geomind_sasaki_metric_distance`, `geomind_moe_fast_path_gate` |
| [`streams.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/streams.cl) | **Lie Subgroup Stream Decomposition & Dynamic SVD Adapters.** Manages representations across the 8 maximal Lie subgroups of $E_8$. Loads and applies 13 MB calibrated orthonormal SVD projection adapters (`geomind_stream_adapters.bin`) and 2.09 MB stream domain masks (`geomind_stream_masks.bin`). | `geomind_streams_init`, `geomind_stream_project_in`, `geomind_stream_project_out`, `geomind_apply_stream_gated_logit_bias` |
| [`train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) | **Unified Autoregressive Training & Curriculum Engine.** Implements Cross-Entropy pre-training (`--train-ce`), Anchored Cloze Curriculum streaming (`--train-cloze`), and Supervised Fine-Tuning (`--train-sft`) over multi-dataset JSON manifests (`corpus.json`) with byte-exact resumption and target loss freezing. | `geomind_train_ce_loop`, `geomind_train_cloze_stream`, `geomind_sft_train_step`, `geomind_update_corpus_manifest` |
| [`cloze_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/cloze_engine.cl) | **Anchored Cloze Curriculum Engine.** Manages curriculum state and byte-exact multi-epoch resumption. | `cloze_engine_step`, `cloze_curriculum_stride` |
| [`sft_train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/sft_train.cl) | **Supervised Fine-Tuning Driver.** Executes instruction-tuning forward and backward steps over prompt-response pairs. | `sft_train_step`, `sft_batch_forward` |
| [`webgpu_causal_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/webgpu_causal_engine.cl) | **Native WebGPU Causal Training Driver.** Dispatches causal pre-training passes directly to WebGPU WGSL compute shaders. | `webgpu_causal_train_step` |
| [`merge_model_weights.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/merge_model_weights.cl) | **Zero-Day Spherical Linear Interpolation (SLERP) Fusion.** Fuses separate Safetensors weight matrices along spherical geodesic paths on the $S^{247}$ hypersphere, preserving angular momentum and geometric stability. | `cartan_slerp_weights`, `geomind_merge_checkpoints` |
| [`azr_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/azr_engine.cl) | **Absolute Zero Reasoning (AZR) Self-Play Engine.** Drives self-supervised compiler self-play loops, synthesizing and verifying CARTAN algorithmic programs without human demonstration. | `azr_generate_candidate_pass`, `azr_evaluate_compiler_fitness` |
| [`geomind_app.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/geomind_app.cl) | **High-Level Application Context.** Wraps lifecycle initialization, device detection, and session state. | `geomind_app_init`, `geomind_app_shutdown` |
| [`engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/engine.cl) | **Execution Dispatch Interface.** Connects high-level command modes to underlying computational kernels. | `geomind_engine_dispatch` |
| [`logger.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/logger.cl) | **Structured Logging & Diagnostics.** Formats operational telemetry and error channels. | `geomind_log_info`, `geomind_log_error` |

---

## 3. Geometric & Mathematical Foundations (`test/geomind/`)

| File | Purpose & Description | Key Functions / Symbols |
| :--- | :--- | :--- |
| [`geometry.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/geometry.cl) | **$E_8$ Root Lattice Differential Geometry.** Mathematical primitives over the 240 root vectors of $\mathfrak{e}_8$, root reflections, and Cartan matrix invariants. | `e8_root_dot`, `e8_weyl_reflection`, `e8_lattice_snap` |
| [`geom.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/geom.cl) | **Differential Geometry Vector & Matrix Utilities.** Vector norms, geodesic projections, and curvature helpers. | `geom_vector_norm`, `geom_dot_product` |
| [`ode_solver.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/ode_solver.cl) | **Symplectic & Hamiltonian Numerical Integrators.** High-order geometric Runge-Kutta and Verlet solvers for continuous Hamiltonian geodesic flows across curved manifold boundaries. | `ode_solve_hamiltonian_step`, `ode_symplectic_verlet` |
| [`ising_state_machine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/ising_state_machine.cl) | **Continuous Hopfield & Ising Spin Relaxation.** Implements continuous spin state transitions, temperature annealing, and Lyapunov energy minimization. | `ising_spin_flip_energy`, `ising_metropolis_step`, `hopfield_lyapunov_eval` |
| [`e8_attention_engine.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/e8_attention_engine.cl) | **Specialized $E_8$ Riemannian Metric Attention.** Curvature-weighted dot-product attention kernels scaling dynamically with localized Riemannian metric scalars. | `e8_attention_forward`, `compute_e8_metric_scalar` |

---

## 4. Standard Library Engine Dependencies (`src/std/`)

| File | Purpose & Description | Key Functions / Symbols |
| :--- | :--- | :--- |
| [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl) | **42-Layer Sovereign Transformer & CPU Threadpool.** Implements full 42-layer model forward passes, INT4 AVX2 quantized dot products (`@cartan_simd_dot_i4_f32`), lock-free CPU threadpool (`cartan_trans_pool_*`), GQA KV cache management with 96 StreamingLLM attention sinks, and LM head logit softcap clamping with protocol token masking. | `cartan_transformer_init_gpu_resident_int4`, `cartan_transformer_upload_gpu_resident_layer_int4`, `cartan_transformer_dispatch_gpu_layer_int4`, `cartan_transformer_dispatch_gpu_layer_batch_int4`, `cartan_manifold_layer_forward_batch_int4`, `cartan_tensor_compute_lm_head_logits`, `cartan_kv_cache_clear_range`, `cartan_trans_pool_init`, `cartan_trans_pool_enter_standby` |
| [`src/std/wgpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/wgpu.cl) | **Bare-Metal WebGPU Hardware Acceleration Engine.** Compiles WGSL compute shaders, mounts and pins all 42 INT4 layers (1.87 GB) in GDDR6 VRAM, coordinates ping-pong double-buffered staging, and dispatches batched sequence prefill kernels. | `cartan_wgpu_init`, `cartan_wgpu_create_pipeline`, `cartan_wgpu_create_bind_group`, `cartan_wgpu_dispatch_fused_geglu_down_read`, `cartan_wgpu_dispatch_fused_geglu_down_batch_read` |
| [`src/std/sqlite_vec.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/sqlite_vec.cl) | **Embedded Tier 2 Cognitive Memory Manager.** Connects to local SQLite WAL database managing the 10 Cognitive Domains, computes vector cosine similarities, stores/retrieves interlocutor attributes, and maintains relational rule dependencies. | `sqlite_vec_init_domain10`, `sqlite_vec_init_schema`, `sqlite_vec_get_user_attr`, `sqlite_vec_set_user_attr`, `sqlite_vec_find_entity_attribute_in_prompt`, `sqlite_vec_consolidate_episodes` |
| [`src/std/cargraph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cargraph.cl) | **Tier 1 Fast Working Memory Buffer (`.car_graph`).** Zero-copy flat binary buffer with strict 64-byte cacheline alignment for active working memory. | `cargraph_init`, `cargraph_write_node`, `cargraph_read_node` |
| [`src/std/cargraph_consolidate.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cargraph_consolidate.cl) | **Two-Tier Memory Consolidation Engine.** Flushes Tier 1 working memory graphs into persistent Tier 2 SQLite tables during sleep cycles. | `cargraph_consolidate_tier1_to_tier2` |
| [`src/std/tokenizer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/tokenizer.cl) | **SentencePiece BPE Tokenizer Wrapper.** High-performance string tokenization and ID-to-token text decoding for the 262,144 Gemma vocabulary. | `sentencepiece_encode`, `bpe_decode_token`, `cartan_hub_encode_text_to_tokens`, `cartan_tokenizer_sample_topp_topk` |
| [`src/std/vision.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/vision.cl) | **Multimodal Computer Vision Ingestion.** Loads raw PPM/BMP frames, performs hardware-accelerated bilinear spatial resizing, and converts images into normalized RGB tensors. | `vision_create_image`, `vision_resize_bilinear`, `vision_image_to_tensor` |
| [`src/std/hub.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/hub.cl) | **Safetensors Checkpoint Loader & Hub Connector.** Ingests authentic model weight checkpoints (`model.safetensors`, `geomind_grafted_multimodal.bin`) directly into memory. | `hub_load_safetensors`, `hub_fetch_weights`, `cartan_graft_multimodal_weights`, `cartan_load_signed_checkpoint` |
| [`src/std/fusion.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fusion.cl) | **Spherical Geodesic Weight Fusion.** Implements SLERP weight combinations across safetensors tensors. | `cartan_fusion_slerp` |
| [`src/std/distill.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/distill.cl) | **Logit Distillation Primitives.** Temperature-scaled KL divergence calculation over teacher-student distributions. | `distill_kl_divergence_loss` |
| [`src/std/domain_lexicon.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/domain_lexicon.cl) | **Domain Vocabulary Synsets.** Semantic grounding lexicons across mathematical, physical, and programming domains. | `domain_lexicon_lookup` |
| [`src/std/burroughs.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/burroughs.cl) | **Burroughs Lateral Cut-Up Generator.** Controlled stochastic entropy injection across Tier 1–3 abstraction tiers. | `burroughs_sample_cutup` |

---

## 5. Active Regression Test Suites (`Projects/geomind/`)

| Test Suite | Purpose & Tested Capability |
| :--- | :--- |
| [`test_jit_context_and_minimal_prefill.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_jit_context_and_minimal_prefill.car) | Validates minimal cognitive preamble ($\le 30$ tokens), targeted JIT user attribute retrieval, conditional tool schema loading, and 94.3% prefill reduction. |
| [`test_universal_interlocutor_and_greeting.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_universal_interlocutor_and_greeting.car) | Validates LM head protocol token masking (`100`, `101`, `98`), thought block sanitization, and dynamic greeting generation for recognized users vs guests. |
| [`test_interface_coloring_and_animation.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_interface_coloring_and_animation.car) | Validates compiler `\e` escape lowering, ANSI palette helpers, dynamic in-place rotating ASCII/braille spinners, and line erasure. |
| [`test_interface_formatting.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_interface_formatting.car) | Validates UI toggles (`/think`, `/stream`, `/telemetry`), structured output buffering, and non-blocking `/` key interruption. |
| [`test_agentic_web_and_screen.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_agentic_web_and_screen.car) | Validates hardware desktop screen OCR, web page retrieval, HTML link extraction, and SSRF sandboxing. |
| [`test_agentic_tools.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_agentic_tools.car) | Validates native file I/O (`read_file`, `write_file`, `list_dir`, `file_exists`) and command-line execution (`exec_command`). |
| [`test_face_mapping_and_user_domain.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_face_mapping_and_user_domain.car) | Validates 320-D eikonal facial embedding extraction, unit hypersphere projection, and Domain 10 template enrollment. |
| [`test_startup_biometric_onboarding.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_startup_biometric_onboarding.car) | Validates end-to-end camera frame capture, biometric authentication thresholding ($\ge 0.85$), and session onboarding. |
| [`test_multiturn_conversational_coherence.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_multiturn_conversational_coherence.car) | Validates multi-turn KV cache continuity, context window management, and dialogue coherence. |
| [`test_domain9_persistence.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_domain9_persistence.car) | Validates Domain 9 ethics, boundary persistence, and creator attribution invariants. |
| [`test_gpu_and_conversational_tools.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_gpu_and_conversational_tools.car) | Validates WebGPU INT4 tensor execution paired with conversational tool dispatch. |
| [`test_e8_canonical.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/test_e8_canonical.car) | Validates canonical $E_8$ root lattice coordinates, Weyl reflections, and Lie algebra invariants. |

---

## 6. Auxiliary Developer & Perception Tools (`tools/`)

| Tool | Purpose & Description |
| :--- | :--- |
| [`tools/read_screen_ocr.cs`](file:///C:/Users/rich-/source/repos/CARTAN/tools/read_screen_ocr.cs) / [`tools/build_screen_ocr.ps1`](file:///C:/Users/rich-/source/repos/CARTAN/tools/build_screen_ocr.ps1) | **Hardware-Accelerated Desktop OCR Utility.** Uses Win32 GDI screen capture, `SetProcessDPIAware()`, `winsta0\default` desktop attachment, and WinRT `Windows.Media.Ocr.OcrEngine` to extract on-screen text in under 0.4 seconds. |
| [`tools/calibrate_stream_adapters.py`](file:///C:/Users/rich-/source/repos/CARTAN/tools/calibrate_stream_adapters.py) | **SVD Stream Adapter Calibrator.** Extracts 13 MB orthonormal projection bases for the 8 maximal Lie subgroups into `geomind_stream_adapters.bin`. |
| [`tools/build_stream_domain_masks.py`](file:///C:/Users/rich-/source/repos/CARTAN/tools/build_stream_domain_masks.py) | **Lie Stream Vocabulary Mask Generator.** Generates 2.09 MB bitmasks uniting high-frequency English vocabulary with Lie subgroup domains (`geomind_stream_masks.bin`). |
| [`tools/quantize_manifold_int4.car`](file:///C:/Users/rich-/source/repos/CARTAN/tools/quantize_manifold_int4.car) | **Offline INT4 Quantizer.** Halves 42-layer checkpoint weights from 3.95 GB to 1.87 GB using symmetric min-max scaling. |
| [`tools/run_affected_tests.ps1`](file:///C:/Users/rich-/source/repos/CARTAN/tools/run_affected_tests.ps1) | **Targeted Regression Test Runner.** Selective test suite executor mapping modified files and sprint presets to official regression targets. |