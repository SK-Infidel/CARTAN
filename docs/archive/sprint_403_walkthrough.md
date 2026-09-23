# Sprint 403 Walkthrough: Domain-Matched Prequential Holdout Validation & Retired Dataset Purge

## 1. Executive Summary
- **User Directive Addressed**:
  > "You don't need to load 2048 tokens for EVERY dataset that it's got in hold out for every pass. Just the dataset that the next training chunk is going to train on."
- **Key Enhancements**:
  1. **Purged Obsolete Holdouts**: Eliminated legacy excerpts (ArXiv particle physics and TinyStories) from `pretrain_validation_holdout.txt`. Re-anchored holdout validation exclusively to the 5 active dataset families configured in `corpus.json` (FineWeb-Edu, OpenWebText, WikiText-103, Storytelling, and Mined Discourse), with ~2,200 words extracted directly from each domain's held-out tail.
  2. **Domain Isolation with `---DOMAIN_BREAK---`**: Added delimiters so `geomind_init_val_cache` pre-tokenizes each domain into a dedicated 2048-token chunk with zero inter-domain context bleed.
  3. **Domain-Family Resolver (`geomind_get_domain_family`)**: Added routing function mapping dataset file paths to active domain family indices (0: FineWeb-Edu, 1: OpenWebText, 2: WikiText-103, 3: Storytelling, 4: Mined Discourse).
  4. **Prequential Validation (`geomind_compute_validation_loss`)**: Updated validation to evaluate **only** the 2048-token holdout for the upcoming dataset family (`next_d_idx`), reducing evaluation latency from ~2.5s down to **~0.4s** and providing domain-aligned out-of-sample prequential metrics.

## 2. Changes Made
| File | Changes |
| :--- | :--- |
| [`test/geomind/trainingdata/pretrain_validation_holdout.txt`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/pretrain_validation_holdout.txt) | Purged ArXiv and TinyStories; populated with authentic tail paragraphs from the 5 active dataset families separated by `---DOMAIN_BREAK---`. |
| [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1550-L1585) | Handled `---DOMAIN_BREAK---` in `geomind_init_val_cache` to pack each domain family into a dedicated 2048-token chunk. |
| [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L1610-L1670) | Added `geomind_get_domain_family` and updated `geomind_compute_validation_loss` to accept `target_domain: float`. |
| [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl#L2340-L2355) | Wired prequential validation in `geomind_train_streaming_steady_state` targeting the upcoming dataset domain. |
| [`CHANGELOG.md`](file:///C:/Users/rich-/source/repos/CARTAN/CHANGELOG.md#L1-L24) | Documented Sprint 403 changes and parity verification. |
| [`ISSUES.md`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md#L2280-L2298) | Logged and resolved `[ISSUE-155]`. |

## 3. Empirical Verification Results
- **Binary Parity**:
  - `cartanc.exe` compiled `test/geomind/main.car` with Zig `-O3` LTO.
  - SHA-256 `1DF1AD1363871C13A16A45C593E07987A3678447EBB1D0BE84A077EDCF66B51D` verified across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
- **Analogy Arithmetic Benchmark (`--eval-analogy`)**:
  - King - man + woman = queen: PASS (Rank 1, Cosine: 0.421395, Margin: +0.109463)
  - he - him + her = she: PASS (Rank 1, Cosine: 0.485710, Margin: +0.110068)
  - father - man + woman = mother: PASS (Rank 1, Cosine: 0.468652, Margin: +0.097622)
  - boy - man + woman = girl: PASS (Rank 1, Cosine: 0.579984, Margin: +0.271068)
- **Live Streaming & Clean State**:
  - Verified live streaming with 5 pre-tokenized domain holdout chunks and domain-targeted prequential validation.
  - Clean weights and zero offsets restored to `corpus.json` and checkpoints for user launch.
