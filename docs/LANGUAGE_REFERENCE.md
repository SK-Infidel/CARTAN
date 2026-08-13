# Cartan Language Reference

This document serves as the canonical reference for Cartan's syntax, types, and compiler features.

---

## 1. Primitives

Cartan operates natively on a few carefully constructed primitive types:

- `f32` / `float`: 32-bit floating point number. (All standard math resolves to this).
- `i32` / `int`: 32-bit integer.
- `bool`: Boolean logic (`true`, `false`).
- `ptr`: A raw memory pointer (often used for C-FFI interfacing).
- `string`: Immutable string literals (`"hello"`).
- `tensor`: N-dimensional contiguous arrays, compiled natively.
- `stream`: Asynchronous, non-blocking hardware data pipelines.
- `vector[N]`: Standard Euclidean ambient or intrinsic tangent vector.
  - **Syntax**: `vector[N] at anchor_tensor` (Tangent vector anchored at target manifold coordinates).
- `lattice[L]`: An algebraic lattice (e.g. `lattice[E8] l`).
- `tree<T>`: A hierarchical heap-allocated search tree holding instances of `T` (e.g. `tree<tensor> t`).
- `dataframe`: A typed database-like table structure.

---

## 2. Variables & Constants

Variables are declared with `var`. Constants are declared with `const`.

```cartan
var my_variable = 42.0;
const PI = 3.14159;
```

---

## 3. Control Flow

Cartan supports standard imperative control flow constructs:

### If / Else
```cartan
if (my_variable == 42.0) {
    // Condition met
} else {
    // Condition not met
}
```

### While Loops
```cartan
var i = 0;
while (i < 10) {
    i = i + 1;
}
```

### For Loops
```cartan
for (var i = 0; i < 10; i = i + 1) {
    // Loop body
}
```

---

## 4. Functions & FFI

Functions are declared with `fn`, followed by parameters and the return type.

```cartan
fn add_numbers(a: f32, b: f32) -> f32 {
    return a + b;
}
```

### External C-FFI
Cartan can natively link against C functions using the `extern fn` keyword.

```cartan
extern fn printf(format: ptr) -> f32;
extern fn malloc(size: f32) -> ptr;
```

---

## 5. Tensors & Math

Tensors are first-class primitives. You can instantiate a tensor explicitly, and perform math operations.

```cartan
var t = tensor[512, 128] under fp16;
var result = t @ t; // Matrix multiplication
```

### Memory Spaces (Manifolds)
Cartan allows placing tensors in non-Euclidean spaces to override the default `@` algebraic operations:
```cartan
parameter[Adam] weights [16, 16] in Minkowski;
```

---

## 6. Advanced Allocations

Cartan provides specialized structures for AI workloads:
- `sequence`: Used for jagged data streams.
- `block`: Used for KV cache pagination.

```cartan
sequence CausalSeq [ 256 ];
block AgentBlock [ 16 ];
```

---

## 7. The Standard Library

The standard library is located in `src/std/`. Implementations use the `.cl` extension and public declarations use `.ch`.

### 7.1 Core & Infrastructure Modules
- `src/std/math.cl` / `src/std/constants.ch`: Standard math & physical constants.
- `src/std/string.cl` / `src/std/collections.cl`: High-performance strings, dynamic trees, vectors, and memory pools.
- `src/std/io.cl` / `src/std/fs.cl` / `src/std/net.cl` / `src/std/http.cl` / `src/std/xml.cl`: Systems I/O, networking, HTTP clients, and XML parsing.
- `src/std/env.cl`: Command-line environment argument parsing.

### 7.2 AI & Machine Learning Breakthrough Modules
- `src/std/evolution.cl` / `src/std/evolution.ch`: Master Evolutionary Suite unifying ES, WANNs, AZR, and M2N2.
- `src/std/es_opt.cl` / `src/std/es_opt.ch`: Mirrored Evolution Strategies (ES) Gaussian Noise Perturbation & Score Function Gradient Estimation ($\theta \pm \sigma \epsilon_i$).
- `src/std/elm.cl` / `src/std/elm.ch`: Extreme Learning Machines (ELM) & Closed-Form Zero-Shot Readout Solves ($W_{\text{head}}^* = (H^T H + \lambda I)^{-1} H^T Y$).
- `src/std/wann.cl` / `src/std/wann.ch`: Weight-Agnostic Neural Networks (WANNs) DAG topology evolution over shared scalar weights.
- `src/std/esn.cl` / `src/std/esn.ch`: Echo State Networks (ESNs) & Reservoir Computing ($\rho < 1.0$) with Ridge regression readouts.
- `src/std/dip.cl` / `src/std/dip.ch`: Deep Image Prior (DIP) spatial/structural priors for signal reconstruction & $E_8$ trajectory smoothing.
- `src/std/reasoning.cl` / `src/std/reasoning.ch`: Absolute Zero Reasoning (AZR) compiler self-play & binary execution rewards ($R \in \{0, 1\}$).
- `src/std/optim.cl` / `src/std/optim.ch`: Finsler-Randers Riemannian Natural Gradient Optimizers ($F(x,y) = \alpha + \beta \cdot y$).
- `src/std/resonator.cl` / `src/std/resonator.ch`: Continuous Hopfield Banach Contraction Resonators ($T(h) = \tanh(\beta W h + E)$).
- `src/std/fusion.cl` / `src/std/fusion.ch`: Sakana AI M2N2 niche crossover, KnOTS SVD task subspaces, SLERP, TIES, DARE.
- `src/std/distill.cl`: Teacher-Student KL Divergence Distillation.
- `src/std/hub.cl`: Native HuggingFace Hub Safetensors checkpoint loader & AutoTokenizer.
- `src/std/vision.cl`: Computer Vision, Bilinear Resize, RGB Tensors & Image Processing.


