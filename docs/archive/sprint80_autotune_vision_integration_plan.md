# Sprint 80 Implementation Plan: Hardware Autotuned GEMM & Multimodal Vision Integration

## 1. Executive Summary
This sprint integrates two native CARTAN standard library modules into GeoMind (`test/geomind/`):
1. **Hardware-Aware Autotuned GEMM Tiling (`src/std/autotune.car`)**: Probe L1/L2 cache lines and SIMD width to execute tiled matrix multiplications (`autotune_tiled_gemm`) across 32-layer attention and LM-Head projections, accelerating inference by 4x-8x.
2. **Multimodal Vision-Language Ingestion (`src/std/vision.car`)**: Wire `--image [path.png]` CLI flag in `main.car` and `chat.car` to load images via `vision_load_image`, resize to $224 \times 224$ via `vision_resize_bilinear`, extract RGB patch embeddings, and project them into GeoMind's E8 Riemannian manifold attention sequence.

---

## 2. Step-by-Step Implementation
1. **`test/geomind/chat.car`**:
   - Include `../../src/std/autotune.car`.
   - Probe hardware profile (`let hw = autotune_probe_hardware()`).
   - Wire `geomind_chat_process_image_input(filepath)` using `vision_load_image` and `vision_resize_bilinear`.
   - Concatenate image patch embeddings into multi-layer E8 attention hidden states.
2. **Rebuild & Synchronize**:
   - Rebuild `geomind.exe` using `cartanc.exe` and sync to root and `bin/`.
3. **Verification**:
   - Run `geomind.exe --chat` and verify autotuned hardware profiling.
4. **Documentation**:
   - Log Sprint 80 in `CHANGELOG.md` and update `docs/ROADMAP.md`.
