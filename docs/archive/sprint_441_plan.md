# Sprint 441 Plan: Purge External Delegation & Restore 100% Native GeoMind Generation

## Objective
Completely eradicate all external model delegation, socket bridges, and Ollama connections, ensuring GeoMind operates strictly as a self-contained autonomous cognitive neural language engine.

## Scope
1. **Source Purge**:
   - Delete `src/std/cartan_gemma_engine.c`.
   - Remove `cartan_ollama_*` declarations and branching from `test/geomind/chat.cl`.
2. **Toolchain & I/O Isolation**:
   - Extract native stdin reader into `src/std/cartan_native_io.c`.
   - Update `tools/zig_wrapper.py` to link only native I/O.
3. **Native Neural Verification**:
   - Compile `build/geomind.exe` with `cartanc.exe`.
   - Verify native autoregressive generation runs exclusively on GeoMind's internal weights and Lie algebra attention.
