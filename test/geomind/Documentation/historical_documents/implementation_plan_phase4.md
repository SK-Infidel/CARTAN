# Phase 4: Teacher Knowledge Assimilation

Following the validation of our model on topological learning, we are transitioning to **Phase 4: Teacher Knowledge Assimilation**. Our goal is to infuse GeoMind with grammatical fluency, syntax patterns, and specialized knowledge from an established "Teacher" LLM without corrupting our core deterministic $E_8$ geometric map.

## Background Context
In previous testing (Alternative Phase 4), we observed that natively supervised fine-tuning (SFT) purely on geometric coordinate sequences led to Centroid Collapse. The model optimized to the topological center of mass rather than learning syntax dynamics. 

To overcome this, we fall back to our roadmap's actual Phase 4: leveraging an external Teacher LLM. We will extract its static embedding knowledge, compress it, geometrically align it to our $E_8$ space, and inject the mapped concepts directly into our `geometry_registry.db`. Because we deprecated BCEN in favor of direct $E_8$ mapping, injecting into the database immediately expands our `WordTokenizer` vocabulary and KD-Tree targets, empowering the causal transformer to construct and comprehend coherent grammar.

## User Review Required
> [!IMPORTANT]
> The scripts for this phase (`extract_teacher.py`, `procrustes_align.py`, `lattice_inject.py`) use `gpt2` as the default teacher model. Please confirm if you would prefer to use a different Teacher LLM (e.g., `meta-llama/Meta-Llama-3-8B`) before we execute the pipeline. Using larger models may require more RAM during SVD extraction.

## Open Questions
> [!WARNING]
> 1. Are there any specific subsets or domain-specific tokens you want to prioritize during the injection? 
> 2. `lattice_inject.py` assigns a static Information Content (IC) of 5.0 to assimilated teacher tokens. Is this acceptable, or should we estimate IC based on the teacher's original embedding norms or token frequencies?

## Proposed Changes

We will execute the existing pipeline scripts located in `utils/assimilation/` to perform the assimilation. 

### utils/assimilation/

#### [MODIFY] No code changes required, execution only
1. **SVD Extraction (`extract_teacher.py`)**: 
   - Downloads the teacher LLM embeddings.
   - Computes `TruncatedSVD` to project down to 248D.
   - Normalizes coordinates to the spherical $E_8$ manifold surface.
   - Outputs `teacher_gpt2_248d.npy` and `teacher_gpt2_vocab.json`.
   
2. **Procrustes Alignment (`procrustes_align.py`)**:
   - Loads GeoMind's current core WordNet anchors from `geometry_registry.db`.
   - Maps overlapping vocabulary tokens to compute an Orthogonal Procrustes rotation matrix $R$.
   - Rotates the entire Teacher vocabulary matrix by $R$ to cleanly snap it into GeoMind's crystalline orientation.
   - Outputs `aligned_teacher_gpt2_248d.npy`.

3. **Lattice Injection (`lattice_inject.py`)**:
   - Parses the aligned 248D vectors and matching vocabulary.
   - Injects each new word into `checkpoints/geometry_registry.db` with `is_assimilated = 1`.

### documentation/

#### [NEW] [Implementation_plan_phase4.md](file:///c:/Users/rich-/source/repos/GeoMind/documentation/Implementation_plan_phase4.md)
As per your rules, after approval, this implementation plan (and the associated tasks/walkthroughs) will be permanently recorded in the `documentation/` folder, and obsolete plans marked as deprecated.

## Verification Plan

### Automated Tests
- Run `python utils/assimilation/extract_teacher.py` and verify `.npy` and `.json` outputs exist.
- Run `python utils/assimilation/procrustes_align.py` and verify matrix alignment succeeds without `Identity rotation` fallback (assuming sufficient anchors exist).
- Run `python utils/assimilation/lattice_inject.py` and query the sqlite database to ensure the total rows in `geometry_registry` have increased significantly.

### Manual Verification
- Launch `chat.py` and query the model with conversational prompts. The system should now correctly map complex grammatical tokens and produce more fluent syntax natively.
