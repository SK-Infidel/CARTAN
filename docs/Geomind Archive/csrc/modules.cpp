#include "modules.h"
#include "math_primitives.h"
#include "ocl_backend.h"
#include <iostream>

namespace geomath {


static std::unique_ptr<Tensor> tensor_copy(const Tensor& src) {
    auto dst = std::make_unique<Tensor>(src.shape(), src.device());
    OCLBackend::get_instance().queue(src.device()).enqueueCopyBuffer(
        *src.buffer(), *dst->buffer(),
        0, 0, src.numel() * sizeof(float)
    );
    return dst;
}

static std::unique_ptr<Tensor> tensor_multiply(const Tensor& a, const Tensor& b) {
    auto out = std::make_unique<Tensor>(a.shape(), a.device());
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(a.device()), "tensor_multiply_inplace");
    
    OCLBackend::get_instance().queue(a.device()).enqueueCopyBuffer(
        *a.buffer(), *out->buffer(), 0, 0, a.numel() * sizeof(float)
    );
    kernel.setArg(0, *out->buffer());
    kernel.setArg(1, *b.buffer());
    kernel.setArg(2, static_cast<int>(a.numel()));
    backend.queue(a.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(a.numel()), cl::NullRange);
    return out;
}

static std::unique_ptr<Tensor> tensor_add(const Tensor& a, const Tensor& b) {
    auto c = std::make_unique<Tensor>(a.shape(), a.device());
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(a.device()), "tensor_add");
    kernel.setArg(0, *a.buffer());
    kernel.setArg(1, *b.buffer());
    kernel.setArg(2, *c->buffer());
    kernel.setArg(3, static_cast<int>(a.numel()));
    backend.queue(a.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(a.numel()), cl::NullRange);
    return c;
}


SphericalNorm::SphericalNorm(size_t dim, float eps, int device_id) : eps_(eps) {
}

void SphericalNorm::forward_inplace(Tensor& x, const Tensor* g_metric) {
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "spherical_norm_inplace");
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t dim = x.shape()[2];
    
    kernel.setArg(0, *x.buffer());
    kernel.setArg(1, eps_);
    kernel.setArg(2, static_cast<int>(batch));
    kernel.setArg(3, static_cast<int>(seq));
    kernel.setArg(4, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
}

std::unique_ptr<Tensor> SphericalNorm::backward(const Tensor& grad_output, const Tensor& x, const Tensor* g_metric) {
    auto grad_in = std::make_unique<Tensor>(x.shape(), x.device());
    grad_in->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "spherical_norm_backward");
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t dim = x.shape()[2];
    
    kernel.setArg(0, *grad_output.buffer());
    kernel.setArg(1, *x.buffer());
    kernel.setArg(2, *grad_in->buffer());
    kernel.setArg(3, eps_);
    kernel.setArg(4, static_cast<int>(batch));
    kernel.setArg(5, static_cast<int>(seq));
    kernel.setArg(6, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    return grad_in;
}

