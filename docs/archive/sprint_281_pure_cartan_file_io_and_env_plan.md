# Sprint 281 Implementation Plan: Pure CARTAN File I/O (`read_file`, `copy_file`) and Environment Retrieval (`get_env`)

## Goals & Objectives
1. **Pure CARTAN `cartan_get_env` (`src/cartanc/main.car`, `src/std/env.cl`)**:
   - Replace external C call `cartan_get_env` with pure native CARTAN calling direct libc `getenv`:
     ```cartan
     extern fn getenv(name: string) -> string;
     fn cartan_get_env(key: string) -> string {
         if (key == 0.0) { return ""; }
         let val = getenv(key);
         if (val == 0.0) { return ""; }
         return val;
     }
     ```
2. **Pure CARTAN `cartan_copy_file` (`src/cartanc/main.car`)**:
   - Implement streaming binary file copier in `main.car` using libc primitives `fopen`, `malloc`, `fread`, `fwrite`, `free`, `fclose`.
3. **Pure CARTAN `cartan_read_file` (`src/cartanc/main.car`, `src/std/fs.cl`)**:
   - Implement native whole-file reader in `main.car` and `src/std/fs.cl` using `fopen`, `fseek`, `ftell`, `calloc`, `fread`, `fclose`.
4. **Mark legacy C runtime functions as `CARTAN_WEAK` (`src/cartanc/core_runtime.c`)**:
   - Annotate `c_cartan_read_file`, `cartan_copy_file`, and `cartan_get_env` as `CARTAN_WEAK` in `core_runtime.c`.
5. **Self-Hosting Parity Verification**:
   - Rebuild Stage 2 and Stage 3 compilers.
   - Verify 100% bit-for-bit SHA-256 fixed-point parity (`cartanc_stage2.ll` == `cartanc_stage3.ll`).
6. **Empirical Regression Verification**:
   - Execute all 47 compiler snapshot tests in [`test/compiler_suite/run_tests.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/compiler_suite/run_tests.car).
   - Update `CHANGELOG.md` and archive sprint retrospective.