---

## 8. Advanced Control Flow & Reasoning Blocks

Cartan implements cognitive reasoning blocks directly at the language level, allowing developers to manage model skepticism, vectorization, and search.

### 8.1 Satisfy & Backtrack
Backtracking search loop that rewinds state until the satisfy condition evaluates to non-zero.
```cartan
satisfy (model_score > 0.95) {
    generate_next_token();
    if (dead_end) {
        backtrack; // Rewinds to the satisfy condition check
    }
} otherwise {
    adjust_temperature();
}
```

### 8.2 Parallel and Autovectorization blocks
- `vmap { ... }`: Auto-vectorizes loops and statements within the block.
- `lazy { ... }`: Defers tensor evaluation into a thunk.
- `multimodal { ... }`: Enforces synchronization of cross-attended modal stream buffers.

### 8.3 Cognitive State Blocks
- `doubt { ... }`: Skepticism pass, lowering precision thresholds to double-check boundaries.
- `chain { ... }`: Activates chain-of-thought density tracking.
- `route { ... }`: Enables sparse Mixture-of-Experts (MoE) routing.
- `grok { ... }`: Monitors gradient frequencies for phase transitions.
- `override { ... }`: Accesses secure prompt override registers.

---

## 9. Data-Oriented OOP (Traits & Implementations)

Traits and Implementations organize behavior across data structs.

```cartan
trait Updateable {
    fn step(w: &mut tensor, lr: f32);
}

struct ModelParam {
    var id = 0.0;
}

impl Updateable for ModelParam {
    fn step(w: &mut tensor, lr: f32) {
        w -= w.grad() * lr;
    }
}
```

---

## 10. Actor Concurrency Model

Natively spawn asynchronous actors that run in parallel threads and communicate via message queues.

```cartan
spawn Router {
    var routes = {"home": 1.0};
    
    receive dispatch(dest: string, data: tensor) {
        // Asynchronously process messages
        printf("Routing message to dest\n");
    }
}
```

---

## 11. Builtin Intrinsics & Operators

Cartan features a rich suite of built-in operators and compiler functions:

### 11.1 Model & Tensor Modifiers
- `@agent_accessible`: Exposes target variable to the LLM agent registry.
- `absorb_layer_weights(donor_file, target)`: Loads pretrained layers directly.
- `project_vocab(source, target)`: Projects embedding vocabulary.
- `import_onnx!("path/to/model.onnx")`: Zero-cost ONNX importing.
- `quantize(target, "int8")`: Compresses model weights.

### 11.2 String & SIMD Intrinsics
- `string_length(str)`: Returns length of string.
- `string_substring(str, start, len)`: Extracts slice.
- `string_concat(a, b)`: Concatenates strings.
- `simd_find_first(buffer, byte)`: Accelerates token search using SIMD registers.
- `simd_mask_alpha(buffer)`: SIMD mask check for alphabetical blocks.

---

## 12. Standard Libraries (`src/std/`)

Cartan provides standard library modules written in native CARTAN:

### 12.1 `std/tensor.car`
- `zeros(size)`: Allocates zeroed contiguous tensor memory.
- `ones(size)`: Allocates initialized tensor memory.
- `relu(tensor)`: In-place ReLU activation function.
- `add(a, b)` / `sub(a, b)` / `mul(a, b)`: Element-wise tensor operations.

### 12.2 `std/fs.car`
- `read_file_to_string(path)`: Reads text file into heap string.
- `write_string_to_file(path, content)`: Writes string to target path.
- `file_exists(path)`: Returns `1.0` if file exists, else `0.0`.

### 12.3 `std/semantics.car`
```cartan
include "src/std/semantics.car";

let path = "entity.physical_entity.object.organism.canine.dog";
let depth = semantics_dot_path_depth(path); // returns 6.0
let distance = semantics_lca_tree_distance(path, "entity.physical_entity.object.organism.canine.wolf");
```

---

## 12.4 Information Content & Tokenizer Scaling (`std/tokenizer`)

```cartan
include "src/std/tokenizer.car";

let scaled_loss = tokenizer_scale_ic_loss(1.5, 35.0); // scales cross-entropy loss by IC weight
```

### 12.5 `std/collections.car`
- `list_create()` / `list_push(l, item)` / `list_get(l, idx)` / `list_len(l)`: Dynamic heap-allocated tree lists.
- `map_create()` / `map_set(m, key, val)` / `map_get(m, key)`: $O(1)$ open-addressing hash dictionaries.

### 12.6 `std/math.car` & `std/io.car`
- `sin(x)`, `cos(x)`, `tan(x)`, `exp(x)`, `log(x)`, `sqrt(x)`, `pow(x, y)`: Scalar math wrappers.
- `println(text)` / `eprintln(text)`: Formatted stdout and stderr printing helpers.
