# Sprint 460 Plan: AST Arity Harmonization, Trait/Impl Type Checking & Method Lowering

## Sprint Objective
Resolve AST arity and signature mismatches across 7 statement variants (`[ISSUE-249]`), normalize dual discriminants and fix `ImplDecl` target struct scope resolution in `type_checker.car` (`[ISSUE-250]`), and implement LLVM IR lowering for `ImplDecl` methods in `llvm_codegen.car` (`[ISSUE-251]`). Empirically verify with Target 70 and full 70-target regression testing.

---

## Technical Specifications

### Phase 1: AST Signature Harmonization (`[ISSUE-249]`, `src/cartanc/ast.ch:enum Stmt`)
Align the 7 mismatched statement variants in `ast.ch:enum Stmt` to match their respective `parser.car` AST constructions:
1. `LayerDecl`: `LayerDecl(string, string, ptr, string)`
2. `StreamDecl`: `StreamDecl(ptr, string)`
3. `TopologyDecl`: `TopologyDecl(string, ptr)`
4. `MeshBlock`: `MeshBlock(string, string, ptr)`
5. `TreeDecl`: `TreeDecl(string, string)`
6. `FluidPrecisionBlock`: `FluidPrecisionBlock(string, string, ptr)`
7. `SparsityBlock`: `SparsityBlock(ptr, ptr, ptr)`

### Phase 2: Type Checker Discriminant Normalization & Scope Fix (`[ISSUE-250]`, `src/cartanc/type_checker.car`)
1. In `type_checker.car:tc_visit_stmt`:
   - Support dual discriminants for `ImplDecl`: `disc == 34.0 || disc == 157.0`.
   - Correct target struct lookup:
     ```cartan
     let target_name = cartan_tree_get_f32(stmt, 2.0); // Index 2.0 is target_name
     ```
   - Support dual discriminants for `TraitDecl`: `disc == 33.0 || disc == 156.0`.

### Phase 3: LLVM IR Codegen Lowering for `ImplDecl` (`[ISSUE-251]`, `src/cartanc/llvm_codegen.car`)
1. In `llvm_visit_stmt`:
   ```cartan
   if (disc == 34.0 || disc == 157.0) { // ImplDecl
       let trait_name = cartan_tree_get_f32(stmt, 1.0);
       let target_name = cartan_tree_get_f32(stmt, 2.0);
       let methods = cartan_tree_get_f32(stmt, 3.0);
       cartan_tree_push(self_ptr.output, cartan_string_concat(cartan_string_concat("  ; --- Begin Impl: ", target_name), " ---\n"));
       if (methods != 0.0) {
           var idx_m = 0.0;
           let num_m = cartan_tree_len_f(methods);
           while (idx_m < num_m) {
               var m_func = cartan_tree_get_f32(methods, idx_m);
               idx_m = idx_m + 1.0;
               llvm_visit_stmt(self_ptr, m_func);
           }
       }
       cartan_tree_push(self_ptr.output, cartan_string_concat(cartan_string_concat("  ; --- End Impl: ", target_name), " ---\n"));
   }
   ```
2. In `MethodCall` lowering:
   Ensure member methods defined on structs can be called and dispatched with the receiver pointer passed as first argument.

### Phase 4: Target 70 Regression Suite & Release
1. Rebuild self-hosted `cartanc.exe`.
2. Author Target 70 regression test: `test/compiler_suite/test_impl_trait_methods.car` validating `impl` block methods, struct method calls with `self`, authentic mathematical transformations, and zero mocking.
3. Whitelist Target 70 in `.gitignore` and register in `test/compiler_suite/run_tests.car`.
4. Rebuild `build/run_tests.exe` and verify all 70 targets pass with 0 failures.
5. Update `ISSUES.md`, `CHANGELOG.md` (`[8.418.0]`), `docs/ROADMAP.md`, task list, and archive walkthrough.
