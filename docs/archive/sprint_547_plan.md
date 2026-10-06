# Sprint 547 Implementation Plan: CARTAN Unified Algebraic Taxonomy (Pillar 4: Abstract, Jordan, Tropical, Boolean & Universal Algebras)

## Sprint Goal
Deliver Pillar 4 of the CARTAN Unified Algebraic Taxonomy under `src/std/algebra/abstract.cl`, covering Jordan algebras, Tropical semirings, Boolean algebras/rings, arbitrary-width BitVectors, and Universal Algebra algebraic property validators. Re-export under `src/std/algebra.cl`, verify with Target 94 (`test_stdlib_algebra_abstract.car`), and validate zero regressions across all affected compiler test targets.

---

## Architecture & Work Breakdown

### Task 1: Jordan Algebras (`AlgJordan`)
- Matrix Jordan product: $A \circ B = \frac{1}{2}(AB + BA)$.
- Jordan triple product: $\{A, B, C\} = (A \circ B) \circ C + (C \circ B) \circ A - (A \circ C) \circ B$.
- Quadratic Jordan operator: $U_A(B) = 2 A \circ (A \circ B) - A^2 \circ B = ABA$.
- Formal finite-dimensional Jordan algebra structure `AlgJordanAlgebra` with 3-tensor $J_{ij}^k$, commutativity enforcement, and basis Jordan identity verification $(x \circ y) \circ x^2 = x \circ (y \circ x^2)$.

### Task 2: Tropical Semirings & Matrices (`AlgTropical`)
- Min-Plus and Max-Plus addition $\oplus$ and multiplication $\otimes$.
- Tropical matrix multiplication: $(A \otimes_{\text{trop}} B)_{ij} = \bigoplus_k (A_{ik} + B_{kj})$.
- Tropical Kleene star closure $A^* = I \oplus A \oplus \dots \oplus A^{n-1}$ for all-pairs shortest paths and transitive closures.
- Tropical scalar operations and identity constants.

### Task 3: Boolean Algebras & Boolean Rings (`AlgBitVector`)
- Lattice operations: Meet ($\wedge$), Join ($\vee$), Complement ($\neg$).
- Verification of De Morgan laws and absorption identities.
- Stone Boolean ring isomorphism: $a + b = a \oplus b$ (XOR), $a \cdot b = a \wedge b$ (AND), with characteristic 2 ($x + x = 0$) and idempotence ($x^2 = x$).
- Multi-word bitvector structure `AlgBitVector` with dynamic bit sizing, bitwise logical operators, Hamming weight (popcount), Hamming distance, and lattice subset ordering ($u \le v \iff u \wedge v = u$).

### Task 4: Universal Algebra & General Structural Taxonomy
- Finite algebraic structures defined on carrier sets $S = \{0, \dots, n-1\}$ with binary operation tables (Cayley tables).
- Automatic axiomatization verifiers: closure, associativity, left/right identity, invertibility, commutativity, and distributivity.
- Classification pipeline: Magma $\to$ Semigroup $\to$ Monoid $\to$ Group $\to$ Abelian Group $\to$ Ring $\to$ Field.
- Homomorphism tester: $\phi(a \star b) = \phi(a) \bullet \phi(b)$.
- General non-associative diagnostics: associator $(x, y, z)$, nucleus $N(A)$, and center $Z(A)$.

### Task 5: Standard Library Umbrella Integration
- Re-export `src/std/algebra/abstract.cl` inside `src/std/algebra.cl`.

### Task 6: Empirical Regression Verification (Target 94)
- Author Target 94: `Projects/geomind/Testing-scratch/test_stdlib_algebra_abstract.car`.
- Gate 1: Jordan Matrix Products, Jordan Triple Products, Quadratic Operators & Formal Jordan Identity.
- Gate 2: Tropical Min-Plus/Max-Plus Semirings, Matrix Multiplication & Kleene Star Shortest Paths.
- Gate 3: Boolean Lattice, Stone Boolean Ring Isomorphism & Multi-Word BitVectors.
- Gate 4: Universal Algebra Classification, Cayley Table Axiomatization, Homomorphisms & Non-Associative Nucleus.
- Register Target 94 and Preset 547 in `tools/run_affected_tests.ps1`.
- Verify clean compilation via `cartanc.exe` and 100% pass across all regression targets.
