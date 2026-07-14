# Cartan Language Reference

This document serves as the canonical reference for Cartan's syntax, types, and compiler features.

## 1. Primitives

Cartan operates natively on a few carefully constructed primitive types:

- `f32` / `float`: 32-bit floating point number. (All standard math resolves to this).
- `i32` / `int`: 32-bit integer.
- `bool`: Boolean logic (`true`, `false`).
- `ptr`: A raw memory pointer (often used for C-FFI interfacing).
- `string`: Immutable string literals (`"hello"`).
- `tensor`: N-dimensional contiguous arrays, compiled natively.
- `stream`: Asynchronous, non-blocking hardware data pipelines.

## 2. Variables & Constants

Variables are declared with `var`. Constants are declared with `const`.

```cartan
var my_variable = 42.0;
const PI = 3.14159;
```

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

## 6. Advanced Allocations

Cartan provides specialized structures for AI workloads:
- `sequence`: Used for jagged data streams.
- `block`: Used for KV cache pagination.

```cartan
sequence CausalSeq [ 256 ];
block AgentBlock [ 16 ];
```

## 7. The Standard Library

The standard library is located in the `std/` directory.

- `std/env.ctn`: Exposes environment arguments (`cartan_has_arg`, `cartan_get_arg_int`, etc.).
- `std/io.ctn`: Exposes the `ConsoleStream` for I/O interactions.
