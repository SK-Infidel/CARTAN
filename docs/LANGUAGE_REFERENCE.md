# Cartan Language Reference

This document serves as the canonical reference for Cartan's syntax, types, and compiler features.

---

## 1. Primitives

Cartan operates natively on a few carefully constructed primitive types:

- `float`: Unified scalar numeric value (compiled to 64-bit IEEE-754 double in LLVM codegen for numerical stability in autograd and differential geometry; 32-bit/16-bit inside tensor buffers).
- `bool`: Boolean logic (`true`, `false`).
- `ptr`: A raw memory pointer (used for C-ABI interoperability and low-level buffers).
- `void`: Empty return type for statements and functions.
- `string`: Immutable string literals (`"hello"`).
- `tree<T>`: Hierarchical dynamic tree structure (`cartan_tree_create`, `cartan_tree_push`, `cartan_tree_get`, etc.).
- `tensor`: N-dimensional contiguous arrays, compiled natively to targeted precision.
- `stream`: Asynchronous, non-blocking hardware data pipelines.
- `vector[N]`: Standard Euclidean ambient or intrinsic tangent vector.
  - **Syntax**: `vector[N] at anchor_tensor` (Tangent vector anchored at target manifold coordinates).
- `lattice[L]`: An algebraic lattice (e.g. `lattice[E8] l`).
- `dataframe`: A typed database-like table structure.

---

## 2. Variables & Constants

Variables are declared with `let` (scoped/immutable assignment) or `var` (mutable assignment). Constants are declared with `const`.

```cartan
let message = "Hello CARTAN";
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
var i = 0.0;
while (i < 10.0) {
    i = i + 1.0;
}
```

### For Loops
```cartan
for (var i = 0.0; i < 10.0; i = i + 1.0) {
    // Loop body
}
```

---

## 4. Functions & FFI

Functions are declared with `fn`, followed by parameters and the return type.

```cartan
fn add_numbers(a: float, b: float) -> float {
    return a + b;
}
```

### External C-FFI
Cartan can natively link against C functions using the `extern fn` keyword.

```cartan
extern fn printf(format: string) -> i32;
extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);
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
- `src/cartanc/core_runtime.car`: Pure CARTAN Core Runtime kernel auto-injected during compiler AST expansion for zero-dependency portability.
- `src/std/math.cl` / `src/std/constants.ch`: Standard math & physical constants.
- `src/std/string.cl` / `src/std/collections.cl`: High-performance strings, dynamic trees, vectors, slices, and memory pools.
- `src/std/async.cl` / `src/std/async.ch`: Native asynchronous coroutines (`cartan_async_spawn`, `cartan_async_yield`, `cartan_async_await`).
- `src/std/security.cl` / `src/std/security.ch`: Capabilities-based VRAM parameter write-locking and SWMR thread-safe memory fences.
- `src/std/io.cl` / `src/std/fs.cl` / `src/std/net.cl` / `src/std/http.cl` / `src/std/xml.cl`: Systems I/O, file streaming, networking, HTTP clients, and XML parsing.
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

Cartan provides standard library modules written in native CARTAN (`.cl` implementation, `.ch` header):

### 12.1 `src/std/tensor.cl`
- `cartan_tensor_alloc(rows, cols)`: Allocates contiguous tensor memory on the memory bus.
- `cartan_tensor_add(a, b)` / `cartan_tensor_sub(a, b)`: Element-wise tensor operations.
- `cartan_tensor_mul(a, b)` / `cartan_tensor_div(a, b)`: Element-wise arithmetic.
- `cartan_tensor_to_dlpack(t)` / `cartan_tensor_from_dlpack(ptr)`: Zero-copy DLPack FFI tensor bridges.

### 12.2 `src/std/fs.cl`
- `cartan_read_file(path)`: Reads full file content into string.
- `cartan_write_file(path, content)`: Writes text string directly to file.
- `cartan_file_exists(path)`: Returns `1.0` if file exists, else `0.0`.
- `cartan_copy_file(src, dst)`: Copies file from source path to destination path.
- `cartan_export_c_headers(src, dst)`: Generates and writes C header files from symbol definitions.

### 12.3 `src/std/semantics.cl`
```cartan
include "src/std/semantics.cl";

let path = "entity.physical_entity.object.organism.canine.dog";
let depth = semantics_dot_path_depth(path); // returns 6.0
let distance = semantics_lca_tree_distance(path, "entity.physical_entity.object.organism.canine.wolf");
```

---

## 12.4 Information Content & Tokenizer Scaling (`src/std/tokenizer.cl`)

```cartan
include "src/std/tokenizer.cl";

let scaled_loss = tokenizer_scale_ic_loss(1.5, 35.0); // scales cross-entropy loss by IC weight
```

### 12.5 `src/std/collections.cl`
- `cartan_tree_create()`: Instantiates dynamic heap tree container.
- `cartan_tree_push(t, item)` / `cartan_tree_push_f32(t, val)`: Appends element to tree.
- `cartan_tree_get_f32(t, idx)` / `cartan_tree_get(t, idx)`: Retrieves element at index.
- `cartan_tree_len_f(t)` / `cartan_tree_len(t)`: Returns total element count.
- `cartan_slice_tree(t, start, end)`: Extracts sub-tree slice.
- `cartan_slice_nd(t, dims, indices)`: Performs N-dimensional multidimensional slicing.

### 12.6 `src/std/async.cl`
- `cartan_async_spawn(fn_ptr, arg)`: Spawns cooperative coroutine.
- `cartan_async_yield(task_id)`: Yields active execution slice back to scheduler.
- `cartan_async_await(task_id)`: Awaits coroutine completion and returns final result.

### 12.7 `src/std/security.cl`
- `cartan_rt_vram_lock_parameters(arena, bytes)`: Sets write-lock on model weights in VRAM.
- `cartan_rt_vram_unlock_parameters(arena)`: Unlocks model weight arena.
- `cartan_rt_check_vram_access(addr, bytes)`: Verifies capability bounds before access.
- `cartan_rt_lock_swmr()` / `cartan_rt_unlock_swmr()`: Single-Writer Multi-Reader synchronization fences.

### 12.8 `src/std/math.cl` & `src/std/io.cl`
- `sin(x)`, `cos(x)`, `tan(x)`, `exp(x)`, `log(x)`, `sqrt(x)`, `pow(x, y)`: Standard scalar math intrinsics.
- `printf(format, ...)`: Formatted console output via libc ABI.
- `cartan_read_line()`: Reads single line from standard input.
- `cartan_flush(handle)`: Flushes standard I/O buffer.

---

## 13. Compiler CLI Toolchain (`cartanc.exe`)

The self-hosted compiler provides native subcommands:

- `cartanc build <file.car> -o <out.exe>`: Compiles CARTAN source to optimized LLVM IR (`.ll`) and links to native executable via Zig.
- `cartanc run <file.car>`: Compiles and runs the program in-memory via Just-In-Time (JIT) execution.
- `cartanc repl`: Launches interactive REPL prompt for live expression evaluation.
- `cartanc pkg`: Generates package manifests (`cartan.toml`) and dependency lockfiles (`cartan.lock`).
- `cartanc bindgen <file.car>`: Automatically exports C/C++ FFI header files (`.h`) from SymbolTable definitions.
- `cartanc lsp`: Runs JSON-RPC 2.0 Language Server for IDE editor integration.
- `cartanc doc <file.car>`: Emits Markdown API documentation directly from docstrings and symbols.