E8CosformerAttention::E8CosformerAttention(size_t total_dim, size_t integer_dim, int device_id) {
    q_proj_ = std::make_unique<LinearLayer>(total_dim, integer_dim, device_id);
    k_proj_ = std::make_unique<LinearLayer>(total_dim, integer_dim, device_id);
    v_proj_ = std::make_unique<LinearLayer>(total_dim, integer_dim, device_id);
    out_proj_ = std::make_unique<LinearLayer>(integer_dim, total_dim, device_id);
}
std::unique_ptr<Tensor> E8CosformerAttention::forward(const Tensor& x, const Tensor* g_metric) {
    auto q = q_proj_->forward(x);
    auto k = k_proj_->forward(x);
    auto v = v_proj_->forward(x);
    
    if (!cached_q_ || cached_q_->shape() != q->shape()) cached_q_ = std::make_unique<Tensor>(q->shape(), x.device());
    OCLBackend::get_instance().queue(x.device()).enqueueCopyBuffer(*q->buffer(), *cached_q_->buffer(), 0, 0, q->numel() * sizeof(float));
    if (!cached_k_ || cached_k_->shape() != k->shape()) cached_k_ = std::make_unique<Tensor>(k->shape(), x.device());
    OCLBackend::get_instance().queue(x.device()).enqueueCopyBuffer(*k->buffer(), *cached_k_->buffer(), 0, 0, k->numel() * sizeof(float));
    if (!cached_v_ || cached_v_->shape() != v->shape()) cached_v_ = std::make_unique<Tensor>(v->shape(), x.device());
    OCLBackend::get_instance().queue(x.device()).enqueueCopyBuffer(*v->buffer(), *cached_v_->buffer(), 0, 0, v->numel() * sizeof(float));
    
    // The attention kernel processes the projected integer_dim (8)
    auto attn_result = std::make_unique<Tensor>(v->shape(), x.device());
    attn_result->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "e8_cosformer_forward");
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t integer_dim = q->shape()[2];
    
    kernel.setArg(0, *q->buffer());
    kernel.setArg(1, *k->buffer());
    kernel.setArg(2, *v->buffer());
    kernel.setArg(3, *attn_result->buffer());
    kernel.setArg(4, static_cast<int>(batch));
    kernel.setArg(5, static_cast<int>(seq));
    kernel.setArg(6, static_cast<int>(integer_dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    // Project back to total_dim
    auto out = out_proj_->forward(*attn_result);
    return out;
}

std::unique_ptr<Tensor> E8CosformerAttention::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    // 1. Backprop through the output projection
    auto grad_attn_result = out_proj_->backward(grad_output);
    
    auto& backend = OCLBackend::get_instance();
    size_t batch = cached_x.shape()[0];
    size_t seq = cached_x.shape()[1];
    size_t dim = cached_q_->shape()[2];
    
    auto grad_q = std::make_unique<Tensor>(cached_q_->shape(), cached_x.device()); grad_q->zero_();
    auto grad_k = std::make_unique<Tensor>(cached_k_->shape(), cached_x.device()); grad_k->zero_();
    auto grad_v = std::make_unique<Tensor>(cached_v_->shape(), cached_x.device()); grad_v->zero_();

    auto A_mat = std::make_unique<Tensor>(std::vector<size_t>{batch, seq, seq}, cached_x.device());
    auto dScore_mat = std::make_unique<Tensor>(std::vector<size_t>{batch, seq, seq}, cached_x.device());
    
    cl::Kernel kernel1(backend.program(cached_x.device()), "e8_cosformer_backward_pass1");
    kernel1.setArg(0, *grad_attn_result->buffer());
    kernel1.setArg(1, *cached_q_->buffer());
    kernel1.setArg(2, *cached_k_->buffer());
    kernel1.setArg(3, *cached_v_->buffer());
    kernel1.setArg(4, *A_mat->buffer());
    kernel1.setArg(5, *dScore_mat->buffer());
    kernel1.setArg(6, static_cast<int>(batch));
    kernel1.setArg(7, static_cast<int>(seq));
    kernel1.setArg(8, static_cast<int>(dim));
    
    backend.queue(cached_x.device()).enqueueNDRangeKernel(kernel1, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);

    cl::Kernel kernel2(backend.program(cached_x.device()), "e8_cosformer_backward_pass2");
    kernel2.setArg(0, *grad_attn_result->buffer());
    kernel2.setArg(1, *cached_q_->buffer());
    kernel2.setArg(2, *cached_k_->buffer());
    kernel2.setArg(3, *A_mat->buffer());
    kernel2.setArg(4, *dScore_mat->buffer());
    kernel2.setArg(5, *grad_q->buffer());
    kernel2.setArg(6, *grad_k->buffer());
    kernel2.setArg(7, *grad_v->buffer());
    kernel2.setArg(8, static_cast<int>(batch));
    kernel2.setArg(9, static_cast<int>(seq));
    kernel2.setArg(10, static_cast<int>(dim));
    
    backend.queue(cached_x.device()).enqueueNDRangeKernel(kernel2, cl::NullRange, cl::NDRange(batch, seq, dim), cl::NullRange);
    
    // 3. Backprop through the q, k, v projections to compute their weight gradients
    auto d_q = q_proj_->backward(*grad_q);
    auto d_k = k_proj_->backward(*grad_k);
    auto d_v = v_proj_->backward(*grad_v);
    
    // 4. Combine gradients to pass down the residual stream
    auto d_qk = tensor_add(*d_q, *d_k);
    auto grad_in = tensor_add(*d_qk, *d_v);
    
    return grad_in;
}

