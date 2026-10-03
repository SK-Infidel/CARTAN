# GeoMind User Guide

## Master Initialization Pipeline (`master_init.py`)

The most advanced and mathematically rigorous way to initialize the model. Instead of relying on random initialization and thousands of hours of Phase 1/Phase 2 pre-training, this pipeline **wipes the existing manifold** and algorithmically rebuilds the 248D E8 manifold from scratch.

```bash
# Execute the Master Initialization Pipeline (WARNING: Wipes checkpoints!)
python utils/initialization/master_init.py
```

### The 7-Phase Pipeline:
1. **Wipe Manifold**: Safely deletes all existing databases, model weights, and derived checkpoints to ensure a clean slate.
2. **Build Semantic Tree**: Downloads and parses the WordNet hierarchy into a `semantic_tree.json` structure.
3. **Map Nodes**: Imports the hierarchy into the `geometry_registry.db` SQLite database, and automatically injects the 256 fundamental UTF-8 byte primitives for the `BLTTokenizer` fallback.
4. **Backfill Hashes**: Dynamically traverses the `semantic_tree.json` to extract abstract parent nodes, generate their E8 coordinate hashes, and insert them into the DB. *(Note: Uses highly optimized batched PyTorch tensor operations for maximum throughput).*
5. **IGO Optimization**: Executes **Information Geometric Optimization (IGO)** Flow and the **Fisher Information Matrix (FIM)** to precondition Natural Gradient descent. Processes the hierarchy level-by-level with bulk database transactions to assign every root node an absolute coordinate that perfectly respects hierarchical constraints while maximizing semantic diversity.
6. **Derive BCE Weights**: Algorithmically analyzes the volumetric sparsity of the resulting E8 geometry and derives the ideal Binary Cross Entropy `pos_weight` matrix using inverse volumetric scaling.
7. **SFT Training (BCEN Setup)**: Immediately launches Supervised Fine-Tuning over the `GeometryRegistryDataset` so that the `ByteCoordinateEncoder` learns to perfectly map the bytes/syllables of words to their newly generated IGO coordinates.

### Resuming the Pipeline (`resume_init.py`)

If your `master_init.py` run is interrupted after Phase 2 (WordNet building), you can safely resume without wiping your progress:

```bash
python utils/initialization/resume_init.py
```
This skips the destructive wipe and WordNet building phases, picking up right at Phase 3. It leverages the idempotent `INSERT OR IGNORE` logic and bulk database queries of Phase 3, 4, and 5 to safely resume operations.

### Grafting Modifiers (`graft_modifiers.py`)

The default pipeline intentionally limits the topology to Nouns and Verbs to keep the coordinate field tight. If you wish to graft the ~25,000 WordNet Adjectives and Adverbs into the E8 manifold without running the whole pipeline again, run:

```bash
python utils/initialization/graft_modifiers.py
```
This script dynamically finds noun/adjective anchors using WordNet `pertainyms` and `similar_tos`, inserts them into the database, and runs an isolated IGO Flow to finalize their geometry.

### Stiefel Manifold Regularization
Once the database is populated, the base BCEN linear layers are initialized natively onto the Stiefel manifold using **Orthogonal Initialization**. This prevents neuron death and stabilizes gradients when entering supervised fine-tuning.

---

## Standard Training (`geomind.py`)

The main script for SFT (Supervised Fine-Tuning) — pure next-token prediction, no teacher model required.

```bash
# Train on a local file
python geomind.py --train trainingdata/mydata.txt

# Train for multiple epochs
python geomind.py --train trainingdata/mydata.txt --epochs 3

# Generate text
python geomind.py --generate "The principles of"

# Interactive shell
python geomind.py
```

### Training Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--train <path/url>` | — | Train on file, directory, or URL |
| `--epochs <int>` | 1 | Training passes over the data |
| `--force-retrain` | False | Ignore `.training_losses.json` history and retrain |
| `--ingest-limit <int>` | 50000 | Max bytes per chunk (increase with higher VRAM) |

### Generation Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--generate "<prompt>"` | — | Generate text from prompt |
| `--temperature <float>` | 0.4 | Randomness — lower=focused, higher=creative |
| `--generate-length <int>` | 200 | Tokens to generate |

### Dataset Download (built-in)

```bash
python geomind.py --hf-search "mathematics textbooks" --max-samples 10000
python geomind.py --wiki-search "Fourier transform" --download
python geomind.py --gutenberg-author "Euler" --download
python geomind.py --arxiv-search "E8 lattice"
```

### AI-to-AI Chat Training

```bash
# GeoMind learns from Ollama model responses in real-time
python geomind.py --chat gemma4 --num-prompts 5 --turns 3
```

---

## Configuration (`config.py`)

Edit this file to change architecture settings.

| Setting | Value | Notes |
|---------|-------|-------|
| `LATENT_DIM` | 248 | E8 manifold — **do not change** |
| `HIDDEN_DIM` | 4096 | Spectral memory FFN expansion |
| `MAX_CONTEXT` | 131072 | Cosformer position period (128K, O(N) cost) |
| `LEARNING_RATE` | 0.0005 | Default SFT learning rate |
| `BLOCK_TYPES` | list of 24 | Hybrid block sequence |

