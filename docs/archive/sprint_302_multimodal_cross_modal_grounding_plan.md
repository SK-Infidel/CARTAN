# Sprint 302 Implementation Plan: Multimodal Cross-Modal Grounding

## 1. Context & Objectives
- **Target**: [Phase 59 Item 4](file:///C:/Users/rich-/source/repos/CARTAN/docs/ROADMAP.md#L178): "Multimodal Cross-Modal Grounding: Connect SigLIP vision patch projections to `EikonalStream` and audio spectrogram features to `SpectralStream`, mapping sight, sound, and text into shared $E_8$ coordinates."
- **Defect Identified**: `[ISSUE-053]` in `ISSUES.md`: Vision (`geomind_chat_process_image_input`) only returns dummy image dimensions without projecting into the manifold, audio ingestion is non-existent, and visual/auditory signals are completely severed from the 42-layer manifold and continuous Hopfield attractor memory.

## 2. Mathematical & Architectural Design
1. **SigLIP Visual Patch Projection $\to$ Eikonal Stream (Sector 5, dims $1600..1919$)**:
   - Visual patch $P \in \mathbb{R}^{768}$ ($16 \times 16 \times 3$ RGB receptive field).
   - Linear projection $W_{\text{vis}} \in \mathbb{R}^{320 \times 768}$ mapping normalized pixels to the 320-D $SO(10) \times SU(4)$ geodesic ray-tracing submanifold.
   - Dynamic injection: $h[1600 + d] \leftarrow (1 - \alpha) h[1600 + d] + \alpha \cdot \text{Eikonal}(v_d)$.
2. **Audio Spectrogram Feature Extraction $\to$ Spectral Stream (Sector 2, dims $640..959$)**:
   - Audio waveform $x \in \mathbb{R}^{N}$ sampled at $16\text{ kHz}$.
   - Discrete Fourier Transform (DFT) harmonic energy filterbank extracting $K = 64$ frequency bins:
     $$X_k = \left|\sum_{n=0}^{N-1} x_n e^{-i 2\pi k n / N}\right|$$
   - Spectral projection $W_{\text{aud}} \in \mathbb{R}^{320 \times 64}$ mapping acoustic harmonics to the 320-D $E_6 \times SU(3)$ harmonic filter submanifold.
   - Dynamic injection: $h[640 + d] \leftarrow (1 - \beta) h[640 + d] + \beta \cdot \text{Spectral}(a_d)$.
3. **Shared $E_8$ Coordinate Attractor Convergence**:
   - Both visual and auditory embeddings fuse with token embeddings inside the 2,560-D manifold hidden state.
   - Continuous Hopfield relaxation ($h \to h^*$) pulls multimodal representations into shared semantic basins, achieving invariant zero-shot recall across sight, sound, and text.

## 3. Work Breakdown
1. **Standard Library Audio Module (`src/std/audio.cl`)**:
   - `audio_create_buffer(samples, sample_rate)`
   - `audio_compute_stft_magnitudes(audio_buf, num_bins)`
   - `audio_project_to_spectral_stream(magnitudes, target_dim)`
2. **Standard Library Vision Extension (`src/std/vision.cl`)**:
   - `vision_extract_patch(img, x, y, patch_w, patch_h)`
   - `vision_project_to_eikonal_stream(patch_tensor, target_dim)`
3. **C Runtime Multimodal Kernels (`src/cartanc/geomind_runtime.c`)**:
   - `cartan_multimodal_project_vision`: Project visual patch into Sector 5 ($1600..1919$).
   - `cartan_multimodal_project_audio`: Compute DFT spectrum and project into Sector 2 ($640..959$).
   - `cartan_multimodal_ground_hidden`: Fuses visual, auditory, and linguistic hidden vectors into shared $E_8$ space.
4. **GeoMind Multimodal Chat Integration (`test/geomind/chat.cl`)**:
   - Upgrade `geomind_chat_process_image_input` to construct real patch tensor and project into $E_8$ hidden manifold.
   - Implement `geomind_chat_process_audio_input` to ingest audio waveforms and project into spectral manifold.
5. **Target 54 Verification Suite (`test/compiler_suite/test_multimodal_grounding.car`)**:
   - Test 1: SigLIP visual patch extraction and 320-D Eikonal projection.
   - Test 2: Audio waveform DFT filterbank and 320-D Spectral projection.
   - Test 3: Multimodal 2560-D manifold assembly and sector isolation.
   - Test 4: Shared Hopfield attractor basin convergence across sight and text.
   - Test 5: C Runtime multimodal API bindings.
6. **Regression Test Runner (`test/compiler_suite/run_tests.car`)**:
   - Register Target 54 and ensure all 54 targets pass 100%.

## 4. Logical Dependency Graph
```
src/std/audio.cl ──┐
src/std/vision.cl ─┼──> test/geomind/chat.cl ──> test/geomind/main.car
                   │           │
src/cartanc/geomind_runtime.c ─┘
                   │
test/compiler_suite/test_multimodal_grounding.car (Target 54)
                   │
test/compiler_suite/run_tests.car
```
