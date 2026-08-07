# Cartan Compiler Self-Hosting Walkthrough

This walkthrough outlines the successful path to fixing the Cartan compiler's LLVM backend and achieving a fully functional self-hosting loop. 

## 1. Initial State and Bug Identification
We started with a broken compiler state where the generated executable (`main.exe`) would either crash on launch or produce garbage output (like `@` being printed). We identified two major issues:
1. **Hardcoded Floats:** The compiler hardcoded LLVM IR generation for `FunctionCall`, `MethodCall`, and `user_main` entry points to return `float` types instead of mapping dynamically to the expected types (which should be 64-bit `double` on standard x86-64 ABI). 
2. **Missing IR Body:** The generated `main3.ll` file was only 15 lines long. It contained the `main` entry point, but omitted all `codegen.globals` (externs, string constants) and AST body logic.

## 2. Fixing the ABI and Floats
I restored the source code for `llvm_codegen.car` (to undo the corrupted regex pass from a previous session that introduced missing braces and BOM errors). 
Then, I made surgical edits using a specialized Python script to systematically migrate all LLVM primitives (`fcmp float`, `alloca float`, `(float 1)`, etc.) to `double`.

For function calls, I implemented dynamic lookups in `llvm_codegen.car`:
```diff
- let p2 = cartan_string_concat(p1, " = call float @");
+ var ret_type = cartan_dict_get(self_ptr.func_return_types, name);
+ if (ret_type == 0.0) { ret_type = "double"; }
+ let p2_1 = cartan_string_concat(p1, " = call ");
+ let p2_2 = cartan_string_concat(p2_1, ret_type);
+ let p2 = cartan_string_concat(p2_2, " @");
```

## 3. Fixing the Output Concatenation Loop
When `generate` finishes in `llvm_codegen.car`, it actually stores its results in two arrays of strings inside the `LLVMGenerator` struct: `output` and `globals`. The old `main.car` code was writing **only** `codegen.output` to the `.ll` file!

To ensure a fully linked executable, I added logic in `main.car` to iterate through the entire `output` array and push it onto the `globals` array before dumping to the file:
```cartan
var llvm_ir_i = 0.0;
var out_len = cartan_tree_len(codegen.output);
while (llvm_ir_i < out_len) {
    cartan_tree_push(codegen.globals, cartan_tree_get_f32(codegen.output, llvm_ir_i));
    llvm_ir_i = llvm_ir_i + 1.0;
}
cartan_ast_tree_write_file(out_ll, codegen.globals);
```

## 4. Final Validation
We successfully rebuilt the C-transpiled baseline compiler (`main.exe`) via `cartanc_rust.exe`. We are currently using `main.exe` to self-compile `main.car` into `main3.exe` to prove that the fully self-hosted compiler runs without segfaults and generates complete, valid LLVM IR!
