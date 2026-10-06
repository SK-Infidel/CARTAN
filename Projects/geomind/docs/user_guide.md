# GeoMind Production User Guide & CLI/REPL Reference

## 1. Quick Start & Native Compilation

GeoMind is compiled natively with the CARTAN compiler (`cartanc.exe`):

```powershell
# Build production native executable with full optimizations
cartanc.exe Projects/geomind/main.car -o bin/geomind.exe

# Launch interactive multimodal chat engine (default WebGPU mode)
.\bin\geomind.exe

# Single prompt execution with token limit
.\bin\geomind.exe -prompt "Explain the Sasaki metric tangent bundle routing" -tokens 120
```

---

## 2. Global Execution Modes

GeoMind supports dedicated operational modes via top-level flags:

| Mode Flag | Description |
| :--- | :--- |
| `[None]` or `--chat` | **Interactive Chat Engine (Default).** Launches the WebGPU-accelerated multimodal chat engine, Continuous Hopfield resonator, and interactive REPL. |
| `--hf-download` | **Dataset Downloader.** Explores and caches HuggingFace dataset splits (`-repo <repo_id>`). |
| `--train-pre` | **Curriculum Pre-Trainer.** Pre-trains the continuous manifold on a specific corpus (`-target <file>`). |
| `--train-cloze` | **Anchored Cloze Curriculum Stream.** Runs structured fill-in-the-blank curriculum training with byte-exact resumption (`-target <file>`). |
| `--train-ce` | **Cross-Entropy Autoregressive Pre-Trainer.** Autoregressive next-token prediction with Zipfian logit adjustment. |
| `--train-sft` | **Supervised Fine-Tuning.** Trains instruction-following on conversation and QA pairs (`-repo <id> \| -target <file>`). |
| `--train-distill` | **Teacher-Student Distillation.** Transfers logit distributions from a larger teacher model via KL divergence minimization. |
| `--merge-slerp` | **SLERP Weight Merging.** Fuses two checkpoints along the $S^{247}$ spherical geodesic manifold without fine-tuning. |
| `--graft` | **Multimodal Checkpoint Grafting.** Grafts authentic 42-layer sovereign weights into the continuous manifold. |
| `--azr-selfplay` | **Absolute Zero Reasoning (AZR).** Self-supervised compiler self-play loop for algorithmic theorem synthesis. |
| `--ingest` | **Continuous Hopfield Memory Ingestion.** Encodes text file into 2,560-D attractor basins (`-target <file>`). |
| `--sleep` | **Autonomous Metacognitive Sleep.** Consolidates short-term fast weights and interaction episodes into long-term Tier 2 memory. |
| `--train-webgpu` | **Native WebGPU Training.** Executes pure GPU-resident causal training loops. |
| `--help`, `-h` | **Help Dialogue.** Displays CLI usage instructions and exits. |

---

## 3. Hardware, Compute & Context Flags

| Flag | Default | Description |
| :--- | :--- | :--- |
| `-cpu`, `--cpu`, `-no-gpu` | Disabled | Runs exclusively on CPU using AVX2 SIMD threadpool, bypassing WebGPU hardware acceleration. |
| `-context <num>` | `8192` | Sets maximum context window capacity in tokens. Supported values: `2048`, `8192`, `32768`, `65536`, `131072`. |
| `-tokens <num>` | `128` | Maximum tokens to decode on live single-prompt runs (`-prompt`). |
| `-temp <float>` | `0.7` | Softmax sampling temperature. Lower values are focused and deterministic; higher values increase entropy. |
| `-user <id>` | `User:Rick` | Sets the active interlocutor identity for session authentication and Domain 10 personalization. |
| `-stream-prune` | Disabled | Activates Lie subgroup domain pruning via 2.09 MB bitmasks (`geomind_stream_masks.bin`). |
| `-speculative-draft` | Disabled | Enables Continuous Hopfield 5-token speculative burst candidate generation. |

---

## 4. Biometric Interlocutor Authentication & Enrollment