SasakiRouter::SasakiRouter() {}


std::unique_ptr<Tensor> SasakiRouter::route(const Tensor& x) {
    size_t B = x.shape()[0];
    size_t L = x.shape()[1];
    auto probs = std::make_unique<Tensor>(std::vector<size_t>{B, L, 16}, x.device());
    probs->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "sasaki_router_forward");
    
    kernel.setArg(0, *x.buffer());
    kernel.setArg(1, *probs->buffer());
    kernel.setArg(2, static_cast<int>(B));
    kernel.setArg(3, static_cast<int>(L));
    kernel.setArg(4, static_cast<int>(x.shape()[2]));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(B, L), cl::NullRange);
    return probs;
}

std::unique_ptr<Tensor> SasakiRouter::backward(const Tensor& grad_probs, const Tensor& probs, const Tensor& x) {
    auto grad_in = std::make_unique<Tensor>(x.shape(), x.device());
    grad_in->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "sasaki_router_backward");
    
    size_t B = x.shape()[0];
    size_t L = x.shape()[1];
    size_t dim = x.shape()[2];
    
    kernel.setArg(0, *grad_probs.buffer());
    kernel.setArg(1, *probs.buffer());
    kernel.setArg(2, *x.buffer());
    kernel.setArg(3, *grad_in->buffer());
    kernel.setArg(4, static_cast<int>(B));
    kernel.setArg(5, static_cast<int>(L));
    kernel.setArg(6, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(B, L), cl::NullRange);
    return grad_in;
}

E8MagicSquareMoE::E8MagicSquareMoE(size_t dim, size_t hidden, int device_id) {
    for(int i=0; i<16; ++i) {
        experts_[i] = std::make_unique<MLP>(dim, hidden, dim, device_id);
    }
}

std::unique_ptr<Tensor> E8MagicSquareMoE::forward(const Tensor& x, const Tensor& routing_probs) {
    auto out = std::make_unique<Tensor>(x.shape(), x.device());
    out->zero_();
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t dim = x.shape()[2];
    
    auto expert_outs = std::make_unique<Tensor>(std::vector<size_t>{16, batch, seq, dim}, x.device());
    
    for(int i=0; i<16; ++i) {
        auto e_out = experts_[i]->forward(x);
        OCLBackend::get_instance().queue(x.device()).enqueueCopyBuffer(
            *e_out->buffer(), *expert_outs->buffer(),
            0, i * batch * seq * dim * sizeof(float),
            batch * seq * dim * sizeof(float)
        );
    }
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "magic_square_moe_forward");
    
    kernel.setArg(0, *x.buffer());
    kernel.setArg(1, *routing_probs.buffer());
    kernel.setArg(2, *expert_outs->buffer());
    kernel.setArg(3, *out->buffer());
    kernel.setArg(4, static_cast<int>(batch));
    kernel.setArg(5, static_cast<int>(seq));
    kernel.setArg(6, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq, dim), cl::NullRange);
    return out;
}

