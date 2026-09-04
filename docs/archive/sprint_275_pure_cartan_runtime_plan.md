# Sprint 275 Plan: Migrating Core Runtime Primitives to Pure CARTAN

## Objectives
1. **Port File I/O Primitives (`src/std/fs.cl`)**:
   - Implement pure CARTAN `cartan_read_file(path: string) -> string` using libc `fopen`, `fseek`, `ftell`, `malloc`, `fread`, `fclose`.
   - Implement pure CARTAN `cartan_tree_write_file(path: string, tree: ptr)` to stream lines to disk directly.
2. **Port String Manipulation Primitives (`src/std/string.cl`)**:
   - Refactor `cartan_string_length`, `cartan_string_eq`, `cartan_string_starts_with`, `cartan_string_contains`, `cartan_string_substring` to pure CARTAN and libc intrinsics.
3. **Port Dynamic Vector & Tree Primitives (`src/std/collections.cl`)**:
   - Implement `cartan_tree_create`, `cartan_tree_push`, `cartan_tree_get_f32`, `cartan_tree_len_f`, `cartan_tree_set`, `cartan_tree_remove` in pure CARTAN.
4. **Validation & Fixed-Point Verification**:
   - Compile test programs and verify that pure CARTAN implementations emit valid LLVM IR and execute with 0 errors.
   - Re-verify bit-for-bit Stage 2 -> Stage 3 SHA-256 fixed-point parity.
   - Execute all 47 compiler snapshot tests.
