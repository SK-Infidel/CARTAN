# Cartan Language Specification (v1.0.0 Systems Architecture)

Cartan is a statically typed, self-hosting, natively tensor-first programming language designed for bare-metal AI development. This document serves as the official reference for the compiler syntax, strict generic constraints, memory ownership, and compiler architecture.

## 1. Compiler Architecture
Cartan compiles via a 100% self-hosted LLVM compiler toolchain (`cartanc` written in native CARTAN):
- **Self-Hosted Frontend (`src/cartanc/`)**: Lexer, Parser, Type Checker, and AST expansion passes written in native CARTAN (`ast.ch`, `lexer.car`, `parser.car`, `type_checker.car`).
- **Pure CARTAN Core Runtime (`src/cartanc/core_runtime.car`)**: Canonical runtime module auto-injected during compiler AST expansion. Provides memory-safe string manipulation, dynamic hierarchical trees (`tree<T>`), memory assertions, file I/O, and OS process execution directly in pure CARTAN.
- **Pure Freestanding Hardware Runtime (`gpu_runtime/` & Native LLVM IR Emitted Runtime)**: Pure freestanding runtime architecture with all primitive tree, string, memory, and formatting operations emitted directly as pure LLVM IR (`llvm_codegen.car`), zero linked C runtime source files, SWMR memory fences, DLPack zero-copy FFI interop, capabilities-based VRAM sandboxing, continuous Hopfield memory banks, and native WebGPU compute shaders.

## 2. Keywords
- `fn` : Function declaration
- `let`, `var`, `const` : Variable declarations
- `return` : Return statement
- `include` : Module evaluation and inclusion (`include "path"`)
- `tensor` : Primitive tensor type declaration
- `struct` : Data structure definition
- `async`, `yield`, `await` : Asynchronous coroutine execution primitives (`src/std/async.cl`)
- **Standard Library Ecosystem (`src/std/`)**: Native implementation files carry the `.cl` extension (CARTAN Library) while public declaration header files carry the `.ch` extension (CARTAN Header). Includes `async.cl`/`async.ch` (Pure CARTAN Coroutines), `security.cl`/`security.ch` (VRAM write-locks and SWMR fences), `evolution.cl`/`evolution.ch` (Master Evolutionary Suite: ES + WANN + AZR + M2N2), `es_opt.cl`/`es_opt.ch` (Mirrored Evolution Strategies), `elm.cl`/`elm.ch` (Extreme Learning Machines zero-shot readout solve), `wann.cl`/`wann.ch` (Weight-Agnostic Neural Networks), `esn.cl`/`esn.ch` (Reservoir Computing), `dip.cl`/`dip.ch` (Deep Image Prior), `reasoning.cl`/`reasoning.ch` (Absolute Zero Reasoning compiler self-play), `optim.cl`/`optim.ch` (Finsler-Randers Riemannian natural gradients), `resonator.cl`/`resonator.ch` (Continuous Hopfield energy basins), `fusion.cl`/`fusion.ch` (M2N2 niche crossover, KnOTS SVD, SLERP, TIES, DARE), `distill.cl` (KL distillation), `hub.cl` (HuggingFace Hub), `tokenizer.cl` (Dynamic Gutenberg BPE tokenizer), and `vision.cl` (Computer Vision).

- `backward(loss)` : Initiates static backward graph generation & autograd
- `in` : Geometric manifold space declaration
- `under` : Precision specifier assignment
- `static_assert!` : Compile-time invariant evaluation
- `comptime` : Compile-time expression evaluation
- `@agent_accessible` : Capabilities VRAM parameter write-lock annotation
- `if`, `else` : Conditional branching
- `while`, `for` : Iteration loops
- `break`, `continue` : Loop control
- `extern fn` : External C-FFI function declaration
- `try`, `catch`, `throw` : Isolated systems-level hardware fault boundaries
- `true`, `false` : Boolean primitives

