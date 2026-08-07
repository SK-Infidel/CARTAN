#pragma once
#include "tensor.h"
#include <memory>

namespace geomath {

// Matrix operations
// A: [B, M, K], B: [B, K, N] -> C: [B, M, N]
std::unique_ptr<Tensor> matmul(const Tensor& A, const Tensor& B);

// A: [B, M, K], B: [N, K] -> C: [B, M, N]
std::unique_ptr<Tensor> matmul_transB(const Tensor& A, const Tensor& B);

// A: [B, M, K], B: [B, M, N] -> C: [K, N] (accumulates into C)
void matmul_transA_sum_batch(const Tensor& A, const Tensor& B, Tensor& C);

// A: [B, M, N] -> C: [N] (accumulates into C)
void sum_batch_seq_accum(const Tensor& A, Tensor& C);

// Normalization
// x: [..., D], weight: [D]
void rms_norm_inplace(Tensor& x, const Tensor& weight, float eps = 1e-6f);

// Activation and Math (Element-wise inplace)
void silu_inplace(Tensor& x);
void silu_backward_inplace(Tensor& grad, const Tensor& x);
void add_bias_inplace(Tensor& x, const Tensor& bias);
void tanh_inplace(Tensor& x);
void sin_inplace(Tensor& x);
void cos_inplace(Tensor& x);
void exp_inplace(Tensor& x);

// Sequence operations
// x: [B, L, D] -> prefix sum along dim L
void cumsum_inplace(Tensor& x, int dim);
void cumsum_backward_inplace(Tensor& grad, int dim);

} // namespace geomath