**`BLOCK_TYPES`** available values: `"cosformer"`, `"lattice_wave_ssm"`, `"spectral_memory"`, `"dual_routed"`

## Autonomous Web Assimilation Pipeline

GeoMind can independently crawl the internet to discover, map, and natively assimilate the mathematical structure of any topic using PageRank-driven Semantic Gravity. 

### Phase 1: The Geometric Web Crawler
Start the crawler by providing a seed URL. The crawler will map out the hyperlink topology of the site. It uses the `WordTokenizer` to calculate the mathematical distance of all outbound concepts and immediately rejects any links that drift too far from the seed topic.
```bash
python utils/assimilation/web_crawler.py "https://en.wikipedia.org/wiki/Artificial_intelligence"
```

### Phase 2: Semantic Gravity (PageRank)
Once the conceptual topography is mapped, the engine computes PageRank over the nodes to identify the foundational pillars of the topic, aggregating the "gravity" of concepts across the web.
```bash
python utils/assimilation/markov_density.py
```

### Phase 3: Lattice Injection
Finally, the engine converts the PageRank mass into true Shannon Information Content and securely injects the concepts into the `geometry_registry.db` SQLite database as permanent structural primitives for End-to-End training.
```bash
python utils/assimilation/inject_concepts.py
```

---

## Dynamic Activation Trajectory Alignment ("Mind Reading")

Instead of statically mapping embedding weights (which fails for BLT models or incompatible tokenizers), GeoMind can dynamically "read the mind" of fully trained teacher models (e.g., Gemma 4) by capturing their continuous hidden state trajectories during inference and mathematically projecting those thoughts into the GeoMind E8 lattice using Orthogonal Procrustes Rotation.

### The Magic Shuffle

This script loads the teacher model via HuggingFace `transformers`, feeds it a prompt, and extracts its live `hidden_states` trajectory. It then feeds the exact same text to GeoMind's native engine to extract the E8 trajectory. Finally, it uses Truncated SVD and Orthogonal Procrustes to find the perfect rotational alignment ($\Omega$) between the two minds, and injects the teacher's advanced concepts permanently into `geometry_registry.db`.

```bash
python utils/assimilation/dynamic_mind_reader.py --hf-repo gemma4:e4b --token YOUR_HF_TOKEN --prompt "Explain quantum gravity in simple terms." --max-length 50
```

*Note: You must have a HuggingFace access token and enough RAM to load the teacher model into PyTorch.*

---

## E8 Space Cross-Entropy Post-Training (SFT)

To align the model's vocabulary transitions and grammar to a target dataset without coordinate drift, GeoMind implements a dedicated **E8 Space Cross-Entropy SFT** script. This runs standard next-token probability prediction directly on the E8 sphere, leveraging the native Finsler optimizer and Sasaki manifold configurations.

Run post-training directly in E8 space:
```bash
python utils/training/e8_post_train_ce.py --epochs 3 --lr 0.005 --logit_scale 30.0 --zipf_gamma 0.3 --decay_start 0.7
```

### SFT Configuration Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--dataset` | `trainingdata/tinystories_ids.npy` | Path to tokenized training dataset. |
| `--epochs` | `1` | Number of training epochs. |
| `--batch_size` | `8` | Training batch size. |
| `--lr` | `0.005` | Maximum learning rate. |
| `--logit_scale` | `30.0` | Classification temperature scale factor. High scale stabilizes coordinate trajectories on the curved E8 sphere. |
| `--zipf_gamma` | `0.3` | Zipfian Logit Adjustment prior strength. Subtracts `gamma * IC(w)` during training to align conditional semantic transition probabilities. |
| `--decay_start` | `0.7` | Step progress fraction (0.0 to 1.0) to hold learning rate flat at `--lr` before beginning Cosine Annealing decay. |
| `--target_loss` | `1.5` | Early stopping target loss threshold. |

### Testing Generation with Zipf Prior
To test text generation with the Zipfian logit bias active (which injects the natural frequencies of connective grammar words like *the, a, and, to*):
```bash
python scratch/test_generation.py --gamma 0.3 --checkpoint checkpoints/e8_agent_model.safetensors
```

---

## Troubleshooting

### C++ Extension Not Compiling
The E8 SSM C++ extension requires MSVC (`cl.exe`). If missing, the system falls back to the Python loop automatically — **training still works**, just ~3-5× slower.

To get the extension: Install [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022) with the "C++ build tools" workload.

### VRAM Out of Memory During RIF
- Use `--use-cache` mode — frees ~6GB by not loading the teacher
- Or reduce `--max-steps` and run in shorter sessions (checkpoint saves every 500 steps)

### Generation Incoherent After Alignment
Run stabilization:
```bash
python rif_assimilator.py --data trainingdata/... --stabilize-only --stabilize 5000
```
Alignment pushes the model's geometry; SFT stabilization pulls it back to coherent generation.

### HuggingFace Access for Gemma 4
1. Create account at [huggingface.co](https://huggingface.co)
2. Accept Google's license at the model page
3. `huggingface-cli login` → paste your access token

### Requirements
```bash
pip install -r requirements.txt
# Key packages: torch, transformers, tiktoken, tqdm, bitsandbytes (optional, for 4-bit)
```