## 3. Types
Cartan enforces strict memory mapping for all primitive types:
1. **Float (f32)**: Scalars (e.g. `5.0`). Note: All mathematical and integer evaluations map to a unified 32-bit floating point hardware representation to allow seamless backpropagation.
2. **Bool**: Boolean logic (`true`, `false`).
3. **String**: Immutable string literals (`"hello"`).
4. **Stream**: Asynchronous, non-blocking hardware data pipelines.
5. **Tensor**: N-dimensional contiguous arrays, compiled natively to the specified precision specifier (e.g., `fp16`, `bf16`, `int8`, `fp32`). Tensors inherently record operations for reverse-mode automatic differentiation.
6. **Ptr**: Raw hardware memory pointer, required for interoperability with external `extern fn` C libraries.

## 4. Tensor Architecture & Memory

### 4.1 Strict MemoryBus Mapping & Fluid Precision
Cartan enforces absolute zero-allocation runtime mutations. Tensors compile directly into raw memory addresses mapped across a physical `MemoryBus` partitioned into hardware boundaries. Precision is specified using the `under` keyword, allowing edge scaling from standard floats to integer quantization:
```cartan
var weights = tensor[512, 128] under fp16 @location("sram");
var activations = tensor[B, 512] under int8;
```

### 4.2 Tensor Ownership & Lifecycle Primitives
To prevent implicit heap fragmentation and Out-Of-Memory (OOM) faults on edge devices, Cartan places mutability modifiers explicitly on the type primitive:
- **Value Semantics**: `var t = tensor[2, 3];` Allocates a contiguous memory block on the `MemoryBus`. Passing `t` to a function shifts total ownership (a Move).
- **Immutable Borrow**: `&tensor` Passes a read-only hardware pointer (a raw integer memory address).
- **Mutable Borrow**: `&mut tensor` Passes a read-write hardware pointer, allowing zero-allocation, in-place mathematical mutations. 

### 4.3 Symbolic Shape Tracking & Strict Generic Constraints
AI models frequently use dynamic runtime dimensions (e.g. `batch_size`). To guarantee mathematically safe matrix computations without expensive runtime checks, Cartan employs **Strict Generic Constraints**.
```cartan
// The compiler mathematically proves this is safe algebraically at compile-time:
fn forward<B: int>(x: tensor[B, 512], w: tensor[512, 128]) -> tensor[B, 128] {
    return x @ w; 
}
```
If dimensions clash mathematically, the Self-Hosted CARTAN Semantic Type Checker (`src/cartanc/type_checker.car`) emits a precise `Diagnostic` and instantly halts the build (or highlights it in real-time via the integrated Language Server). 

### 4.4 Geometric Manifolds
A tensor exists within a specific mathematical space, which dictates how operations like `@` (geodesic inner product) behave.
```cartan
struct PoincaréDisk { const curvature = -1.0; }
var embedding = tensor[1, 512] in PoincaréDisk; 
```

## 5. Syntax Rules

### 5.1 Variable Declaration & Typing
Variables are declared using the `var` keyword.
```cartan
var count = 5; 
const MAX_EPOCHS = 100;
```

### 5.2 Arrays and Dictionaries
Arrays are initialized using `[]` and Dictionaries using `{}`. Array indexing assignment is supported for scalar hardware mutations.
```cartan
var arr = [1, 2.5, 3];
arr[0] = 5.0;
```