E8MagicSquareMoE::MoEBackwardResult E8MagicSquareMoE::backward(const Tensor& grad_output, const Tensor& probs, const Tensor& cached_x) {
    MoEBackwardResult res;
    res.grad_in = std::make_unique<Tensor>(cached_x.shape(), cached_x.device());
    res.grad_in->zero_();
    res.grad_probs = std::make_unique<Tensor>(probs.shape(), probs.device());
    res.grad_probs->zero_();
    
    size_t batch = cached_x.shape()[0];
    size_t seq = cached_x.shape()[1];
    size_t dim = cached_x.shape()[2];
    
    auto grad_expert_outs = std::make_unique<Tensor>(std::vector<size_t>{16, batch, seq, dim}, cached_x.device());
    grad_expert_outs->zero_();
    
    auto expert_outs = std::make_unique<Tensor>(std::vector<size_t>{16, batch, seq, dim}, cached_x.device());
    for(int i=0; i<16; ++i) {
        auto e_out = experts_[i]->forward(cached_x);
        OCLBackend::get_instance().queue(cached_x.device()).enqueueCopyBuffer(*e_out->buffer(), *expert_outs->buffer(), 0, i * batch * seq * dim * sizeof(float), batch * seq * dim * sizeof(float));
    }
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(cached_x.device()), "magic_square_moe_backward");
    
    kernel.setArg(0, *grad_output.buffer());
    kernel.setArg(1, *probs.buffer());
    kernel.setArg(2, *expert_outs->buffer());
    kernel.setArg(3, *res.grad_in->buffer());
    kernel.setArg(4, *res.grad_probs->buffer());
    kernel.setArg(5, *grad_expert_outs->buffer());
    kernel.setArg(6, static_cast<int>(batch));
    kernel.setArg(7, static_cast<int>(seq));
    kernel.setArg(8, static_cast<int>(dim));
    
    backend.queue(cached_x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq, dim), cl::NullRange);
    
    auto sliced_grad = std::make_unique<Tensor>(cached_x.shape(), cached_x.device());
    
    for(int i=0; i<16; ++i) {
        // Copy the i-th slice from grad_expert_outs into sliced_grad
        backend.queue(cached_x.device()).enqueueCopyBuffer(
            *grad_expert_outs->buffer(), *sliced_grad->buffer(),
            i * batch * seq * dim * sizeof(float), 0,
            batch * seq * dim * sizeof(float)
        );
        
        // Backprop through the expert to compute its weight gradients
        auto d_expert = experts_[i]->backward(*sliced_grad);
        
        // Accumulate the expert's gradient into the residual stream gradient
        auto tmp = tensor_add(*res.grad_in, *d_expert);
        res.grad_in = std::move(tmp);
    }
    
    return res;
}


// ============================================================================
// E8LatticeWaveSSM
// ============================================================================
E8LatticeWaveSSM::E8LatticeWaveSSM(size_t total_dim, size_t rank, int device_id) {
    w_x_ = std::make_unique<LinearLayer>(total_dim, rank, device_id);
    w_y_ = std::make_unique<LinearLayer>(total_dim, rank, device_id);
    w_out_ = std::make_unique<LinearLayer>(rank, total_dim, device_id);
    norm_ = std::make_unique<SphericalNorm>(total_dim, 1e-6f, device_id);
}

std::unique_ptr<Tensor> E8LatticeWaveSSM::forward(const Tensor& x, const Tensor* g_metric) {
    auto u = w_x_->forward(x);
    auto v = w_y_->forward(x);
    cached_proj_x_ = tensor_copy(*u);
    cached_proj_y_ = tensor_copy(*v);
    auto comm = tensor_multiply(*u, *v);
    geomath::cumsum_inplace(*comm, 1);
    auto div = w_out_->forward(*comm);
    auto h = tensor_add(x, *div);
    norm_->forward_inplace(*h, g_metric);
    cached_proj_x_ = std::move(u);
    cached_proj_y_ = std::move(v);
    cached_h_states_ = tensor_copy(*h);
    return h;
}

std::unique_ptr<Tensor> E8LatticeWaveSSM::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_h = norm_->backward(grad_output, *cached_h_states_, g_metric);
    auto grad_div = w_out_->backward(*grad_h);
    geomath::cumsum_backward_inplace(*grad_div, 1);
    auto grad_u = tensor_multiply(*grad_div, *cached_proj_y_);
    auto grad_v = tensor_multiply(*grad_div, *cached_proj_x_);
    auto g_x1 = w_x_->backward(*grad_u);
    auto g_x2 = w_y_->backward(*grad_v);
    auto gx = tensor_add(*g_x1, *g_x2);
    return tensor_add(*gx, *grad_h);
}

// ============================================================================
// SpectralMemory
// ============================================================================
SpectralMemory::SpectralMemory(size_t total_dim, int device_id) {
    filter_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
    out_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
    norm_ = std::make_unique<SphericalNorm>(total_dim, 1e-6f, device_id);
}
std::unique_ptr<Tensor> SpectralMemory::forward(const Tensor& x, const Tensor* g_metric) {
    auto filter = filter_proj_->forward(x);
    geomath::cumsum_inplace(*filter, 1);
    auto mem = tensor_multiply(x, *filter);
    norm_->forward_inplace(*mem, g_metric);
    auto out = out_proj_->forward(*mem);
    cached_x_ = tensor_copy(x);
    cached_filter_ = std::move(filter);
    cached_mem_ = std::move(mem);
    return out;
}
std::unique_ptr<Tensor> SpectralMemory::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_mem = out_proj_->backward(grad_output);
    auto grad_mem_norm = norm_->backward(*grad_mem, *cached_mem_, g_metric);
    auto gx1 = tensor_multiply(*grad_mem_norm, *cached_filter_);
    auto grad_f = tensor_multiply(*grad_mem_norm, *cached_x_);
    geomath::cumsum_backward_inplace(*grad_f, 1);
    auto gx2 = filter_proj_->backward(*grad_f);
    return tensor_add(*gx1, *gx2);
}

