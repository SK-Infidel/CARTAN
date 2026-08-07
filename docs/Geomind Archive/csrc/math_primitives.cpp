#include "math_primitives.h"
#include <cmath>

namespace geomath {

void silu_inplace(Tensor& x) {
    auto& backend = OCLBackend::get_instance();
    int dev = x.device();
    cl::Kernel kernel(backend.program(dev), "silu_inplace");
    
    kernel.setArg(0, *x.buffer());
    kernel.setArg(1, static_cast<int>(x.numel()));
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(x.numel()), cl::NullRange
    );
}

void add_bias_inplace(Tensor& x, const Tensor& bias) {
    auto& backend = OCLBackend::get_instance();
    int dev = x.device();
    cl::Kernel kernel(backend.program(dev), "add_bias_inplace");
    
    kernel.setArg(0, *x.buffer());
    kernel.setArg(1, *bias.buffer());
    kernel.setArg(2, static_cast<int>(x.shape().back()));
    kernel.setArg(3, static_cast<int>(x.numel()));
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(x.numel()), cl::NullRange
    );
}

void tanh_inplace(Tensor& x) {}
void sin_inplace(Tensor& x) {}
void cos_inplace(Tensor& x) {}
void exp_inplace(Tensor& x) {}

void rms_norm_inplace(Tensor& x, const Tensor& weight, float eps) {
    if (x.device() != weight.device()) {
        throw std::runtime_error("Tensor device mismatch in rms_norm_inplace");
    }
    auto& backend = OCLBackend::get_instance();
    int dev = x.device();
    cl::Kernel kernel(backend.program(dev), "rms_norm_inplace");
    
    const auto& shape = x.shape();
    size_t batch = shape[0];
    size_t seq = shape[1];
    size_t dim = shape[2];
    
    kernel.setArg(0, *x.buffer());
    kernel.setArg(1, *weight.buffer());
    kernel.setArg(2, eps);
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(seq));
    kernel.setArg(5, static_cast<int>(dim));
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange
    );
}

void cumsum_inplace(Tensor& x, int dim) {
    auto& backend = OCLBackend::get_instance();
    int dev = x.device();
    cl::Kernel kernel(backend.program(dev), "cumsum_inplace");
    
    const auto& shape = x.shape();
    size_t batch = shape[0];
    size_t seq = shape[1];
    size_t d = shape[2];
    
    kernel.setArg(0, *x.buffer());
    kernel.setArg(1, static_cast<int>(batch));
    kernel.setArg(2, static_cast<int>(seq));
    kernel.setArg(3, static_cast<int>(d));
    kernel.setArg(4, dim);
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(batch, d), cl::NullRange
    );
}

void cumsum_backward_inplace(Tensor& grad, int dim) {
    auto& backend = OCLBackend::get_instance();
    int dev = grad.device();
    cl::Kernel kernel(backend.program(dev), "cumsum_backward_inplace");
    
    const auto& shape = grad.shape();
    size_t batch = shape[0];
    size_t seq = shape[1];
    size_t d = shape[2];
    
    kernel.setArg(0, *grad.buffer());
    kernel.setArg(1, static_cast<int>(batch));
    kernel.setArg(2, static_cast<int>(seq));
    kernel.setArg(3, static_cast<int>(d));
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(batch, d), cl::NullRange
    );
}