### 5.3 Operators and Logic
- **Arithmetic**: `+`, `-`, `*`, `/`
- **Compound Assignment**: `+=`, `-=`, `*=`, `/=`
- **Matrix Multiplication**: `@` (Context-aware based on the Tensor's geometric manifold).

### 5.4 Data Structures & Functions
Cartan uses `struct` to group variables and functions natively into an isolated memory scope.
```cartan
struct SGDOptimizer {
    var lr = 0.01;
    
    // Explicit Mutable Borrow: In-place weight updating
    // Notice the modifiers belong to the TYPE, preventing parsing ambiguities
    fn step(w: &mut tensor, grad: &tensor) {
        w -= grad * lr; // Explicitly mutates physical memory in-place
    }
}
```

### 5.5 Stateful Layers & Autograd
To distinguish between **Model Parameters** (persistent weights) and **Transient Activations** (ephemeral tensors freed during backward passes), Cartan provides `layer` and `module` blocks. These blocks explicitly inform the LLVM compilation layer about stateful lifecycle lifetimes.

Additionally, to track computational graphs for reverse-mode automatic differentiation without expensive runtime allocations, Cartan uses a zero-allocation gradient tape via the `autograd.track` primitive:
```cartan
// Explicitly generating a static autograd track
var loss = autograd.track {
    return forward(x, &w);
};
var grads = loss.backward(); // Applies g^-1 automatically based on manifold!
```

### 5.6 Fault Isolation (Try/Catch)
For robust edge-device processing, Cartan includes native `try`/`catch` blocks, allowing hardware-level faults or geometric bounds violations to be captured safely without crashing the microkernel.

### 5.7 Fused Loop Broadcasting & Vectorization Annotations
To support physical simulations with zero allocations, Cartan provides fused element-wise broadcasting operators and optimization annotations:
* **Broadcasting Operators (`.+=`, `.-=`, `.*=`, `./=`, `.@=`)**: Instead of creating temporary tensors/arrays, these perform operations element-wise in-place.
* **Vectorization Hints (`@simd`, `@inbounds`)**: Preceding a loop block, `@simd` instructs the LLVM compiler to vectorise loop lanes via loop metadata, and `@inbounds` flags the compiler to omit safety bounds checking for maximum bare-metal optimization.

## 6. Continuous Multi-Modal Streams
Rather than treating hardware inputs as blocking text files, Cartan uses `stream` for continuous read-to-learn cycles. A `stream` directly binds to a symbolic dimension in a function call, telling the Type Checker exactly where a dynamic variable originates.
```cartan
// Explicitly binding a streaming hardware channel to a symbolic evaluation dimension
fn runtime_entry(input_channel: stream) {
    var frame[B, 3, 224, 224] = stream.read_frame<B>(input_channel);
    var output = model.forward<B>(frame);
}
```

## 7. Native Compilation & Execution Pipeline

CARTAN compiles directly from source AST to native machine code via textual LLVM Intermediate Representation (`.ll`):
1. **AST Expansion Pass (`src/cartanc/main.car`)**: Recursively resolves all `include` statements and injects the pure CARTAN runtime kernel (`src/cartanc/core_runtime.car`).
2. **Semantic Verification (`src/cartanc/type_checker.car`)**: Validates tensor dimensions, method calls, and symbol scopes.
3. **AST Optimization Pass (`src/cartanc/optimizer.car`)**: Folds constant scalar arithmetic and simplifies control graphs.
4. **LLVM IR Code Generation (`src/cartanc/llvm_codegen.car`)**: Emits structured, type-checked LLVM IR (`.ll`) featuring automatic pointer-to-float conversions (`as_float`), scientific float stabilization (`1.0e-06`), and DWARF debugging metadata (`!dbg`).
5. **Native Linking & Vectorized Pass Pipeline (`tools/zig_wrapper.py`)**: Compiles `.ll` directly (with zero C source files linked) into standalone, zero-dependency native `.exe` executables.
6. **In-Memory JIT Engine (`cartan_jit_eval`)**: Compiles and executes code on-the-fly for `cartanc run <file.car>` and the interactive REPL.

*(Historical Note: The early `.aer` stack-based bytecode format served as an initial Phase 1 prototype and has been entirely superseded by direct native LLVM IR emission).*

## 8. Codegen Optimizations & Hardware Target Backends

To preserve zero-overhead execution and numerical precision, CARTAN incorporates specialized codegen passes:

### 8.1 Pointer-to-Float Impedance Conversion (`as_float`)
When dynamic data structures (`ptr:`, `string:`, `tree<T>`, `struct:`) are returned from functions or evaluated in floating-point operations, `llvm_codegen.car` automatically emits:
```llvm
%val_i64 = ptrtoint ptr %ptr to i64
%val_dbl = sitofp i64 %val_i64 to double
```
This eliminates LLVM type verification failures (`defined with type 'ptr' but expected 'double'`) while allowing seamless scalar manipulation of opaque pointers.

### 8.2 Strict Scientific Float Stabilization
LLVM IR syntax mandates an explicit decimal point in floating-point literals with exponents (e.g. `1.0e-06`). The LLVM IR emitter and native runtime formatters enforce decimal point inclusion on all `%g` float formatting, preventing parser rejections in mathematical operations.

### 8.3 Static Monomorphization & Direct GPU Target Backends (NVPTX / SPIR-V / WGSL)
1. **Static Generic Monomorphization**: Multiple method dispatch based on generic dimensions (e.g. `B: int`) or precision specifiers (`under fp16`) is resolved at compile time.
2. **Direct GPU Backends (WGSL / OpenCL)**: Functions marked with compute directives compile directly to native WebGPU compute shaders (`gpu_runtime/src/kernels.wgsl`) and OpenCL kernels, binding to persistent VRAM buffers with zero PCIe host-device latency.

## 9. Differential Geometry & Riemannian Math
Cartan rejects the concept of treating Non-Euclidean math as a software-level hack. The `@` operator natively reads the geometric manifold of the tensor and alters its mathematical contraction at the compiler level.

### 9.1 Minkowski Space (Lorentz Invariance)
In `Minkowski` manifolds, the `@` operator explicitly applies the signature metric tensor $g_{\mu\nu} = \text{diag}(-1, 1, 1, 1)$.

### 9.2 Poincaré Ball (Möbius Operations)
In the `PoincareDisk`, `@` translates matrix multiplication into exact Möbius operations mapping onto the Euclidean tangent space via logarithmic maps.

### 9.3 Riemannian Autograd
Because the space is warped, standard Euclidean gradients point in the wrong steepest-descent direction. When `backward()` is called on a Non-Euclidean tensor, Cartan automatically calculates the inverse metric tensor $g^{-1}$ for that manifold and applies it to the Euclidean gradients.

## 10. The Master Execution Architecture

Cartan's roadmap follows a strict progression, beginning with the foundations of static graph generation and memory mapping, scaling up to hardware tokenization, and ultimately culminating in an agentic operating system. 

```text
+-------------------------------------------------------------+
| 1. CORE COMPILATION & STATE (Phases 14 - 14c)               |
| Static graphs, liveness analysis, .aew zero-copy DMA        |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
| 2. MEMORY & GEOMETRIC EVOLUTION (Phases 15 - 16)            |
| SievingCache, Fluid Precision, Block Sparsity               |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
| 3. SILICON & INTERCONNECTS (Phases 17 - 19)                 |
| Hard-Lexing, SNNs/BrainChip, Diffeomorphic Bridges          |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
| 4. THE AGENTIC MICROKERNEL (Phase 20)                       |
| GraphFS, Capabilities Execution, Hot-Swap Re-compilation    |
+-------------------------------------------------------------+
```

### 10.1 Real-Time Tokenization Interconnect
Cartan `stream` types are designed to hook directly into silicon tokenizers (Finite State Automata) at the microkernel level. This guarantees that incoming raw data streams (e.g., audio, video) are tokenized asynchronously in-flight before crossing into a tensor memory allocation boundary.

### 10.2 Hot-Swap Compilation Safety
A core feature of the CartanOS is `Cartan.hot_swap()`, enabling the model to dynamically recompile its own routing architecture. To prevent an agent from fatally crashing its runtime loop, this capability heavily leverages Cartan's Fault Isolation (`try`/`catch`) boundaries. The microkernel must execute newly compiled graphs in an isolated memory sandbox before officially hot-swapping the active pointer in the Execution Registry.

## 11. Advanced Hardware & Model Primitives

### 11.1 Memory Manifestations & Fractal Attention (Sprint 15)
Cartan allows specifying exact memory bus hardware for allocation, as well as complex routing via `SievingCache` and `FractalAttentionBlock`:
```cartan
var lora = tensor[1024, 1024] @backend("NVMe"); // Maps directly to NVMe memory backing
var cache = SievingCache();
var block = FractalAttentionBlock();

@attention(routing="spotlight")
Cartan.Attention(target);
```

### 11.2 Dynamic Precision & Sparsity (Sprint 16)
Models can dynamically scale precision during execution using the `fluid` block and enforce hardware-level sparsity via the `with sparsity` block:
```cartan
under fluid(fp16, int8) {
    // Computations default to fp16, gracefully dropping to int8 under thermal pressure
}

with sparsity(8x8, 0.5) {
    // Forces hardware structural sparsity natively across the block
}

Cartan.prune_graph(0.01); // Prunes sub-threshold weights dynamically
```

### 11.2 Multi-Modal Streams & Tokenization (Sprint 17)
Streams map directly to hardware drivers, enabling real-time fusion of text, vision, and audio without runtime string parsing:
```cartan
var audio = stream[pcm_16khz]("microphone://0");
var video = stream[rgba, 60fps]("camera://0");
var text = stream[utf8]("network://socket");

var vocab = ElasticVocabulary(); // dynamically allocating vocab registry
var embedded = Cartan.lex_and_embed(text); // Hard-lexing FSA kernel mapping
```

### 11.3 Neuromorphic & SNN Support (Sprint 18)
Cartan natively supports event-driven spiking neural networks (e.g., BrainChip Akida):
```cartan
var s = spike;
var n = neuron;
emit spike(s); // Natively emits an asynchronous pulse on the crossbar
```

### 11.4 Cross-Model Subsumption (Sprint 19)
Disjoint pretrained models can be bridged geometrically at runtime without retraining:
```cartan
var aligned = Cartan.align_geodesics(model_a, model_b);
var bridge = Cartan.GeometricBridge(model_a, model_b);
var fused = Cartan.transpose_weights(model_a, model_b);
```

### 11.5 Agentic Operating System (CartanOS) (Sprint 20)
Cartan functions can be natively exposed to intelligent agent output spaces via `@agent_accessible`. Agents can query the mathematical AST vector of the entire codebase via `Cartan.reflect_repo()` and safely mutate their own execution architecture live using `Cartan.hot_swap(current, new)`.

## 12. Data-Oriented OOP (Traits & Implementations)

Cartan implements a lightweight, non-hierarchical, data-oriented object programming model. It separates raw data layouts (`struct` definitions) from behavior definitions (`trait` interfaces and `impl` blocks).

### 12.1 Interface Traits
Traits specify a set of method signatures that implementors must satisfy:
```cartan
trait Optimizer {
    fn step(w: &mut tensor, grad: &tensor);
}
```

### 12.2 Method Implementations
The `impl` block binds method definitions to a target struct structure. Cartan supports both direct methods and trait implementations:
```cartan
struct AdamOptimizer {
    var lr = 0.001;
    var beta1 = 0.9;
}

impl Optimizer for AdamOptimizer {
    fn step(w: &mut tensor, grad: &tensor) {
        // Implement Adam update step using struct fields
        w -= grad * lr; 
    }
}
```

---

## 13. Actor Concurrency Model

To support distributed systems and agentic multi-agent environments, Cartan provides a native Actor Concurrency model based on asynchronous message passing, bypassing global interpreter locks.

### 13.1 Spawning Actors
The `spawn` block instantiates a concurrent actor running in an isolated VM thread. Actors maintain their own private symbol tables and execution registers:
```cartan
spawn ModelAgent {
    // Local actor state
    var model_weights = tensor[512, 512];
    
    // Message handler loop
    receive predict(x: tensor[1, 512]) {
        var output = x @ model_weights;
        // Process prediction asynchronously
    }
}
```

### 13.2 Asynchronous Message Handling
Message handlers are defined using the `receive` keyword. Handlers match incoming message signatures, parsing parameters dynamically and executing safe local updates inside try-catch fault isolation boundaries.

