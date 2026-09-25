# SFT Training Plan: Full Corpus Restoration, Web Text & Gemma 4-Compatible Reddit Conversations

## 1. Executive Summary & Objective
This plan establishes the complete architecture, dataset acquisition strategy, and engine specifications for **Stage 3: Supervised Fine-Tuning (SFT)** of GeoMind in CARTAN. 

During Stage 1 (Cloze), the model successfully grounded fundamental lexical taxonomy units (Noun-Noun pairs, binomials, discourse markers) down to validation loss **3.808** across 240,000 mined cloze sentences. However, during Cloze harvesting (`tools/harvest_domain_ngrams.py`), the underlying corpora were accessed strictly via streaming (`streaming=True`) with a 25,000-sample limit, extracting only isolated phrase-matching sentences.

To achieve robust conversational ability, instruction compliance, web-scale world knowledge, and natural human dialogue flow without catastrophic forgetting:
1. **SFT will train on the full, complete source corpora from which cloze was mined** (TinyStories, WikiText-103, ArXiv STEM, OASST1, Alpaca, and the 240,000 continuous source sentences).
2. **SFT incorporates high-reasoning Web Text** (`HuggingFaceFW/fineweb-edu`, `Skylion007/openwebtext`).
3. **SFT incorporates natural Reddit Conversations** (`binhgiangnguyendanh/reddit_casual_conversation_for_alpaca_lora`, `sentence-transformers/reddit-title-body`) formatted strictly for **Gemma 4 conversational turn compatibility**.

---

## 2. Corpus Inventory & Reconciliation

### 2.1 Complete Dataset Portfolio
| Domain | Dataset Identifier | Source / Config | Target Size | Role in SFT |
|---|---|---|---|---|
| **Reddit Conversations** | `binhgiangnguyendanh/reddit_casual_conversation_for_alpaca_lora` | HF Hub | ~45,000 conversation threads | Multi-turn casual human dialogue, banter, pragmatic responses |
| **Reddit Q&A / Discourse** | `sentence-transformers/reddit-title-body` | HF Hub | ~100,000 high-karma posts | Community Q&A, advice, long-form discussion across diverse subreddits |
| **High-Reasoning Web Text** | `HuggingFaceFW/fineweb-edu` | `sample-10BT` partition | ~100,000 curated articles (~250 MB) | Educational web prose, factual accuracy, expository reasoning |
| **Open Web Text** | `Skylion007/openwebtext` | `train` | ~50,000 articles (~150 MB) | Human-curated general web text from high-karma Reddit outbound links |
| **Instruction Following** | `OpenAssistant/oasst1` | `train` tree dialogues | ~84,400 messages | Human-assistant instruction following, multi-turn task completion |
| **Instruction Compliance** | `tatsu-lab/alpaca` | `train` | 52,002 instruction-response pairs | General instruction compliance, formatting, structured outputs |
| **Narrative / Stories** | `roneneldan/TinyStories` | `train` | ~200,000 stories (~200 MB) | Causal narrative reasoning, moral consistency, vivid storytelling |
| **Structural Knowledge** | `Salesforce/wikitext` | `wikitext-103-raw-v1` | ~1.8 million sentences (~500 MB) | Syntactic depth, encyclopedic knowledge, expository coherence |
| **Scientific / STEM** | `gfissore/arxiv-abstracts-2021` | `train` | ~100,000 STEM abstracts (~150 MB) | Mathematics, physics, computer science, and technical rigor |
| **Local Continuous Cloze** | `mined_expanded_corpus_cloze_part01..06.txt` | Local disk | 240,000 sentences (35.2 MB) | Preserves all exact context sentences from Stage 1 Cloze training |
| **Local Literature & Prose** | `storytelling_corpus.txt` + `gutenberg_classics.txt` | Local disk | ~13.2 MB continuous prose | Literary style, classics (Plato, Shelley, Melville, Conan Doyle) |

---

## 3. Gemma 4 Compatibility & Chat Formatting Protocol

