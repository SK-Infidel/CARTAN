# Cognitive Memory Architecture & Two-Tier Synaptic Substrate Plan
**Solving Context Amnesia, Catastrophic Forgetting, and Epistemic Contradictions in Continuous Neural-Symbolic AI**

---

## 1. System Vision & The Two-Tier Cognitive Hierarchy

Current LLMs and neural architectures suffer from three fundamental memory failures:
1. **Context-Window Amnesia ($O(N^2)$ Quadratic Attention)**: Memory is constrained to transient prompt tokens; once the context slides or restarts, all episodic interaction is lost.
2. **Catastrophic Forgetting (Weight Overwriting)**: Learning new facts via backpropagation alters global weights, corrupting previously stabilized representations.
3. **Flat Semantic Retrieval Collisions (RAG Failures)**: Naive vector databases lack time awareness, belief revision, and entity tracking, retrieving outdated or contradictory facts alongside active ones.

To permanently solve this, GeoMind and CARTAN implement a **Two-Tier Cognitive Memory Hierarchy**:

```
┌────────────────────────────────────────────────────────────────────────┐
│               Tier 2: Deep Neocortical Relational Store                │
│                 (PostgreSQL + pgvector / sqlite-vec)                   │
│  • Unbounded long-term semantic, episodic & entity memory              │
│  • 6-table relational schema with ACID transactions                    │
│  • Temporal decay, belief revision, and multi-hop graph queries       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
           ┌────────────────────────┴────────────────────────┐
           │                                                 │
           ▼ (Materialize / Pre-compile)                     │ (Sleep Consolidation /
  [Wakeup / Domain Switch]                                   │  Synaptic Ingestion)
  Extract active domain rules,                               │  Flush new interactions,
  strict guardrails & entity states                          │  update Hebbian weights,
           │                                                 │  prune decayed synapses
           ▼                                                 │
┌────────────────────────────────────────────────────────┐   │
│           Tier 1: Prefrontal Working Memory            │   │
│                      (.car_graph)                      │───┘
│  • Zero-copy mmap binary in local RAM/cache            │
│  • Microsecond SIMD vector dot products                │
│  • Direct CSR graph traversal & online Hebbian tuning  │
│  • Inviolable physical & safety guardrail injection    │
└────────────────────────────────────────────────────────┘
```

---

## 2. Tier 2: Enhanced 6-Table Relational Schema

To address temporal recency, belief updates, chronological episodes, and current world-state, the database schema expands from 4 to 6 interconnected relational tables:

```sql
-- Table 1: High-Level Cognitive Contexts & Operational Boundaries
CREATE TABLE domains (
    domain_id SERIAL PRIMARY KEY,
    name VARCHAR(64) UNIQUE NOT NULL,
    description TEXT,
    embedding vector(1536),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table 2: Ground Truth, Guardrails, and Distilled Semantic Rules
CREATE TABLE rule_elements (
    element_id SERIAL PRIMARY KEY,
    domain_id INT REFERENCES domains(domain_id) ON DELETE CASCADE,
    element_type VARCHAR(32) NOT NULL, -- 'guardrail_hard', 'fact_grounding', 'episodic_rule'
    content TEXT NOT NULL,
    embedding vector(1536),
    is_strict BOOLEAN DEFAULT FALSE,    -- TRUE = Inviolable deterministic guardrail
    confidence FLOAT DEFAULT 1.0,       -- 0.0 to 1.0 epistemic certainty
    status VARCHAR(16) DEFAULT 'active',-- 'active', 'superseded', 'refuted'
    superseded_by_id INT REFERENCES rule_elements(element_id),
    access_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    decay_half_life_days FLOAT DEFAULT 30.0
);

-- Table 3: Causal Logic & Hebbian Plasticity Edges
CREATE TABLE dependencies (
    dependency_id SERIAL PRIMARY KEY,
    source_element_id INT REFERENCES rule_elements(element_id) ON DELETE CASCADE,
    target_element_id INT REFERENCES rule_elements(element_id) ON DELETE CASCADE,
    relationship_type VARCHAR(32) NOT NULL, -- 'requires', 'associates', 'contradicts'
    weight FLOAT DEFAULT 1.0,               -- Heuristic strength (1.0 to 5.0)
    last_traversed TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_dependency_pair UNIQUE(source_element_id, target_element_id, relationship_type)
);

-- Table 4: Curated Burroughs Lateral Primes (Creativity Injection)
CREATE TABLE randomicity_fragments (
    fragment_id SERIAL PRIMARY KEY,
    domain_id INT REFERENCES domains(domain_id) ON DELETE SET NULL,
    fragment_text TEXT NOT NULL,
    entropy_tier INT DEFAULT 1,             -- 1 = subtle lateral leap, 3 = radical abstraction
    usage_count INT DEFAULT 0
);

-- Table 5: Chronological Episodic Interaction Stream (Narrative History)
CREATE TABLE episodes (
    episode_id SERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    domain_id INT REFERENCES domains(domain_id) ON DELETE SET NULL,
    speaker VARCHAR(32) NOT NULL,           -- 'user', 'assistant', 'system'
    content TEXT NOT NULL,
    embedding vector(1536),
    consolidated BOOLEAN DEFAULT FALSE,     -- TRUE once digested into semantic rules
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Table 6: Deterministic World-Model / Active Entity-State Tracking
CREATE TABLE entity_states (
    state_id SERIAL PRIMARY KEY,
    domain_id INT REFERENCES domains(domain_id) ON DELETE CASCADE,
    entity_name VARCHAR(64) NOT NULL,       -- e.g. 'user', 'project', 'geomind'
    attribute_name VARCHAR(64) NOT NULL,    -- e.g. 'preferred_name', 'current_stage'
    attribute_value TEXT NOT NULL,
    confidence FLOAT DEFAULT 1.0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_entity_attribute UNIQUE(domain_id, entity_name, attribute_name)
);
```

