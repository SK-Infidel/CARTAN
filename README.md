# Cartan Language

![Cartan Logo](https://via.placeholder.com/150?text=Cartan)

**Cartan** is a statically typed, natively tensor-first programming language designed from the ground up for bare-metal AI development.

By bringing Riemannian geometry, automatic differentiation, and zero-copy memory allocation directly into the language syntax and compiler, Cartan eliminates the overhead of Python abstractions, massive C++ frameworks, and unpredictable heap allocations.

## Key Features

- **Natively Tensor-First**: Tensors are primitive types in Cartan (e.g., `tensor[512, 128] under fp16`). They compile directly into raw memory addresses mapped across physical memory buses.
- **Shape-Safe Compile Time Verification**: Matrix multiplication shapes ($N \times K \cdot K \times M$) are mathematically proven at compile-time. Shape mismatch crashes are caught during compilation, not hours into training.
- **Riemannian Geometry Types**: Tensors can inhabit specific topological spaces (`in Minkowski`, `in PoincareDisk`). The compiler automatically overrides algebraic operators (like `@`) and applies the inverse metric tensor $g^{-1}$ during reverse-mode autograd to warp gradients back into curved spaces.
- **Zero-Copy Memory**: Cartan enforces absolute zero-allocation runtime mutations. Data paths flow seamlessly from disk/network directly to the GPU/NPU memory controller.
- **Native LLVM Backend**: Cartan emits textual `.ll` (LLVM IR) without external dependencies, allowing your AI models to be compiled directly into standalone `.exe` binaries or linked via standard LLVM tools.

## The Architecture

Cartan compiles via a highly specialized systems pipeline:
1. **Frontend (`cartanc`)**: A Rust-based compiler that parses Cartan source (`.ctn`), verifies symbolic geometric constraints, calculates static tensor memory offsets (Liveness Analysis), and emits optimized LLVM IR (`.ll`).
2. **Standard Library (`aether`)**: Pre-built AI workflows and primitives such as `run_causal_pretrain`, `run_sft_train`, and `run_generate`.
3. **Hardware Runtime**: A fast C/Rust-based `tensor_runtime` that implements memory allocation, C-FFI interconnects, and reverse-mode automatic differentiation.

## Quick Start

### 1. Build the Compiler
Ensure you have Rust and Cargo installed, as well as a C compiler (or Zig, which is included in the recommended setup).

```bash
cd compiler
cargo build --release
```

### 2. Compile an AI Workflow
You can compile Cartan `.ctn` files into standalone executables. The entry point of the AI operating system is `aether/geomind.ctn`.

```bash
cartanc build-exe aether/geomind.ctn
```

This will produce a fast, standalone native binary `release/geomind.exe`.

### 3. Run GeoMind
GeoMind acts as the universal entry point for training and interacting with neural networks in Cartan.

```bash
./release/geomind.exe --help

# Options:
#   --train-causal   Run causal language model pretraining
#   --train-sft      Run supervised fine tuning
#   --chat           Start interactive chat session
#   --generate       Generate text from a prompt
#   --debug          Show internal states and tokens
```

Example: Train a causal model with debug output:
```bash
./release/geomind.exe --train-causal --debug
```

## Language Overview
A quick look at the Cartan syntax:

```cartan
import "std/io.ctn"

// Standard main entry point
fn main() -> f32 {
    var console = ConsoleStream();
    
    // Primitive hardware tensors
    parameter[Adam] weights [16, 16] in Minkowski;
    
    // Statically sized sequences and blocks
    sequence CausalSeq [ 256 ];
    block AgentBlock [ 16 ];
    
    console.print("Initialized Cartan AI model.\n");
    return 0;
}
```

## Documentation
Check out the `docs/` directory for full specifications:
- [Language Reference](docs/LANGUAGE_REFERENCE.md)
- [Language Specification](docs/spec.md)
- [Roadmap](docs/ROADMAP.md)

## License
MIT License