GeoMind uses the Gemma 4 neural architecture (2560 hidden dimension, 42 Lie projection layers, SentencePiece 256k/65k BPE vocab, and $\text{cap}=30.0$ hyperbolic logit soft-capping). All conversational and Reddit training data is standardized to the official Gemma 4 chat turn format:

```
<start_of_turn>user
{user_query_or_context}<end_of_turn>
<start_of_turn>model
{assistant_or_target_response}<end_of_turn>
```

### 3.1 Gemma 4 Tokenization & Sanitization Standards
1. **Control Tokens**:
   - `<bos>` = Token ID 2
   - `<eos>` = Token ID 1
   - `<start_of_turn>` = Token ID 106
   - `<end_of_turn>` = Token ID 107
2. **Multi-Turn Reddit Formatting**:
   - For Reddit multi-turn comment threads, odd turns are mapped to `user` and the concluding response is mapped to `model`:
     ```
     <start_of_turn>user
     @user1: Have you tried baking sourdough in a Dutch oven?
     @user2: Yes, it traps steam and produces a much crispier crust!
     @user3: What temperature do you preheat it to?<end_of_turn>
     <start_of_turn>model
     I usually preheat the Dutch oven to 450°F (230°C) for at least 45 minutes before loading the dough.<end_of_turn>
     ```
3. **Artifact Sanitization**:
   - Strip raw HTML tags, unescape entities (`&amp;`, `&lt;`), normalize curly quotes, and eliminate non-UTF-8 control bytes (`[\x00-\x1f\x7f-\x9f]`), preserving SentencePiece leading whitespace markers (`\u2581`).

---

## 4. Dataset Acquisition Tooling: `tools/download_full_sft_corpus.py`

A dedicated, high-speed acquisition tool (`tools/download_full_sft_corpus.py`) authenticates via cached HF token (`~/.cache/huggingface/token`) and creates the unified SFT dataset structure under `test/geomind/trainingdata/sft/`:

1. **`reddit_conversations_gemma.jsonl`**:
   - Downloads `binhgiangnguyendanh/reddit_casual_conversation_for_alpaca_lora` and formats directly into Gemma 4 turns.
2. **`reddit_qa_discourse_gemma.jsonl`**:
   - Streams from `sentence-transformers/reddit-title-body` across high-quality subreddits, formatting `title` as user prompt and `body` as model response.
3. **`fineweb_edu_curated.txt`**:
   - Downloads clean expository web articles from `HuggingFaceFW/fineweb-edu` (`sample-10BT`).
4. **`openwebtext_curated.txt`**:
   - Downloads diverse web articles from `Skylion007/openwebtext`.
5. **`oasst1_dialogues_gemma.jsonl`**:
   - Extracts complete conversation branches from `OpenAssistant/oasst1` into multi-turn Gemma turns.
6. **`alpaca_instructions_gemma.jsonl`**:
   - Formats `tatsu-lab/alpaca` into standard Gemma instruction turns.
7. **`tinystories_narratives.txt`**:
   - Full narrative prose partition from `roneneldan/TinyStories`.
8. **`wikitext103_structural.txt`**:
   - Continuous encyclopedic prose from `Salesforce/wikitext`.
9. **`arxiv_scientific_abstracts.txt`**:
   - STEM abstracts from `gfissore/arxiv-abstracts-2021`.

---

## 5. SFT Manifest Curriculum Architecture (`sft_manifest.json`)

`test/geomind/trainingdata/sft_manifest.json` partitions the training into balanced domain modules to prevent gradient collapse and maintain linguistic equilibrium:

