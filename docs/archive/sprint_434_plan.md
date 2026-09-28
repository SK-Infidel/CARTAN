# Sprint 434 Plan: Neuro-Symbolic Cognitive Memory Architecture & Two-Tier Synaptic Substrate

## Sprint Goal
Implement Tier 2 embedded relational vector database (`sqlite-vec` via Windows C-FFI in `src/std/sqlite_vec.cl`) and Tier 1 fast zero-copy working memory buffer (`.car_graph` v2 in `src/std/cargraph.cl` with 64-byte cacheline alignment and entity state tracking), extend the 4-block structured scaffold in `src/std/prompt_scaffold.cl` to inject active entity states (`[WORLD-STATE: User='Rick', Stage='Sprint 434']`), establish the two-way materialization bridge, and validate 100% pass across regression gates.

## User Stories
1. **As GeoMind & CARTAN Runtime**, I need an embedded, daemonless relational vector store (6-table schema) in `src/std/sqlite_vec.cl` using native OS C-FFI (`winsqlite3`), so that memory is persisted across sessions with zero external dependencies and single-binary portability.
2. **As an Inference Engine**, I need `.car_graph` v2 binary headers in `src/std/cargraph.cl` to store `num_entities`, `offset_entities`, and maintain strict 64-byte cacheline alignment across all offsets to preserve SIMD dot product and DMA throughput.
3. **As a Reasoner**, I need `prompt_scaffold.cl` to inject active entity states into the 4-block scaffold (`[WORLD-STATE: User='Rick', Stage='Sprint 434']`) to eliminate context amnesia and belief contradictions without leaking into static guardrails.

## Architectural Architecture & Gates
- **TS-21.1: Embedded Relational Vector Store Engine**: 6 tables (`domains`, `rule_elements`, `dependencies`, `randomicity_fragments`, `episodes`, `entity_states`), verified via native C-FFI.
- **TS-21.2: Two-Way Materialization Bridge**: Materialize DB domain rules & entities into `.car_graph` v2 binary with strict 64-byte cacheline alignment.
- **TS-21.3: Zero-Copy .car_graph v2 Deserialization & SIMD Alignment**: Validate header v2 parsing, entity retrieval, and cacheline alignment ($offset \pmod{64} == 0$).
- **TS-21.4: 4-Block Scaffold World-State Injection**: Validate formatting of `[WORLD-STATE: ...]` within the structured prompt scaffold without delimiter leakage.
