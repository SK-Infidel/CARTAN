# Startup Code Review: Sprint 464 (Chat & Training Integration with NSES Forward Pass)

## 1. Executive Summary & Context
In Sprints 461-463, CARTAN developed the Language & Discourse Domain (Domain 6), the automated neuro-symbolic rule generator (`ns_rule_generator.car`), the 110-rule authentic discourse corpus (`atomic_conceptnet_discourse.tsv`), and dynamic $O(1)$ zero-copy string pool resolution in `src/std/nses_pipeline.cl`.
This code review inspects [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl), [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl), and [`src/std/veto_gate.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/veto_gate.cl) to evaluate how symbolic rules and domain attractors integrate into the forward pass during both autoregressive chat inference and WebGPU training.

---

## 2. Dependency Graph & Architectural Flow

```mermaid
flowchart TD
    A["Atomic Discourse / NSES Knowledge Graph (.car_graph)"] --> B["NSES Master Pipeline (nses_pipeline.cl)"]
    B --> C["Veto Registry & Guardrails (veto_gate.cl)"]
    B --> D["Saliency Attractor Selector (saliency_attractor.cl)"]
    
    subgraph Chat Engine ("chat.cl")
        B --> E["Stage 1-4 Query Routing & Memory Traversal"]
        D --> F["Hopfield Attractor Memory Priming (cartan_hopfield_store_vector)"]
        F --> G["Hidden State Hopfield Relaxation (cartan_hopfield_relax)"]
        G --> H["Autoregressive E8 Attention Forward Pass"]
        H --> I["Logits Computation (lm_head)"]
        C --> J["NSES Symbolic Forward Logit Modulation (nses_pipeline_shape_loss)"]
        I --> J
        J --> K["Top-P / Top-K Token Sampling"]
    end
    
    subgraph Training Engine ("train.cl")
        B --> L["Domain 6 Dataset Routing ('discourse', 'dialogue', 'chat')"]
        D --> M["GPU VRAM Salient Attractor Staging (train_sync_salient_attractors_to_gpu)"]
        M --> N["WebGPU Forward Pass & Hopfield Injection"]
        C --> O["Automated Contradiction Loss Shaping (nses_pipeline_shape_loss)"]
        N --> O
        O --> P["Backpropagation Gradient Step"]
    end
```

---

## 3. Findings & Bugs Identified

### Finding 1: Ineffective Training Loss Shaping with Null Forbidden Token IDs (`[ISSUE-255]`)
- **Location**: [`src/std/veto_gate.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/veto_gate.cl#L257-L283) and [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2701)
- **Problem**: `veto_compute_symbolic_loss_penalty` requires an explicit non-null `forbidden_token_ids` pointer. In `train.cl:2701`, `nses_pipeline_shape_loss(nses_pipe, active_d, g_host_train_logits, 0.0, 0.15)` passes `0.0`, resulting in an immediate 0.0 return without shaping training loss or penalizing contradiction tokens.
- **Resolution**: Equip `VetoRegistry` with domain-indexed forbidden token stores and auto-extract domain contradiction tokens when `forbidden_token_ids == 0.0`.

### Finding 2: Missing Domain 6 (`LANGUAGE_DISCOURSE`) Dataset Routing in Training Loop
- **Location**: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2625-L2638)
- **Problem**: Dataset routing currently classifies datasets into Domains 1 (Physics), 2 (Topology), 3 (Complexity), 4 (Biology), and 5 (Causal Taxonomy). Language, dialogue, and discourse datasets (`discourse`, `dialogue`, `chat`, `language`, `atomic`, `conceptnet`) fall through to default Domain 5 instead of activating Domain 6.
- **Resolution**: Add explicit keyword routing for Domain 6.

### Finding 3: Missing Symbolic Logit Shaping in Chat Autoregressive Forward Pass
- **Location**: [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L768-L771)
- **Problem**: During autoregressive generation, repetition penalty and concept boost are applied to `logits_vec`, but `nses_pipeline_shape_loss` is never invoked. Contradictory tokens are only caught post-generation by the veto firewall (line 828), which discards the entire generation.
- **Resolution**: Apply `nses_pipeline_shape_loss` directly on `logits_vec` at each forward step.

### Finding 4: Missing Active Domain Attractor Priming in Chat Continuous Hopfield Memory
- **Location**: [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L721-L739)
- **Problem**: `chat.cl` queries and relaxes `hidden_state` against offline `hopfield_basins.bin`, but never stages the active domain's salient rule attractors from `nses_pipe.graph_file`.
- **Resolution**: Prime Hopfield memory with active domain salient rule vectors from `nses_pipe.graph_file` prior to continuous state relaxation.

### Finding 5: Preference for 110-Rule Bulk Discourse Graph in Interactive Chat
- **Location**: [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L474)
- **Problem**: `geomind_chat_get_nses_pipeline()` hardcodes `nses_knowledge.car_graph`, missing the richer 110-rule discourse corpus in `atomic_discourse.car_graph`.
- **Resolution**: Resolve `atomic_discourse.car_graph` when available.

---

## 4. Logical Dependency Analysis & Blast Radius
- `src/std/veto_gate.cl`: Upgrading `VetoRegistry` to store domain forbidden tokens and updating `veto_compute_symbolic_loss_penalty` to fall back to domain tokens ensures backwards compatibility with existing callers.
- `test/geomind/chat.cl`: Adding NSES logit modulation and Hopfield attractor priming directly sharpens the forward pass.
- `test/geomind/train.cl`: Adding Domain 6 routing and activating real loss penalties aligns training loss with linguistic invariants.
- All 73 existing compiler suite tests will be verified for zero regressions.