std::unique_ptr<Tensor> matmul(const Tensor& A, const Tensor& B) {
    if (A.device() != B.device()) {
        throw std::runtime_error("Tensor device mismatch in matmul");
    }
    auto& backend = OCLBackend::get_instance();
    int dev = A.device();
    
    const auto& shapeA = A.shape();
    const auto& shapeB = B.shape();
    
    size_t batch = shapeA[0];
    size_t M = shapeA[1];
    size_t K = shapeA[2];
    size_t N = shapeB.back(); // Handles both 3D [B, K, N] and 2D [K, N]
    bool b_is_batched = (shapeB.size() == 3);
    
    std::vector<size_t> shapeC = {batch, M, N};
    auto C = std::make_unique<Tensor>(shapeC, dev);
    
    cl::Kernel kernel(backend.program(dev), "matmul");
    kernel.setArg(0, *A.buffer());
    kernel.setArg(1, *B.buffer());
    kernel.setArg(2, *C->buffer());
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(M));
    kernel.setArg(5, static_cast<int>(K));
    kernel.setArg(6, static_cast<int>(N));
    kernel.setArg(7, static_cast<int>(b_is_batched ? 1 : 0));
    
    size_t M_padded = ((M + 15) / 16) * 16;
    size_t N_padded = ((N + 15) / 16) * 16;
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(batch, M_padded, N_padded), cl::NDRange(1, 16, 16)
    );
    
    return C;
}

std::unique_ptr<Tensor> matmul_transB(const Tensor& A, const Tensor& B) {
    if (A.device() != B.device()) {
        throw std::runtime_error("Tensor device mismatch in matmul_transB");
    }
    auto& backend = OCLBackend::get_instance();
    int dev = A.device();
    
    const auto& shapeA = A.shape();
    const auto& shapeB = B.shape();
    
    size_t batch = shapeA[0];
    size_t M = shapeA[1];
    size_t K = shapeA[2];
    size_t N = shapeB[0]; // B is [N, K]
    
    std::vector<size_t> shapeC = {batch, M, N};
    auto C = std::make_unique<Tensor>(shapeC, dev);
    
    cl::Kernel kernel(backend.program(dev), "matmul_transB");
    kernel.setArg(0, *A.buffer());
    kernel.setArg(1, *B.buffer());
    kernel.setArg(2, *C->buffer());
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(M));
    kernel.setArg(5, static_cast<int>(K));
    kernel.setArg(6, static_cast<int>(N));
    
    size_t M_padded = ((M + 15) / 16) * 16;
    size_t N_padded = ((N + 15) / 16) * 16;
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(batch, M_padded, N_padded), cl::NDRange(1, 16, 16)
    );
    
    return C;
}

void matmul_transA_sum_batch(const Tensor& A, const Tensor& B, Tensor& C) {
    if (A.device() != B.device() || A.device() != C.device()) {
        throw std::runtime_error("Tensor device mismatch in matmul_transA_sum_batch");
    }
    auto& backend = OCLBackend::get_instance();
    int dev = A.device();
    
    size_t batch = A.shape()[0];
    size_t M = A.shape()[1];
    size_t K = A.shape()[2];
    size_t N = B.shape()[2];
    
    cl::Kernel kernel(backend.program(dev), "matmul_transA_sum_batch");
    kernel.setArg(0, *A.buffer());
    kernel.setArg(1, *B.buffer());
    kernel.setArg(2, *C.buffer());
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(M));
    kernel.setArg(5, static_cast<int>(K));
    kernel.setArg(6, static_cast<int>(N));
    
    size_t K_padded = ((K + 15) / 16) * 16;
    size_t N_padded = ((N + 15) / 16) * 16;
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(K_padded, N_padded), cl::NDRange(16, 16)
    );
}

void sum_batch_seq_accum(const Tensor& A, Tensor& C) {
    if (A.device() != C.device()) {
        throw std::runtime_error("Tensor device mismatch in sum_batch_seq_accum");
    }
    auto& backend = OCLBackend::get_instance();
    int dev = A.device();
    
    size_t batch = A.shape()[0];
    size_t M = A.shape()[1];
    size_t N = A.shape()[2];
    
    cl::Kernel kernel(backend.program(dev), "sum_batch_seq_accum");
    kernel.setArg(0, *A.buffer());
    kernel.setArg(1, *C.buffer());
    kernel.setArg(2, static_cast<int>(batch));
    kernel.setArg(3, static_cast<int>(M));
    kernel.setArg(4, static_cast<int>(N));
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(N), cl::NullRange
    );
}


} // namespace geomath
