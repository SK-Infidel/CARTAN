#pragma once

namespace geomath {

// Standard E8 Root Lattice Generator Matrix (8x8)
extern const float d_E8_M[8][8];

// Projects a continuous 8D coordinate into the nearest valid E8 discrete lattice point
void project_to_valid_e8(float* x);

// Generates the continuous coordinates for a specific discrete integer basis
void matrix_basis_generate_e8(const int* integer_indices, float* e8_coords_out);

} // namespace geomath
