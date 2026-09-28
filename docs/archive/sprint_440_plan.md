# Sprint 440 Implementation Plan: GeoMind GPU VRAM Residency Realignment & Sub-Second Inference Optimization

## Problem Statement
When running GeoMind's interactive chat mode (`geomind.exe --chat`), response latency was observed to exceed 35 seconds per prompt. Profiling the execution environment revealed two cascading bottlenecks:
1. **Context Window VRAM Overflow**: Ollama defaulted Gemma 4's context window to `num_ctx: 131072` (9.7 GB VRAM footprint). On an NVIDIA RTX 2000 Ada Generation GPU (8 GB VRAM), 66% of the neural network was offloaded onto CPU/system RAM (`66%/34% CPU/GPU`).
2. **Hidden Deep Reasoning Token Budgeting**: Gemma 4 possesses an internal `thinking` capability. When prompts were evaluated via `/api/generate` without disabling internal reasoning, the model spent hundreds of unseen tokens in its `<think>` phase.

## Technical Architecture & Core Changes
1. **GPU VRAM Context Realignment (`num_ctx: 8192`)**:
   - Pin context window to 8,192 tokens in all Ollama requests (`cartan_gemma_engine.c`).
   - Reduces model VRAM footprint from 9.7 GB to 3.2 GB, achieving 100% GPU residency with zero CPU offloading.
2. **Conversational Latency Acceleration (`"think": false`)**:
   - Explicitly disable reasoning loop overhead for immediate conversational dialogue.
   - Boosts effective generation speed from ~1.2 tokens/sec (CPU hybrid) to 54.9+ tokens/sec (100% GPU VRAM).
3. **UTF-8 Console Stream Synchronization**:
   - Initialize Windows console encoding to UTF-8 (`SetConsoleOutputCP(CP_UTF8)` / `SetConsoleCP(CP_UTF8)`).
   - Strip diagnostic raw socket checkpoint logging.
4. **Binary Synchronization Across Workspaces**:
   - Synchronize compiled `build/geomind.exe` across `bin/geomind.exe`, `geomind.exe`, and `test/geomind/geomind.exe`.