```json
{
  "datasets": [
    "test/geomind/trainingdata/sft/reddit_conversations_gemma.jsonl",
    "test/geomind/trainingdata/sft/oasst1_dialogues_gemma.jsonl",
    "test/geomind/trainingdata/sft/alpaca_instructions_gemma.jsonl",
    "test/geomind/trainingdata/sft/reddit_qa_discourse_gemma.jsonl",
    "test/geomind/trainingdata/sft/fineweb_edu_curated.txt",
    "test/geomind/trainingdata/sft/openwebtext_curated.txt",
    "test/geomind/trainingdata/sft/wikitext103_structural.txt",
    "test/geomind/trainingdata/sft/arxiv_scientific_abstracts.txt",
    "test/geomind/trainingdata/sft/tinystories_narratives.txt",
    "test/geomind/trainingdata/mined_expanded_corpus_cloze_part01.txt",
    "test/geomind/trainingdata/mined_expanded_corpus_cloze_part02.txt",
    "test/geomind/trainingdata/mined_expanded_corpus_cloze_part03.txt",
    "test/geomind/trainingdata/mined_expanded_corpus_cloze_part04.txt",
    "test/geomind/trainingdata/mined_expanded_corpus_cloze_part05.txt",
    "test/geomind/trainingdata/mined_expanded_corpus_cloze_part06.txt",
    "test/geomind/trainingdata/storytelling_corpus.txt"
  ],
  "current_dataset_index": 0.0,
  "current_offset": 0.0,
  "current_epoch": 1.0,
  "current_lr": 0.0003
}
```

---

## 6. CARTAN Engine Modifications (`test/geomind/train.cl` & `main.car`)

1. **Manifest Default for Stage 3 (`train.cl`)**:
   - Default `stage_mode == 3.0` (`--train-sft`) to `test/geomind/trainingdata/sft_manifest.json`.
   - Implement missing manifest auto-discovery and non-destructive initialization guard (preserving Sprint 357 standards).
2. **Gemma Turn Ingestion & Loss Weighting**:
   - For JSONL entries with `<start_of_turn>user ... <start_of_turn>model ...`, backpropagate gradients over model response tokens, conditioning on user prompts.
   - For continuous prose text (`.txt`), execute standard autoregressive causal language modeling.
3. **Calibrated SFT Hyperparameters**:
   - **Baseline Starting Weights**: Loaded directly from Cloze-converged weights (`geomind_steady_state_weights.bin` / `geomind_slerp_fused_weights.bin`).
   - **Target Loss**: `2.00` (calibrated for high-precision SFT alignment).
   - **Learning Rate Range**: Floor `0.0001`, Ceiling `0.0005`, default `0.0003`.
   - **Perplexity Centering Controller**: Actively bounds gradient steps across disparate domain boundaries (e.g. from Reddit banter to ArXiv physics).
   - **Telemetry Output**: Logged to `logs/stage3_sft_training.log`.

---

## 7. Step-by-Step Implementation Roadmap

```
+--------------------------------------------------------+
¦ Step 1: Tooling Authoring                              ¦
¦ - Create tools/download_full_sft_corpus.py             ¦
¦ - Implement HF Hub download & Gemma turn formatters    ¦
+--------------------------------------------------------+
                           ¦
                           ?
+--------------------------------------------------------+
¦ Step 2: Full Dataset Acquisition                       ¦
¦ - Download Reddit, Web Text, OASST1, Alpaca, Stories,  ¦
¦   WikiText-103, and ArXiv STEM abstracts               ¦
¦ - Generate test/geomind/trainingdata/sft/ files        ¦
+--------------------------------------------------------+
                           ¦
                           ?
+--------------------------------------------------------+
¦ Step 3: Engine Wiring & Manifest Initialization        ¦
¦ - Update test/geomind/train.cl for sft_manifest.json   ¦
¦ - Recompile test/geomind/geomind.exe via cartanc.exe   ¦
+--------------------------------------------------------+
                           ¦
                           ?
+--------------------------------------------------------+
¦ Step 4: Verification & Baseline Step Execution         ¦
¦ - Run geomind.exe --train-sft -epochs 1 -target-loss 2.0¦
¦ - Verify WebGPU GPU compute, loss reporting, telemetry ¦
+--------------------------------------------------------+
```
