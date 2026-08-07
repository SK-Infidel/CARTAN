#include "e8_topology.h"
#include "geomath.h"

namespace geomath {

const float d_E8_M[8][8] = {
    {1.0f, -1.0f,  0.0f,  0.0f,  0.0f,  0.0f,  0.0f,  0.0f},
    {0.0f,  1.0f, -1.0f,  0.0f,  0.0f,  0.0f,  0.0f,  0.0f},
    {0.0f,  0.0f,  1.0f, -1.0f,  0.0f,  0.0f,  0.0f,  0.0f},
    {0.0f,  0.0f,  0.0f,  1.0f, -1.0f,  0.0f,  0.0f,  0.0f},
    {0.0f,  0.0f,  0.0f,  0.0f,  1.0f, -1.0f,  0.0f,  0.0f},
    {0.0f,  0.0f,  0.0f,  0.0f,  0.0f,  1.0f, -1.0f,  0.0f},
    {0.0f,  0.0f,  0.0f,  0.0f,  0.0f,  0.0f,  1.0f, -1.0f},
    {0.5f,  0.5f,  0.5f,  0.5f,  0.5f,  0.5f,  0.5f,  0.5f}
};

void project_to_valid_e8(float* x) {
    float y_int[8];
    float y_half[8];
    int sum_int = 0;
    int sum_half = 0;
    float max_diff_int = -1.0f;
    float max_diff_half = -1.0f;
    int max_idx_int = 0;
    int max_idx_half = 0;

    for (int i = 0; i < 8; i++) {
        y_int[i] = MATH_ROUND(x[i]);
        sum_int += static_cast<int>(y_int[i]);
        float diff_int = MATH_FABS(y_int[i] - x[i]);
        if (diff_int > max_diff_int) { max_diff_int = diff_int; max_idx_int = i; }

        float fl = static_cast<float>(static_cast<int>(x[i]) - (x[i] < 0.0f ? 1 : 0));
        y_half[i] = fl + 0.5f;
        sum_half += static_cast<int>(fl); 
        float diff_half = MATH_FABS(y_half[i] - x[i]);
        if (diff_half > max_diff_half) { max_diff_half = diff_half; max_idx_half = i; }
    }

    // D8 constraint: integer sum must be even
    if (sum_int % 2 != 0) {
        y_int[max_idx_int] += (y_int[max_idx_int] > x[max_idx_int]) ? -1.0f : 1.0f;
    }
    // Half-integer constraint: sum of floors must be even
    if (std::abs(sum_half) % 2 != 0) {
        y_half[max_idx_half] += (y_half[max_idx_half] > x[max_idx_half]) ? -1.0f : 1.0f;
    }

    float dist_int = 0.0f;
    float dist_half = 0.0f;
    for (int i = 0; i < 8; i++) {
        dist_int += (y_int[i] - x[i]) * (y_int[i] - x[i]);
        dist_half += (y_half[i] - x[i]) * (y_half[i] - x[i]);
    }

    // Snap to the closest valid sub-lattice
    if (dist_int <= dist_half) {
        for (int i = 0; i < 8; i++) x[i] = y_int[i];
    } else {
        for (int i = 0; i < 8; i++) x[i] = y_half[i];
    }
}

void matrix_basis_generate_e8(const int* integer_indices, float* e8_coords_out) {
    for (int i = 0; i < 8; i++) {
        float dimension_sum = 0.0f;
        for (int j = 0; j < 8; j++) {
            dimension_sum += static_cast<float>(integer_indices[j]) * d_E8_M[j][i];
        }
        e8_coords_out[i] = dimension_sum;
    }
}

} // namespace geomath
