// src/std/algebra.cl
// CARTAN Standard Library: Unified Algebraic Architecture (Umbrella Entrypoint)
// Named in honor of Élie Cartan (1869–1951)

// Pillar 1: Multilinear Tensor Algebra & Matrix Factorizations
include "src/std/algebra/tensor.cl";

// Pillar 2: Clifford, Weyl & Hypercomplex Algebras
include "src/std/algebra/geometric.cl";

// Pillars 3–4 will be re-exported here as they are established:
// include "src/std/algebra/lie.cl";       // Pillar 3: Lie Algebras, Roots & Poisson
// include "src/std/algebra/abstract.cl";  // Pillar 4: Jordan, Tropical & Logic

