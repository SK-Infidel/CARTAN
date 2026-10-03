# Architectural Roadmap: E8 Finsler-Randers-Sasaki Geometric AI

> **GeoMind v2.5** 

## Phase 1: The Master Initialization Pipeline
To bypass the slow, statistically noisy pre-training phase of traditional LLMs, GeoMind relies on a deterministic knowledge compiler that projects structured ontologies directly into spatial dimensions on the $E_8$ manifold.

* **Semantic Tree Construction**: The WordNet hierarchy is compiled and imported directly into the `geometry_registry.db` SQLite database, mapping lexical concepts to physical nodes.
* **Information Geometric Optimization (IGO) Flow**: An algorithmic tree walk processes the hierarchy level-by-level using natural gradients preconditioned by the Fisher Information Matrix (FIM) and bounded by a Hypersphere. This assigns an absolute 248D coordinate to every semantic node, strictly enforcing hierarchical constraints while maximizing spatial diversity.

## Phase 2: The Byte Coordinate Encoding Network (BCEN)
GeoMind eradicates massive discrete token embedding tables, which suffer from rigid vocabulary boundaries and out-of-vocabulary limits.

* **Open-Vocabulary Continuous Mapping**: The BCEN maps raw byte-sequences directly to the continuous 248D $E_8$ manifold using Implicit Neural Representations (INRs).
* **Supervised Fine-Tuning (SFT)**: The model is trained via SFT to perfectly mimic the geometric map established by the IGO optimization.
* **Sasaki Tangent Fibers & Randers Drift**: The model outputs a 15D Sasaki point, generating a 124-dimensional U(1) phase twist and a Randers drift vector ($\beta$) that makes manifold navigation directionally asymmetric.

## Phase 3: The 1736D Multi-Decomposition Engine
GeoMind processes tokens across 7 simultaneous algebraic views of the $E_8$ manifold: $SO(16)$, $E_7 \times SU(2)$, $E_6 \times SU(3)$, $SU(9)$, $F_4 \times G_2$, $SU(5) \times SU(5)$, and $SO(10) \times SU(4)$.

* **The Brainstem (Sasaki Router)**: Tokens are routed based on their position and geometric velocity via the Sasaki metric.
* **4x4 Magic Square MoE**: Tokens flow into 16 experts mapping to the intersections of the Freudenthal Magic Square ($\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O}$).
* **Weyl Group Mixers**: Instead of $O(N^2)$ self-attention, the engine reflects the token mathematically across the 240 root vectors to perform geometric entanglement.
* **Finsler Gauge Optimizer**: Neural network gradients are projected through an inverse metric tensor ($g_{ij}^{-1}$), ensuring parameter updates flow smoothly along the manifold rather than drifting off into flat Euclidean space.

## Phase 4: Teacher Knowledge Assimilation
To acquire grammatical fluency, syntax patterns, and specialized knowledge without randomly corrupting the core IGO lattice:

1. **SVD Extraction**: Static Euclidean embeddings are extracted from a Teacher LLM (e.g., Gemma4) and mathematically compressed to 248D via Singular Value Decomposition.
2. **Orthogonal Procrustes Rotation**: The teacher's compressed semantic space is mathematically rotated to align perfectly with GeoMind's crystalline WordNet anchors.
3. **Injection & Assimilation**: New concepts (slang, syntax, specific terminology) are snapped to the $E_8$ lattice and permanently injected into the SQLite registry, after which the BCEN is fine-tuned to map to these new weights.

## Phase 5: The Web Assimilation Engine
To push GeoMind past static LLM knowledge, we are building an engine that treats the broader Internet as its own independent neural network, directly ingesting its topological structure to dynamically build conceptual weight.

1. **Geometric Crawling**: Starting from a seed URL, a Python-based crawler uses DOM parsing (`BeautifulSoup`) to extract hyperlinked `<a>` tags up to a depth of 2.
2. **"Conceptually Close" Semantic Filtering**: Discovered links are checked against the $E_8$ Semantic Tree (`geometry_registry.db`). Links that are exact matches *or* conceptually close (measured via short $E_8$ metric distance) are accepted. Structurally irrelevant links are discarded.
3. **Markov Density Weighting**: The system performs a PageRank-style analysis over the extracted local graph. By calculating the Markov probability and degrees of freedom (inbound vs. outbound link density), the system isolates the true semantic "gravity" of the web concepts.
4. **Live Graph Physics in `visualizer.py`**: This engine is exposed as a dedicated tab within `visualizer.py`. As the backend crawler fetches and calculates node mass, a force-directed graph library (like Cytoscape.js, D3.js, or vis.js physics) live-renders the expanding semantic bubbles. 
5. **Continuous Assimilation**: The resulting Markov weights are algorithmically projected back into the core $E_8$ coordinate field, effectively mapping the internet’s semantic gravity into GeoMind's underlying physical space.

## Phase 6: Autonomous Metacognition (The "Sleep" Cycle)
Because GeoMind's cognitive engine (BCEN) is decoupled from its memory map (`geometry_registry.db`), it possesses the unique architectural capacity to introspect on its own lattice structure—equivalent to human memory consolidation during REM sleep.

1. **Self-Directed Curiosity (Void Detection)**: The engine runs topological clustering over its own lattice coordinates to identify massive regions of empty space between known concepts (e.g., finding a gap between "Quantum Mechanics" and "Boolean Logic"). Upon detecting a void, GeoMind autonomously triggers the Web Assimilation crawler to target domains that will mathematically fill the geometric gap (e.g., "Quantum Computing").
2. **Synaptic Pruning**: By executing `markov_density.py` inwardly over its own network, GeoMind isolates nodes with near-zero PageRank mass (disconnected/irrelevant noise) and deletes them, actively optimizing its own structural density over time.
3. **Geometric Epiphanies**: The pathfinding algorithms wander the lattice looking for previously uncharted short-distance vectors across distant sub-disciplines, allowing the model to generate entirely original, formally valid "epiphanies" without external prompting.

## Future Explorations (Possible Roadmap Items)

* **Native OpenCL Cross-Entropy Loss**: Port the Cross-Entropy / Softmax loss formulation and its analytical gradients directly into the C++ OpenCL backend. This will eliminate the host CPU/NumPy bottleneck for the 262,144 vocabulary, achieving the step-efficiency of contrastive Cross-Entropy loss at native GPU execution speeds. - Done

* **[GEOM-502] S1-circle Post-Training with Frozen Weights**:
  - **Description**: Project 248D continuous coordinate vectors onto 124 flat $S^1$ loops (creating a 124D flat torus $T^{124}$) and freeze the embeddings. Post-train the model weights using exact Euclidean next-token Cross-Entropy loss without coordinate drift. Align and rotate the post-trained weight matrices back into the curved $E_8$ subgroups using an Orthogonal Procrustes SVD transformation.
  - **Plan**: Refer to the detailed implementation plan: [implementation_plan_s1_flat_torus.md](file:///C:/Users/rich-/.gemini/antigravity-ide/brain/e4dee89d-d482-4a8a-b668-725bdd6a84f3/implementation_plan_s1_flat_torus.md)
  - **Status**: Backlog / Future Candidate