---

## 3. Tier 1: Native `.car_graph` v2 Binary Buffer Specification

The in-memory execution buffer maintains zero-copy, mmap-backed performance while encoding the new schema extensions:

1. **Header Layout (`CarGraphHeader_v2`)**:
   - `magic`: 8 bytes (`CARGRAPH`)
   - `version`: 2.0
   - `embedding_dim`: 1536
   - `num_domains`, `num_rules`, `num_strict_rules`, `num_edges`, `num_fragments`
   - `num_entities`: Active entity state count
   - `offset_domains`, `offset_rules`, `offset_csr_ptrs`, `offset_csr_edges`, `offset_fragments`, `offset_entities`, `offset_embeddings`, `offset_strings`.

2. **Rule Metadata Structure (`RuleElementMeta_v2`)**:
   ```
   [ element_id: f64 ][ domain_idx: f64 ][ element_type: f64 ][ is_strict: f64 ]
   [ confidence: f64 ][ status_flag: f64 ][ string_offset: f64 ][ string_len: f64 ]
   [ embedding_idx: f64 ][ last_accessed: f64 ][ access_count: f64 ][ decay_factor: f64 ]
   ```

3. **Entity State Entry (`EntityStateEntry`)**:
   ```
   [ domain_idx: f64 ][ entity_str_offset: f64 ][ attr_str_offset: f64 ][ val_str_offset: f64 ]
   ```

---

## 4. Two-Way Synchronization Bridge

### Phase A: Materialization (DB $\rightarrow$ `.car_graph`)
- **Trigger**: Startup, domain shift, or user context switch.
- **Process**:
  1. Retrieve active domain record from `domains`.
  2. Fetch all strict guardrails: `WHERE domain_id = active_id AND is_strict = TRUE`.
  3. Fetch top-$N$ active semantic rules: `WHERE domain_id = active_id AND status = 'active'` ordered by recency and weight.
  4. Fetch causal edges from `dependencies` and current entity values from `entity_states`.
  5. Compile and serialize into `test/geomind/trainingdata/nses_knowledge.car_graph`.
  6. Memory-map `.car_graph` directly into `NSES_Pipeline` structs in microsecond time.

### Phase B: Metacognitive Sleep Consolidation (`.car_graph` $\rightarrow$ DB)
- **Trigger**: `--sleep` cycle, training epoch boundary, or idle background consolidation.
- **Process**:
  1. **Episodic Ingestion**: Scan unconsolidated rows in `episodes`, extract candidate facts, and generate candidate `rule_elements`.
  2. **Belief Revision & Deduplication**: If an ingested statement refutes an existing rule, update the old rule's `status = 'superseded'` and link `superseded_by_id`.
  3. **Hebbian Synapse Sync**: Read updated edge weights from the working memory graph and execute batched `UPDATE dependencies SET weight = ...`.
  4. **Ebbinghaus Synaptic Pruning**: Apply exponential decay to rules where `access_count` is low and `NOW() - last_accessed_at > decay_half_life`. Decayed non-strict rules are archived or pruned.
  5. **World-Model State Flush**: Upsert current entity states into `entity_states`.
  6. **Re-materialize Clean Hot Buffer**: Write the freshly optimized, compacted `.car_graph` back to disk.

---

## 5. Phased Implementation Roadmap

```
Sprint 434: Relational Cognitive Schema & Database Bridge
├── Setup database schema (domains, rule_elements, dependencies, fragments, episodes, entity_states)
├── Implement database client adapter in tools/ & CARTAN standard library
└── Author schema migration and seed scripts

Sprint 435: CarGraph v2 Binary Format & Zero-Copy Engine
├── Expand cargraph.cl with v2 header, entity tables, and belief flags
├── Implement high-speed SIMD vector dot-product and CSR graph traversal
└── Author regression harness verifying v2 binary layout and memory isolation

Sprint 436: Task Materializer & Context Compiler (DB -> CarGraph)
├── Author high-speed materialization pipeline compiling DB subgraphs into .car_graph
├── Implement active entity state injection into prompt scaffolds
└── Empirically verify sub-10ms compilation latency and guardrail integrity

Sprint 437: Metacognitive Sleep Consolidator (CarGraph -> DB)
├── Implement episodic interaction logging during chat turns
├── Implement automated belief revision (supersession) and Hebbian weight flushing
└── Implement Ebbinghaus half-life synaptic decay and pruning in sleep phase

Sprint 438: End-to-End GeoMind Neural-Symbolic Grounding
├── Connect live memory retrieval and entity state lookups to chat and training engines
├── Verify elimination of context amnesia and contradiction resolution
└── Full verification across 13 regression targets and binary synchronization
```

---

## 6. Definition of Done (DoD)
- [ ] Database schema deployed and verified with full relational integrity and vector indexes.
- [ ] Native `.car_graph` v2 compiles and passes all static type checks via `cartanc.exe`.
- [ ] Sub-10ms materialization from DB to `.car_graph`.
- [ ] Microsecond retrieval from `.car_graph` during inference turns (zero network/SQL calls in loop).
- [ ] Sleep consolidation cleanly updates weights, supersedes refuted facts, and prunes decayed synapses.
- [ ] Zero mock/simulated operations; genuine mathematical and database computations throughout.
- [ ] Complete documentation, changelog update, and archived walkthroughs.