// ============================================================================
// HyperbolicAttention
// ============================================================================
HyperbolicAttention::HyperbolicAttention(size_t total_dim, int device_id) {
    in_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
    out_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
}
std::unique_ptr<Tensor> HyperbolicAttention::forward(const Tensor& x, const Tensor* g_metric) {
    auto u = in_proj_->forward(x);
    cached_proj_ = tensor_copy(*u);
    
    auto attn_result = std::make_unique<Tensor>(u->shape(), x.device());
    attn_result->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "hyperbolic_forward");
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t dim = x.shape()[2];
    
    kernel.setArg(0, *u->buffer());
    kernel.setArg(1, *attn_result->buffer());
    kernel.setArg(2, static_cast<int>(batch));
    kernel.setArg(3, static_cast<int>(seq));
    kernel.setArg(4, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    auto out = out_proj_->forward(*attn_result);
    return out;
}
std::unique_ptr<Tensor> HyperbolicAttention::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_attn_result = out_proj_->backward(grad_output);
    
    auto grad_u = std::make_unique<Tensor>(cached_proj_->shape(), cached_x.device());
    grad_u->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(cached_x.device()), "hyperbolic_backward");
    
    size_t batch = cached_x.shape()[0];
    size_t seq = cached_x.shape()[1];
    size_t dim = cached_x.shape()[2];
    
    kernel.setArg(0, *grad_attn_result->buffer());
    kernel.setArg(1, *cached_proj_->buffer());
    kernel.setArg(2, *grad_u->buffer());
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(seq));
    kernel.setArg(5, static_cast<int>(dim));
    
    backend.queue(cached_x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    return in_proj_->backward(*grad_u);
}

// ============================================================================
// TopologicalHomologyAttention
// ============================================================================
TopologicalHomologyAttention::TopologicalHomologyAttention(size_t total_dim, int device_id) {
    in_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
    out_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
}
std::unique_ptr<Tensor> TopologicalHomologyAttention::forward(const Tensor& x, const Tensor* g_metric) {
    auto u = in_proj_->forward(x);
    cached_proj_ = tensor_copy(*u);
    
    auto attn_result = std::make_unique<Tensor>(u->shape(), x.device());
    attn_result->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "homology_forward");
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t dim = x.shape()[2];
    
    kernel.setArg(0, *u->buffer());
    kernel.setArg(1, *attn_result->buffer());
    kernel.setArg(2, static_cast<int>(batch));
    kernel.setArg(3, static_cast<int>(seq));
    kernel.setArg(4, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    auto out = out_proj_->forward(*attn_result);
    return out;
}
std::unique_ptr<Tensor> TopologicalHomologyAttention::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_attn_result = out_proj_->backward(grad_output);
    
    auto grad_u = std::make_unique<Tensor>(cached_proj_->shape(), cached_x.device());
    grad_u->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(cached_x.device()), "homology_backward");
    
    size_t batch = cached_x.shape()[0];
    size_t seq = cached_x.shape()[1];
    size_t dim = cached_x.shape()[2];
    
    kernel.setArg(0, *grad_attn_result->buffer());
    kernel.setArg(1, *cached_proj_->buffer());
    kernel.setArg(2, *grad_u->buffer());
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(seq));
    kernel.setArg(5, static_cast<int>(dim));
    
    backend.queue(cached_x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    return in_proj_->backward(*grad_u);
}

