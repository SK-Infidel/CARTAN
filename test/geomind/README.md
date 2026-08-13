# GeoMind Architecture & Model Test Suite

This directory contains **GeoMind**, a 100% self-hosted, multimodal neural model written natively in **CARTAN** and compiled directly into native machine code.

## Comprehensive Pipeline Documentation
For a complete theoretical, mathematical, and algorithmic walkthrough of the GeoMind pipeline (from SLERP weight merging and KL distillation to $E_8$ attention and BPE tokenizer decoding), see:
- [**GEOMIND_PIPELINE.md**](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/GEOMIND_PIPELINE.md)

## Execution Modes
GeoMind supports 4 primary execution modes driven by command-line flags:

```bash
# 1. Interactive Multimodal E8 Chat Engine
.\test\geomind\geomind.exe --chat

# 2. Supervised Fine-Tuning (SFT) Ingestion & Training
.\test\geomind\geomind.exe --train-sft

# 3. Teacher-Student KL Divergence Distillation
.\test\geomind\geomind.exe --train-distill

# 4. Zero-Day SLERP Geodesic Model Weight Merging
.\test\geomind\geomind.exe --merge-slerp
```

## Running the Complete Verification Suite
To execute all 4 modes in a single automated test pass:
```bash
.\src\archive\target\release\cartanc.exe build test/geomind/run_geomind_all_modes.car -o test/geomind/run_geomind_all_modes.exe
.\test\geomind\run_geomind_all_modes.exe
```
