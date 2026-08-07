#include "mlp_layers.h"
#include "math_primitives.h"
#include <stdexcept>
#include <random>
#include <cmath>
#include <stdexcept>

namespace geomath {

LinearLayer::LinearLayer(size_t in_features, size_t out_features, int device_id)
    : in_features_(in_features), out_features_(out_features) {
    
    weight_ = std::make_unique<Tensor>(std::vector<size_t>{in_features, out_features}, device_id);
    bias_ = std::make_unique<Tensor>(std::vector<size_t>{out_features}, device_id);
    weight_grad_ = std::make_unique<Tensor>(std::vector<size_t>{in_features, out_features}, device_id);
    bias_grad_ = std::make_unique<Tensor>(std::vector<size_t>{out_features}, device_id);
    
    std::random_device rd;
    std::mt19937 gen(rd());
    float limit = std::sqrt(1.0f / in_features);
    std::uniform_real_distribution<float> dis(-limit, limit);
    
    std::vector<float> w_host(in_features * out_features);
    for (size_t i = 0; i < w_host.size(); ++i) {
        w_host[i] = dis(gen);
    }
    weight_->copy_from_host(w_host.data());
    
    bias_->zero_();
    weight_grad_->zero_();
    bias_grad_->zero_();
}

std::unique_ptr<Tensor> LinearLayer::forward(const Tensor& x) {
    // Cache input for backward pass
    if (!cached_input_ || cached_input_->shape() != x.shape()) {
        cached_input_ = std::make_unique<Tensor>(x.shape(), x.device());
    }
    OCLBackend::get_instance().queue(x.device()).enqueueCopyBuffer(
        *x.buffer(), *cached_input_->buffer(), 0, 0, x.numel() * sizeof(float)
    );
    
    // Y = X * W
    auto out = matmul(x, *weight_);
    add_bias_inplace(*out, *bias_);
    return out;
}

std::unique_ptr<Tensor> LinearLayer::backward(const Tensor& grad_output) {
    // grad_in = grad_output * W^T
    auto grad_in = matmul_transB(grad_output, *weight_);
    
    // weight_grad += cached_input^T * grad_output
    if (cached_input_) {
        matmul_transA_sum_batch(*cached_input_, grad_output, *weight_grad_);
    }
    
    // bias_grad += sum(grad_output, dim=(0,1))
    sum_batch_seq_accum(grad_output, *bias_grad_);
    
    return grad_in;
}

void silu_backward_inplace(Tensor& grad, const Tensor& x) {
    if (grad.device() != x.device()) throw std::runtime_error("Device mismatch in silu_backward");
    auto& backend = OCLBackend::get_instance();
    int dev = x.device();
    cl::Kernel kernel(backend.program(dev), "silu_backward_inplace");
    
    kernel.setArg(0, *grad.buffer());
    kernel.setArg(1, *x.buffer());
    kernel.setArg(2, static_cast<int>(x.numel()));
    
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(x.numel()), cl::NullRange
    );
}

MLP::MLP(size_t in_dim, size_t hidden_dim, size_t out_dim, int device_id) {
    fc1_ = std::make_unique<LinearLayer>(in_dim, hidden_dim, device_id);
    fc2_ = std::make_unique<LinearLayer>(hidden_dim, out_dim, device_id);
    
    // Default initialization is used instead of zero to prevent Finsler norm collapse
}

std::unique_ptr<Tensor> MLP::forward(const Tensor& x) {
    auto hidden = fc1_->forward(x);
    if (!cached_hidden_ || cached_hidden_->shape() != hidden->shape()) {
        cached_hidden_ = std::make_unique<Tensor>(hidden->shape(), x.device());
    }
    OCLBackend::get_instance().queue(x.device()).enqueueCopyBuffer(
        *hidden->buffer(), *cached_hidden_->buffer(), 0, 0, hidden->numel() * sizeof(float)
    );
    silu_inplace(*hidden);
    auto out = fc2_->forward(*hidden);
    return out;
}

std::unique_ptr<Tensor> MLP::backward(const Tensor& grad_output) {
    auto grad_hidden = fc2_->backward(grad_output);
    silu_backward_inplace(*grad_hidden, *cached_hidden_);
    return fc1_->backward(*grad_hidden);
}

} // namespace geomath
