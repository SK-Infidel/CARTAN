# Cartan Language Specification (v0.3.0 Systems Architecture)

Cartan is a statically typed, natively tensor-first programming language designed for bare-metal AI development. This document serves as the official reference for the compiler syntax, strict generic constraints, memory ownership, and our tiered compilation architecture.

## 1. The Tiered Architecture
Cartan compiles via a multi-language systems pipeline:
- **Tier 1 (Rust Frontend & LSP):** Parses source code into a strongly-typed AST, verifies symbolic geometric constraints (Semantic Type Checker), provides real-time Language Server Protocol (LSP) diagnostics, and emits tightly packed binary bytecode or Native LLVM IR.
- **Tier 2 (Zig Runtime VM):** A microkernel environment that reads `.aer` binary files and directly maps instructions to physical hardware buffers using zero-copy allocation. Perfect for rapid prototyping and interpreted execution.
- **Tier 3 (LLVM Native Backend):** Raw native compilation. Cartan natively emits textual `.ll` (LLVM IR) without external dependencies, allowing code to be compiled directly to ARM/RISC-V/x86 instruction sets via standard LLVM tools (like `clang`).

## 2. Keywords
- `fn` : Function declaration
- `var` : Variable declaration
- `const` : Constant, immutable variable declaration
- `return` : Return statement
- `tensor` : Primitive tensor type declaration
- `struct` : Data structure definition
- `layer`, `module` : Stateful lifecycle block abstractions
- `autograd.track` : Initiates static backward graph generation
- `import` : Module evaluation and inclusion
- `in` : Geometric manifold space declaration
- `under` : Precision specifier assignment
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
If dimensions clash mathematically, the Rust Semantic Type Checker emits a precise `Diagnostic` and instantly halts the build (or highlights it in real-time via the integrated Language Server). 

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

## 6. Continuous Multi-Modal Streams
Rather than treating hardware inputs as blocking text files, Cartan uses `stream` for continuous read-to-learn cycles. A `stream` directly binds to a symbolic dimension in a function call, telling the Type Checker exactly where a dynamic variable originates.
```cartan
// Explicitly binding a streaming hardware channel to a symbolic evaluation dimension
fn runtime_entry(input_channel: stream) {
    var frame[B, 3, 224, 224] = stream.read_frame<B>(input_channel);
    var output = model.forward<B>(frame);
}
```

## 7. The Tier 2 `.aer` Executable Format
When source code compiles in `.aer` mode, it produces an Cartan Executable binary. This serves as the foundational microkernel executable for CartanOS.
The packed format features:
- **Magic Number**: `AER0`
- **Metadata Header**: Version (32-bit), Instruction Count (32-bit), Allocation Count (32-bit).
- **Instruction Stream**: Packed Opcodes (e.g., `0x10` for `AllocTensor`, `0x11` for `PushTensor`, `0x12` for `StoreElement`, `0x20` for `MatMul`) followed by their raw integer parameters.

### 7.1 Virtual Machine Execution Model
The Tier 2 Zig Runtime interprets the `.aer` file using a stack-based microkernel architecture:
1. **MemoryBus Bump Allocator**: During `AllocTensor`, the VM calculates `total_elements = width * height` and allocates a contiguous raw `[]f32` slice directly from simulated hardware pools (SRAM, HBM, DRAM).
2. **Tensor Registry**: The VM tracks tensors by ID using an internal hash map, linking the opaque IDs in the `.aer` bytecode to their physical memory offsets, shapes, and ranks.
3. **Execution Stack**: The compiler emits `PushTensor(ID)` to push operands onto an execution stack.
4. **Mathematical Execution**: Operations like `MatMul (0x20)` pop operand IDs from the stack, fetch their physical matrices from the Tensor Registry, perform the raw mathematical loops, and push the newly allocated Result ID back to the stack.

### 7.2 The Autograd Register Plane
The Tier 2 VM maintains a fixed-size, stack-allocated Autograd Tape Arena. When a tensor in a non-Euclidean manifold executes an operation, the VM stores a compact 16-byte record tracking the input IDs, output ID, and a pointer to the manifold's inverse metric function, ensuring OOM-free reverse-mode updates without dynamic memory tracking.

## 8. The Tier 3 LLVM Native Backend
Cartan can bypass the Tier 2 VM entirely by running `cartanc build-llvm`. This command natively generates zero-dependency LLVM Intermediate Representation (`.ll`) files.
This Tier 3 pipeline enables variables and tensors to be directly compiled into natively allocated memory addresses via `alloca`, enabling high-performance optimizations using standard toolchains (e.g., `clang output.ll -O3`).

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

