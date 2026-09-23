# Sprint 386 Plan: Mathematical Stabilization of Non-Euclidean Cortical Dynamics & Gradient Chain

## 1. Problem & Root Cause Analysis
A rigorous code review identified 6 non-Euclidean mathematical instability mechanisms in the forward and backward paths:
1. **Stream 4 (F4 x G2 Homology) Cubic Explosion**: Forward autoregression applies $0.10 v^3$ without saturation ($g_i = 5.0$). For $v > 2$, activations explode super-exponentially ($v \to 109 \to 818$).
2. **Stream 5 (SO(10) x SU(4) Eikonal) Positive Feedback Instability**: Forward autoregression applies $1.265 |v| + 0.2 v$, giving an eigenvalue $\lambda = 1.465 > 1$ that expands positive activations by $1980\times$ across 20 steps.
3. **Stream 2 (E6 x SU(3) Spectral) Negative Sign Flipping**: Multiplier $(harmonic + 0.5) \in [-0.207, 1.207]$ inverts coordinate signs and amplifies magnitudes.
4. **Cascading Manifold Collapse via Anisotropic RMSNorm**: Runaway activations in Streams 4 and 5 inflate Riemannian RMS, causing the other 6 streams (1920 features) to be crushed to near zero.
5. **Vocabulary Column Metric Misapplication**: Finsler drift and Dynkin weights ($0 \dots 2559$) were mistakenly applied across vocabulary token IDs rather than hidden features.
6. **Derivative & Feedback Mismatches**: Forward transformations expanded by $1.465\times$ and $v^3$ while backward passes used constant linear contractions, with Stream 4 backward gradients attenuated by $80\%$.

## 2. Planned Changes
1. **`test/geomind/streams.cl`**:
   - Stream 2: Bounded positive frequency modulation $\cos(\dots) \times 0.25 + 0.75 \in [0.50, 1.00]$.
   - Stream 4: Bounded hyperbolic saturation $\tanh(v^3 \times 0.02 \times kw) \times 0.25$, guaranteeing Banach contractive stability.
   - Stream 5: Sign-preserving contractive Eikonal geodesic travel: $0.70 v + 0.25 \tanh(\sqrt{v^2 kw + 0.01}) \text{sgn}(v)$ with contraction factor $< 1.0$.
2. **`test/geomind/train.cl`**:
   - `webgpu_get_lie_streams_shader` & `geomind_autoregressive_step`: Update Streams 2, 4, 5 to contractive, bounded formulations matching `streams.cl`.
   - `geomind_sgd_backward` & `geomind_backward_head_gemv`: Remove vocabulary column drift corruption. Use canonical cross-entropy delta on vocabulary simplex $\Delta^{V-1}$. Normalize inverse metric scaling in backward head GEMV: $inv\_g = 2.625 / g_r$ to prevent 80% gradient starvation of Stream 4.
   - `geomind_rmsnorm` & `geomind_rmsnorm_backward`: Normalize Riemannian metric sum by mean metric factor $\bar{g} = 2.625$, preserving unit variance.
   - CPU fallback `cartan_tensor_train_step`: Eliminate persistent non-zero drift subtraction on $d=0$.
   - Control loop: Recalibrate static gap threshold from $0.03 \to 0.38\text{ nats}$ ($\Delta PPL > 45$) and tie temperature/braking to active validation loss velocity ($\Delta AVL > 0.002$).

## 3. Verification Protocol
1. Clean compilation via `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe`.
2. Binary synchronization and bit-for-bit SHA-256 match across all 3 targets.
3. 4/4 semantic vector analogies verified cleanly at Rank 1.
4. Update `CHANGELOG.md` (`[8.343.0]`) and `ISSUES.md` (`[ISSUE-135]`).
5. Iterative secondary code review to inspect for any additional mathematical edge cases.