GeoMind incorporates native biometric camera facial recognition using DirectShow / Win32 frame capture and 320-D eikonal face embeddings on the $S^{319}$ unit hypersphere.

```
[GeoMind Biometrics] Initiating biometric interlocutor scan...
[Camera Capture] Successfully captured 640x480 frame to 'camera_frame.bmp'
[GeoMind Vision] Loaded camera frame (640x480). Extracting 320-D eikonal face embedding...
[GeoMind Biometrics] Evaluating 'User:Rick' face map -> similarity: 0.9494 >= 0.85
[GeoMind Biometrics] INTERLOCUTOR RECOGNIZED: Rick (Father / Primary Creator). Session authenticated.
```

### Biometric REPL Commands:
- `/verify-face`: Re-scans the webcam and re-authenticates identity against Domain 10.
- `/register-face [user]`: Captures current camera frame and enrolls a new user face map in Cognitive Memory Domain 10.
- `/capture-face`: Manually triggers camera capture and saves `camera_frame.bmp`.

---

## 5. Interactive REPL Slash Command Catalog

Within the interactive chat session, the following slash commands are supported:

### Interface & Telemetry Toggles
- `/think`, `t`: Toggle display of internal cognitive thinking passes (Hopfield energy, concept taxonomy, Sasaki tangent bundle routing). Default: **Hidden**.
- `/telemetry`, `m`: Toggle real-time inference telemetry (prefill latency, decode tok/s, KV cache utilization). Default: **Hidden**.
- `/stream`, `s`: Toggle between **BUFFERED** mode (smooth, jitter-free full-response presentation) and **STREAMING** mode (real-time sub-token display). Default: **Buffered**.
- `/color`, `c`: Toggle ANSI terminal color styling. Default: **Enabled**.
- `/anim`, `a`: Toggle dynamic in-place ASCII/braille rotating spinners. Default: **Enabled**.

### Identity & Cognitive Memory
- `/whoami`: Displays active interlocutor profile, canonical attributes, and biometric verification status.
- `/who`, `/identity`: Displays GeoMind's self-identity, origin, and active cognitive preamble.
- `/switch-user <user>`: Switches active session identity (e.g., `/switch-user User:Rick`).
- `/clear`, `/reset`, `/new`: Clears active conversation history and resets the KV cache.
- `/remember <fact>`: Explicitly stores a semantic fact into Cognitive Memory Domain 10 (`USERS_AND_RELATIONSHIPS`).
- `/state`: Prints active cognitive entity states and active graph rules.
- `/sleep`: Executes an online metacognitive sleep memory consolidation cycle.
- `/context [num]`: Queries or dynamically resizes the active context window capacity (e.g., `/context 32768`).

### Agentic Host System & Perceptual Tools
- `/read <path>`: Reads and displays text file contents from disk.
- `/write <path> <content>`: Writes content to a file on disk.
- `/exec <cmd>`: Executes a command-line process and captures stdout/stderr.
- `/ls [path]`: Lists directory contents.
- `/browse <url>`: Fetches and parses a web page, stripping HTML and extracting hyperlinks (with SSRF protection).
- `/screen`: Captures active desktop screen and extracts on-screen text via hardware-accelerated WinRT OCR (biometric verification required).

### Session Control
- `/exit`, `/quit`, `exit`, `quit`: Shuts down threadpool workers cleanly and exits with status 0.

---

## 6. Non-Blocking Live Generation Interruption (`/` Key)

GeoMind monitors keyboard input asynchronously during every autoregressive decode step via CRT `_kbhit()`.

**To immediately interrupt generation:**
1. Press the `/` key at any point while GeoMind is thinking or generating tokens.
2. Generation halts immediately without thread hangs, memory leaks, or KV cache corruption.
3. The REPL transitions directly into command mode:
   ```text
   [Generation Interrupted by User]
   Command> /
   ```
4. Enter any REPL slash command (e.g., `/think`, `/clear`, `/exit`) or press Enter to resume chatting.