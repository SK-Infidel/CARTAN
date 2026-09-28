# Sprint 446 Task List

- [x] **Task 1**: Update `geomind_inverse_randers_backward_project` in `src/std/geom.cl` and `test/geomind/geom.cl` with dynamic submanifold strides (using CARTAN `if / else if` syntax).
- [x] **Task 2**: Implement `geomind_inverse_randers_transform_grad` with Sherman-Morrison dual vector reduction, background drift shift $-0.10 (\mathbf{b} \odot \mathbf{metric})$, destination vector length safeguard, and AGC clipping in `src/std/geom.cl` and `test/geomind/geom.cl`.
- [x] **Task 3**: Eliminate synthetic sine drift (`0.05 * sin(...)`) in `test/geomind/train.cl` (host initialization and CPU fallback path); replace with genuine bounded Cartan drift ($\|\mathbf{b}\|_g \le 0.50 < 1.0$) and dynamic stride `floor(c / stride)`.
- [x] **Task 4**: Parametrize WebGPU WGSL shaders in `test/geomind/train.cl` with dynamic dimension $D$, stride $S = D / 8$, and exact attention scale `sqrt(f32(S))`.
- [x] **Task 5**: Author dedicated unit test `test/compiler_suite/test_finsler_randers.car` (Target 65) covering dynamic strides, Sherman-Morrison collinear/orthogonal/zero-drift properties, and AGC bounds; register in `test/compiler_suite/run_tests.car`.
- [x] **Task 6**: Verify compilation and empirically execute individual binaries: `test_finsler_randers.exe` (G1), `test_lie_streams.exe` (G3), `test_hybrid_resonant_transformer.exe` (G3), `run_tests.exe` (G4), `geomind.exe --eval-analogy` (G5), and `geomind.exe --sleep` (G6).
- [x] **Task 7**: Update `CHANGELOG.md`, `ISSUES.md`, and `docs/ROADMAP.md`.
