#pragma once

#include <cmath>

namespace geomath {

// Math abstractions mapped to std built-ins
#define MATH_SIN(x) std::sin((float)(x))
#define MATH_COS(x) std::cos((float)(x))
#define MATH_EXP(x) std::exp((float)(x))
#define MATH_FABS(x) std::fabs((float)(x))
#define MATH_RSQRT(x) (1.0f / std::sqrt((float)(x)))
#define MATH_SQRT(x) std::sqrt((float)(x))
#define MATH_ROUND(x) std::round((float)(x))
#define MATH_FMA(x, y, z) std::fma((float)(x), (float)(y), (float)(z))

// Constant Offsets for E8 spatial scaling
inline float get_e8_offset(int d) {
    const float offsets[8] = { 2.31f, 3.17f, 5.09f, 7.61f, 11.23f, 13.01f, 17.87f, 19.93f };
    return offsets[d];
}

// Reeb Flow Potential (imaginary axis momentum drift)
inline float compute_reeb_flow_force(float imaginary_coord, float alpha) {
    return -alpha * MATH_SIN(imaginary_coord);
}

// Inverse Compression Tensor calculation (Maj + Chiral Gate)
inline void calculate_inverse_compression_tensor(const float* v, const float* warped_sin_cache, const float* warped_cos_cache, float* tensor_out) {
    // Continuous Majority (Maj) Convergence Optimization via FMA
    float maj = MATH_FMA(warped_sin_cache[0], warped_sin_cache[1] + warped_sin_cache[2], warped_sin_cache[1] * warped_sin_cache[2]);
    float maj_force = -0.01f * maj;
    
    // Continuous Chiral Gate (Ch) Optimization via FMA
    float chooser = MATH_FMA(0.5f, warped_sin_cache[4], 0.5f); 
    float chiral_gate = MATH_FMA(chooser, warped_sin_cache[5] - warped_sin_cache[6], warped_sin_cache[6]);
    float chiral_force = -0.01f * chiral_gate;

    // Tangent Bundle Coriolis Vortices via FMA scalar distribution
    float sigma_0 = MATH_FMA(v[0], 0.025f, MATH_FMA(v[1], 0.015f, v[2] * 0.01f));
    float sigma_1 = MATH_FMA(v[4], 0.025f, MATH_FMA(v[5], 0.015f, v[6] * 0.01f));

    tensor_out[0] = maj_force * warped_sin_cache[0];
    tensor_out[1] = maj_force * warped_sin_cache[1];
    tensor_out[2] = maj_force * warped_sin_cache[2];
    tensor_out[3] = sigma_0 * warped_sin_cache[3];
    
    tensor_out[4] = chiral_force * warped_cos_cache[4];
    tensor_out[5] = chiral_force * warped_cos_cache[5];
    tensor_out[6] = chiral_force * warped_cos_cache[6];
    tensor_out[7] = sigma_1 * warped_cos_cache[7];
}

// Finsler-Randers Static Force Potential
inline float calculate_static_force_potential(const float* vec, int d, float hb_res = 6.4721359f, float landsberg_strength = 0.08f, float rh_tension = 2.0f) {
    float x = vec[d];
    float imaginary_coord = 0.0f;
    
    float finsler_force = MATH_COS(x * hb_res * get_e8_offset(d));
    float rh_deviation = MATH_SIN(x * 12.566370614359172f); // 4 * pi stabilizes both n and n+0.5 roots
    
    // E8 Metric Tensor Shortcut: Riemann Zeta Spectral Density via FRS Curvature Trace
    float e8_trace = MATH_FABS(MATH_FMA(-2.0f, MATH_FABS(x - MATH_ROUND(x)), 1.0f));
    float zeta_spectral = e8_trace * 0.5f;
    
    float base_rh = -rh_tension * rh_deviation;
    float rh_force = MATH_FMA(base_rh, zeta_spectral, base_rh * 0.01f);
    float reeb_force = compute_reeb_flow_force(imaginary_coord, 0.01f);
    
    float wx_wrap = MATH_FMA(-6.2831853f, MATH_ROUND(x * 0.1591549f), x);
    float wx_sq = wx_wrap * wx_wrap;
    
    float p1 = MATH_FMA(0.001170f, wx_sq, -0.024220f);
    float p2 = MATH_FMA(p1, wx_sq, 0.349880f);
    float p3 = MATH_FMA(p2, wx_sq, -2.138845f);
    float prime_gap_harmonics = MATH_FMA(p3, wx_sq, 3.0f);
    float landsberg_drift = landsberg_strength * prime_gap_harmonics;

    float topological_coupling = 0.0f;
    float cos_x = MATH_COS(x);
    for (int j = 0; j < 8; j++) {
        if (j != d) {
            topological_coupling = MATH_FMA(cos_x, MATH_COS(vec[j]), topological_coupling);
        }
    }
    
    return finsler_force + rh_force + reeb_force + landsberg_drift + topological_coupling;
}

} // namespace geomath
