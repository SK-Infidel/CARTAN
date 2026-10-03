# Goal: 28-Combination Routing Experiment & Domain Analysis

The objective is to determine the optimal routing strategy for different data domains by testing 28 combinations (7 processing streams $\times$ 4 attention mechanisms) and evaluating Loss, Perplexity, and Surprise for each datatype.

## 1. Domain Datasets Determination

I recommend the following 5 distinct domains for the experiment to get a robust topological mapping profile:
1. **Logic/Relational**: `wikidata_logic.json` (Currently open in your workspace). Tests graph-like relational reasoning.
2. **Mathematics**: A short dataset of proofs or algebraic equations (tests strict symbolic constraints).
3. **Physics/Geometrodynamics**: A paragraph from your anisotropic theory of everything (tests abstract continuous concepts).
4. **Code**: A Python algorithm snippet (tests syntactic structure and precise formatting).
5. **Literature/Prose**: A natural language paragraph (e.g., Wikipedia or classical literature) to test unstructured semantic entropy.

## 2. Restoring the 4 Attention Mechanisms (OpenCL Porting)

You noted that "Inverse Riemannian" is the backward pass and asked about the **Wave Propagation** attention. During the massive Phase 2 migration to the pure C++ OpenCL backend, the `E8LatticeWaveSSM` (Wave Propagation), `Spectral Memory`, and `Dual Routed` mechanisms were left behind as PyTorch modules. Currently, `E8CosformerAttention` is the only active one in the OpenCL pipeline.

To execute the 28 combinations natively on the GPU, I will port the missing mechanisms into the OpenCL backend:
1. **Cosformer Attention**: (Already implemented in OpenCL).
2. **Lattice Wave SSM (Wave Propagation)**: I will port `csrc/e8_ssm.cpp` into pure OpenCL (`kernels.cl.h`) so it can propagate waves across the Lie Bracket state space natively.
3. **Spectral Memory**: I will port this into OpenCL (Fourier/Spectral filtering over the E8 manifold).
4. **Dual Routed Attention**: I will port this into OpenCL (dynamically combining wave/spectral with cosformer similarities).

Additionally, I will update the backward pass for all of these to utilize the **Inverse Riemannian** mapping, ensuring that gradients travel back up the lattice via the least action path instead of fighting the curved topology.

## 3. Isolating the 7 Streams (C++ API Update)

Currently, the C++ `GeoMindHybridEngine::forward` aggregates all 7 streams into a single Fréchet mean before returning to Python. To evaluate them individually without training interference:
- I will add a `forward_all_streams(token_ids, batch, seq_len, metric_tensor)` method to `csrc/engine.cpp` and expose it via `csrc/bindings.cpp`.
- This will return a Python list of 7 independent `geomath.Tensor` outputs, allowing us to calculate the loss for *each specific stream* on a single forward pass.

## 4. Experiment Pipeline

I will create an experiment script `scratch/routing_experiment.py` that will:
1. Load the 5 domain datasets and tokenize them.
2. Loop through the 4 Attention Types.
3. Call `forward_all_streams()` to get the 7 stream outputs simultaneously.
4. Calculate:
   - **Loss**: Standard Cross-Entropy against the shifted targets.
   - **Perplexity**: $\exp(\text{Loss})$.
   - **Surprise (Information Gain)**: $\Delta$ in probability distribution entropy.
5. Output a structured report/table showing the optimal (Stream, Attention) combination for each Domain.

## Open Questions

> [!IMPORTANT]  
> 1. Do you approve of the 5 domains suggested? I can easily generate the placeholder paragraphs for Math, Physics, Code, and Prose if you agree.
> 2. Do the 4 defined Attention Mechanisms (Metric Topologies) align with your theoretical framework, or did you have 4 specific structural variations of the Cosformer in mind (e.g., different positional encodings, local vs global context)?
> 3. Does this architectural plan accurately reflect how you want to conduct the evaluation?