// ============================================================================
// GeodesicRayTracingAttention
// ============================================================================
GeodesicRayTracingAttention::GeodesicRayTracingAttention(size_t total_dim, int device_id) {
    in_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
    out_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
}
std::unique_ptr<Tensor> GeodesicRayTracingAttention::forward(const Tensor& x, const Tensor* g_metric) {
    auto u = in_proj_->forward(x);
    cached_proj_ = tensor_copy(*u);
    
    auto attn_result = std::make_unique<Tensor>(u->shape(), x.device());
    attn_result->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "ray_tracing_forward");
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t dim = x.shape()[2];
    
    kernel.setArg(0, *u->buffer());
    kernel.setArg(1, *attn_result->buffer());
    kernel.setArg(2, static_cast<int>(batch));
    kernel.setArg(3, static_cast<int>(seq));
    kernel.setArg(4, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    auto out = out_proj_->forward(*attn_result);
    return out;
}
std::unique_ptr<Tensor> GeodesicRayTracingAttention::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_attn_result = out_proj_->backward(grad_output);
    
    auto grad_u = std::make_unique<Tensor>(cached_proj_->shape(), cached_x.device());
    grad_u->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(cached_x.device()), "ray_tracing_backward");
    
    size_t batch = cached_x.shape()[0];
    size_t seq = cached_x.shape()[1];
    size_t dim = cached_x.shape()[2];
    
    kernel.setArg(0, *grad_attn_result->buffer());
    kernel.setArg(1, *cached_proj_->buffer());
    kernel.setArg(2, *grad_u->buffer());
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(seq));
    kernel.setArg(5, static_cast<int>(dim));
    
    backend.queue(cached_x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    return in_proj_->backward(*grad_u);
}

// ============================================================================
// HeatKernelDiffusionAttention
// ============================================================================
HeatKernelDiffusionAttention::HeatKernelDiffusionAttention(size_t total_dim, int device_id) {
    in_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
    out_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
}
std::unique_ptr<Tensor> HeatKernelDiffusionAttention::forward(const Tensor& x, const Tensor* g_metric) {
    auto u = in_proj_->forward(x);
    cached_proj_ = tensor_copy(*u);
    
    auto attn_result = std::make_unique<Tensor>(u->shape(), x.device());
    attn_result->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "heat_kernel_forward");
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t dim = x.shape()[2];
    
    kernel.setArg(0, *u->buffer());
    kernel.setArg(1, *attn_result->buffer());
    kernel.setArg(2, static_cast<int>(batch));
    kernel.setArg(3, static_cast<int>(seq));
    kernel.setArg(4, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    auto out = out_proj_->forward(*attn_result);
    return out;
}
std::unique_ptr<Tensor> HeatKernelDiffusionAttention::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_attn_result = out_proj_->backward(grad_output);
    
    auto grad_u = std::make_unique<Tensor>(cached_proj_->shape(), cached_x.device());
    grad_u->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(cached_x.device()), "heat_kernel_backward");
    
    size_t batch = cached_x.shape()[0];
    size_t seq = cached_x.shape()[1];
    size_t dim = cached_x.shape()[2];
    
    kernel.setArg(0, *grad_attn_result->buffer());
    kernel.setArg(1, *cached_proj_->buffer());
    kernel.setArg(2, *grad_u->buffer());
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(seq));
    kernel.setArg(5, static_cast<int>(dim));
    
    backend.queue(cached_x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    return in_proj_->backward(*grad_u);
}

// ============================================================================
// SymplecticTrialityMixer
// ============================================================================
SymplecticTrialityMixer::SymplecticTrialityMixer(size_t total_dim, int device_id) {
    in_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
    out_proj_ = std::make_unique<LinearLayer>(total_dim, total_dim, device_id);
}

std::unique_ptr<Tensor> SymplecticTrialityMixer::forward(const Tensor& x, const Tensor* g_metric) {
    auto u = in_proj_->forward(x);
    cached_proj_ = tensor_copy(*u);
    
    auto mix_result = std::make_unique<Tensor>(u->shape(), x.device());
    mix_result->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(x.device()), "symplectic_triality_forward");
    
    size_t batch = x.shape()[0];
    size_t seq = x.shape()[1];
    size_t dim = x.shape()[2];
    
    kernel.setArg(0, *u->buffer());
    kernel.setArg(1, *mix_result->buffer());
    kernel.setArg(2, static_cast<int>(batch));
    kernel.setArg(3, static_cast<int>(seq));
    kernel.setArg(4, static_cast<int>(dim));
    
    backend.queue(x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    auto out = out_proj_->forward(*mix_result);
    return out;
}

