# Sprint 407 Implementation Plan: Native `.car_graph` Binary Storage Engine & SIMD Vector Core (NSES Phase 1)

## 1. Context & Objectives
- **Subproject**: Neuro-Symbolic Expert System (NSES) Phase 1
- **Isolation Guarantee**: Strictly isolated from `ISSUES.md` and `docs/ROADMAP.md`. All tracking maintained in [`test/geomind/Research/NSES_IMPLEMENTATION_PLAN.md`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/Research/NSES_IMPLEMENTATION_PLAN.md).
- **Core Deliverables**:
  1. [`src/std/cargraph.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cargraph.cl): Zero-copy flat binary file builder, serializer, and memory-mapped reader for `.car_graph`.
  2. [`src/cartanc/cargraph_simd.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/cargraph_simd.car): 4-way unrolled 1536-D SIMD cosine dot product and unit-sphere normalizer.
  3. [`test/geomind/nses/test_sprint1_binary_loader.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint1_binary_loader.car): Empirical test harness verifying `TS-1.1`, `TS-1.2`, and `TS-1.3`.

---

## 2. Architectural Design & Binary File Specification

### 2.1 File Header (`CarGraphHeader`, 64 Bytes)
- Bytes 0–7: Magic ASCII `"CARGRAPH"` (`0x4850415247524143`)
- Bytes 8–11: Version `1`
- Bytes 12–15: Flags (Endianness `0 = LE`, Precision `0 = FP64`, `1 = FP32`)
- Bytes 16–23: Total file size (bytes)
- Bytes 24–27: Embedding dimension (`1536`)
- Bytes 28–31: Number of domains (`num_domains`, including Domain 0)
- Bytes 32–35: Total rules count (`num_rules`)
- Bytes 36–39: Strict rules count (`num_strict_rules`)
- Bytes 40–43: Total CSR edges count (`num_edges`)
- Bytes 44–47: Burroughs fragments count (`num_fragments`)
- Bytes 48–55: Section offset: Domains metadata (4096-byte page aligned)
- Bytes 56–63: Section offset: Rules metadata
- Bytes 64–71: Section offset: CSR row pointers
- Bytes 72–79: Section offset: CSR edge targets
- Bytes 80–87: Section offset: Burroughs text fragments
- Bytes 88–95: Section offset: Embeddings matrix (64-byte cacheline aligned)
- Bytes 96–103: Section offset: String pool table

### 2.2 Rule Element Metadata (`RuleElementMeta`, 32 Bytes)
- `element_id`: uint32 index
- `domain_idx`: uint32 (0 = `SYSTEM_CORE`, $\ge 1$ = domain partitions)
- `element_type`: uint16 (`0 = guardrail_hard`, `1 = fact_grounding`, `2 = episodic`)
- `is_strict`: uint8 (`1 = unbreachable invariant`, `0 = associative`)
- `reserved`: uint8 (`0`)
- `string_offset`: uint32 (byte offset into string pool)
- `string_len`: uint32 (byte length of predicate text)
- `embedding_idx`: uint32 (vector index in embedding matrix)
- `flags`: uint32

### 2.3 Dynamic Delta Arena (`NSES_EdgeChunk`, 64 Bytes)
- `target_node_id[4]`: 4 $\times$ uint32 target nodes
- `weight[4]`: 4 $\times$ float32 Hebbian synaptic weights
- `relation_type[4]`: 4 $\times$ uint16 relation predicates
- `timestamp`: uint64
- `next_chunk_offset`: uint64 (atomic CAS link for dynamic growth)

---

## 3. Empirical QA Test Gates

| Gate ID | Verification Description | Pass Condition |
| :--- | :--- | :--- |
| **`TS-1.1`** | Bitwise roundtrip serialization/deserialization | 100% bit-for-bit exact header, rules, and embeddings match |
| **`TS-1.2`** | 64-byte alignment verification | `(uintptr_t)embedding_ptr % 64 == 0` for all vectors |
| **`TS-1.3`** | Truncated/corrupted header fuzzing | Malformed magic/truncated lengths rejected safely with return `0.0` (zero segfaults) |
| **`TS-1.4`** | Performance benchmark | Initialization $\le 1.0\text{ ms}$, SIMD 1536-D dot product $\le 2.0\text{ }\mu\text{s}$ |
