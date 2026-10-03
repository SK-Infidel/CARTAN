# Spherical Cosine Geometry & Topological IC Migration

This walkthrough documents the major architectural shift in GeoMind v2.5 from Euclidean space heuristics to pure angular Spherical topology.

## 1. Spherical Cosine SFT Rewrite
> [!WARNING]
> Euclidean distances (like MSE) are fundamentally incompatible with norm-preserving optimizers. They fight magnitude constraints that the optimizer tries to lock, causing massive distortions.

- Replaced the naive MSE SFT loss with **Spherical Cosine Descent**.
- The BCEN optimizer `FinslerIGO` uses the Geodesic Exponential Map, which strictly rotates weights along the hypersphere without ever warping their $L_2$ norm.
- Replaced the linear gradient `grad = pred - target` with the Spherical Cosine gradient: `grad = (1 / pred_norm) * (pred_hat * cosine_sim - target_hat)`.

## 2. Intrinsic Structural Information Content
> [!IMPORTANT]
> The original topology used Brown corpus word frequencies to determine node spacing. This injected statistical biases from the English language rather than utilizing pure graph topology.

- Replaced NLTK's `wordnet_ic` corpus dependency with **Intrinsic Structural IC**.
- $IC(s) = -\log \left( \frac{|Hypo(s)|}{N} \right)$
- A node's IC is now derived purely from its topological descendants, making the entire E8 manifold a self-contained structural crystal.
- Because WordNet is a deep DAG, we implemented a non-recursive post-order DFS stack to flawlessly trace hyponym lineage without causing `RecursionError` bounds.

## 3. Pruning Fake Simulated Topology
- Custom domains (mathematics, physics, logic) were being forcibly grafted onto the tree using linearly simulated IC (`depth * 0.5`). 
- Because Intrinsic IC relies on global node counts, injecting fake nodes creates literal topological spikes that mathematically corrupt the hypersphere geometry.
- Custom domain injection has been completely pruned from the initialization pipeline to maintain pure WordNet topological purity until a mathematically robust multi-domain fusion script is developed.

## 4. Constant-Temperature MoE Routing
- Stripped the legacy `shannon_norm` extraction from the Sasaki Router.
- Because tokens now traverse `SphericalNorm` layers, their magnitude is mathematically locked. 
- The router correctly devolved into a constant-temperature router natively aligned to the fixed-radius hypersphere.

## Validation Results
- The engine compiles without breaking changes.
- SFT now converges on pure angles, properly rotating the topological embeddings without exploding gradient magnitudes.
- The `master_init.py` pipeline runs successfully and builds a topologically pure, artifact-free manifold ready for causal pretraining.