std::unique_ptr<Tensor> SymplecticTrialityMixer::backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric) {
    auto grad_mix_result = out_proj_->backward(grad_output);
    
    auto grad_u = std::make_unique<Tensor>(cached_proj_->shape(), cached_x.device());
    grad_u->zero_();
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(cached_x.device()), "symplectic_triality_backward");
    
    size_t batch = cached_x.shape()[0];
    size_t seq = cached_x.shape()[1];
    size_t dim = cached_x.shape()[2];
    
    kernel.setArg(0, *grad_mix_result->buffer());
    kernel.setArg(1, *cached_proj_->buffer());
    kernel.setArg(2, *grad_u->buffer());
    kernel.setArg(3, static_cast<int>(batch));
    kernel.setArg(4, static_cast<int>(seq));
    kernel.setArg(5, static_cast<int>(dim));
    
    backend.queue(cached_x.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq), cl::NullRange);
    
    return in_proj_->backward(*grad_u);
}

// ============================================================================
// ContinuousEmbedding
// ============================================================================
ContinuousEmbedding::ContinuousEmbedding(size_t vocab_size, size_t dim, int device_id) 
    : vocab_size_(vocab_size), dim_(dim) {
    weight_context_ = std::make_unique<Tensor>(std::vector<size_t>{vocab_size, 31}, device_id);
    weight_context_->zero_();
    weight_context_grad_ = std::make_unique<Tensor>(std::vector<size_t>{vocab_size, 31}, device_id);
    weight_context_grad_->zero_();
    
    weight_gauge_ = std::make_unique<Tensor>(std::vector<size_t>{8, 8}, device_id);
    weight_gauge_->zero_();
    weight_gauge_grad_ = std::make_unique<Tensor>(std::vector<size_t>{8, 8}, device_id);
    weight_gauge_grad_->zero_();
}

std::unique_ptr<Tensor> ContinuousEmbedding::forward(const int* token_ids, size_t batch, size_t seq_len) {
    auto out = std::make_unique<Tensor>(std::vector<size_t>{batch, seq_len, dim_}, weight_context_->device());
    auto& backend = OCLBackend::get_instance();
    
    cl_int err;
    cl::Buffer token_buf(backend.context(weight_context_->device()), CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 
                         batch * seq_len * sizeof(int), const_cast<int*>(token_ids), &err);
                         
    cl::Kernel kernel(backend.program(weight_context_->device()), "embedding_forward_kronecker");
    kernel.setArg(0, token_buf);
    kernel.setArg(1, *weight_context_->buffer());
    kernel.setArg(2, *weight_gauge_->buffer());
    kernel.setArg(3, *out->buffer());
    kernel.setArg(4, static_cast<int>(batch));
    kernel.setArg(5, static_cast<int>(seq_len));
    kernel.setArg(6, static_cast<int>(dim_));
    kernel.setArg(7, static_cast<int>(vocab_size_));
    
    size_t total_elements = batch * seq_len * dim_;
    cl_int err_launch = backend.queue(weight_context_->device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(total_elements), cl::NullRange);
    if (err_launch != CL_SUCCESS) {
        printf("ERROR: embedding_forward_kronecker launch failed with error code: %d\n", err_launch);
    }
    
    return out;
}

void ContinuousEmbedding::backward(const Tensor& grad_output, const int* token_ids, size_t batch, size_t seq_len) {
    auto& backend = OCLBackend::get_instance();
    cl_int err;
    cl::Buffer token_buf(backend.context(weight_context_->device()), CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 
                         batch * seq_len * sizeof(int), const_cast<int*>(token_ids), &err);
                         
    cl::Kernel kernel(backend.program(weight_context_->device()), "embedding_backward_kronecker");
    kernel.setArg(0, token_buf);
    kernel.setArg(1, *grad_output.buffer());
    kernel.setArg(2, *weight_context_->buffer());
    kernel.setArg(3, *weight_gauge_->buffer());
    kernel.setArg(4, *weight_context_grad_->buffer());
    kernel.setArg(5, *weight_gauge_grad_->buffer());
    kernel.setArg(6, static_cast<int>(batch));
    kernel.setArg(7, static_cast<int>(seq_len));
    kernel.setArg(8, static_cast<int>(dim_));
    kernel.setArg(9, static_cast<int>(vocab_size_));
    
    size_t total_elements = batch * seq_len * dim_;
    backend.queue(weight_context_->device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(total_elements), cl::NullRange);
}

} // namespace geomath
