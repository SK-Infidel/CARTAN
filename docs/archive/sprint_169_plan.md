# Sprint 169 Plan: Zero-Mock Hardening & Debt Elimination

## Goals
1. **CLI Subcommand Implementation (`[ISSUE-010]`)**: Replace stubs in `src/cartanc/main.car` (`pkg`, `repl`, `lsp`) with genuine interactive state loops, manifest/lockfile generation, and stdio JSON-RPC processing.
2. **AST Optimizer Pass Linkage**: Link `src/cartanc/optimizer.car` into `main.car` so AST constant folding & identity reduction runs before LLVM IR generation.
3. **Test Harness Hardening (`test/compiler_suite/run_tests.car`)**: Assert return exit codes for all test builds/executions, run compiled binaries to evaluate `cartan_assert`, and route all test outputs into `build/`.
4. **Environment-Agnostic Path Resolution**: Normalize hardcoded user paths in `main.car` and `tools/build_toolchain.car` using `cartan_get_env("USERPROFILE")`.
5. **Purge Legacy Mock Artifacts & Clutter**: Remove legacy mock files (`test/mock_pass.car`, `test/train.car`) and root duplicate `.car`/`.cl` files. Update `ISSUES.md` and `CHANGELOG.md`.

## Execution Steps
- [x] Pre-sprint audit & Scrum alignment
- [ ] Upgrade `src/cartanc/main.car` (`pkg`, `repl`, `lsp`, `optimizer.car`, dynamic paths)
- [ ] Hardened `test/compiler_suite/run_tests.car` and `tools/build_toolchain.car`
- [ ] Delete mock files and root file clutter
- [ ] Rebuild compiler and execute full regression test suite
- [ ] Update `ISSUES.md` and `CHANGELOG.md`
