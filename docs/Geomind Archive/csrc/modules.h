#pragma once

#include "tensor.h"
#include "mlp_layers.h"
#include <memory>
#include <vector>

namespace geomath {

class SphericalNorm {
private:
    float eps_;
public:
    SphericalNorm(size_t dim, float eps = 1e-6f, int device_id = 0);
    void forward_inplace(Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& x, const Tensor* g_metric = nullptr);
};

class ContinuousEmbedding {
private:
    std::unique_ptr<Tensor> weight_context_;
    std::unique_ptr<Tensor> weight_gauge_;
    std::unique_ptr<Tensor> weight_context_grad_;
    std::unique_ptr<Tensor> weight_gauge_grad_;
    size_t vocab_size_;
    size_t dim_;
public:
    ContinuousEmbedding(size_t vocab_size, size_t dim, int device_id = 0);
    std::unique_ptr<Tensor> forward(const int* token_ids, size_t batch, size_t seq_len);
    void backward(const Tensor& grad_output, const int* token_ids, size_t batch, size_t seq_len);
    
    Tensor* weight_context() { return weight_context_.get(); }
    Tensor* weight_gauge() { return weight_gauge_.get(); }
    Tensor* weight_context_grad() { return weight_context_grad_.get(); }
    Tensor* weight_gauge_grad() { return weight_gauge_grad_.get(); }
};

class E8CosformerAttention {
private:
    std::unique_ptr<LinearLayer> q_proj_;
    std::unique_ptr<LinearLayer> k_proj_;
    std::unique_ptr<LinearLayer> v_proj_;
    std::unique_ptr<LinearLayer> out_proj_;
    std::unique_ptr<Tensor> cached_q_;
    std::unique_ptr<Tensor> cached_k_;
    std::unique_ptr<Tensor> cached_v_;
public:
    E8CosformerAttention(size_t total_dim, size_t integer_dim, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric = nullptr);
    
    LinearLayer* q_proj() { return q_proj_.get(); }
    LinearLayer* k_proj() { return k_proj_.get(); }
    LinearLayer* v_proj() { return v_proj_.get(); }
    LinearLayer* out_proj() { return out_proj_.get(); }
};

class E8LatticeWaveSSM {
private:
    std::unique_ptr<LinearLayer> w_x_;
    std::unique_ptr<LinearLayer> w_y_;
    std::unique_ptr<LinearLayer> w_out_;
    std::unique_ptr<SphericalNorm> norm_;
    std::unique_ptr<Tensor> cached_proj_x_;
    std::unique_ptr<Tensor> cached_proj_y_;
    std::unique_ptr<Tensor> cached_h_states_;
public:
    E8LatticeWaveSSM(size_t total_dim, size_t rank, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric = nullptr);
    
    LinearLayer* w_x() { return w_x_.get(); }
    LinearLayer* w_y() { return w_y_.get(); }
    LinearLayer* w_out() { return w_out_.get(); }
    SphericalNorm* norm() { return norm_.get(); }
};

class SpectralMemory {
private:
    std::unique_ptr<LinearLayer> filter_proj_;
    std::unique_ptr<LinearLayer> out_proj_;
    std::unique_ptr<SphericalNorm> norm_;
    std::unique_ptr<Tensor> cached_x_;
    std::unique_ptr<Tensor> cached_filter_;
    std::unique_ptr<Tensor> cached_mem_;
public:
    SpectralMemory(size_t total_dim, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric = nullptr);
    
    LinearLayer* filter_proj() { return filter_proj_.get(); }
    LinearLayer* out_proj() { return out_proj_.get(); }
};

class HyperbolicAttention {
private:
    std::unique_ptr<LinearLayer> in_proj_;
    std::unique_ptr<LinearLayer> out_proj_;
    std::unique_ptr<Tensor> cached_proj_;
public:
    HyperbolicAttention(size_t total_dim, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric = nullptr);
    LinearLayer* in_proj() { return in_proj_.get(); }
    LinearLayer* out_proj() { return out_proj_.get(); }
};

class TopologicalHomologyAttention {
private:
    std::unique_ptr<LinearLayer> in_proj_;
    std::unique_ptr<LinearLayer> out_proj_;
    std::unique_ptr<Tensor> cached_proj_;
public:
    TopologicalHomologyAttention(size_t total_dim, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric = nullptr);
    LinearLayer* in_proj() { return in_proj_.get(); }
    LinearLayer* out_proj() { return out_proj_.get(); }
};

class GeodesicRayTracingAttention {
private:
    std::unique_ptr<LinearLayer> in_proj_;
    std::unique_ptr<LinearLayer> out_proj_;
    std::unique_ptr<Tensor> cached_proj_;
public:
    GeodesicRayTracingAttention(size_t total_dim, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric = nullptr);
    LinearLayer* in_proj() { return in_proj_.get(); }
    LinearLayer* out_proj() { return out_proj_.get(); }
};

class HeatKernelDiffusionAttention {
private:
    std::unique_ptr<LinearLayer> in_proj_;
    std::unique_ptr<LinearLayer> out_proj_;
    std::unique_ptr<Tensor> cached_proj_;
public:
    HeatKernelDiffusionAttention(size_t total_dim, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric = nullptr);
    LinearLayer* in_proj() { return in_proj_.get(); }
    LinearLayer* out_proj() { return out_proj_.get(); }
};

class SymplecticTrialityMixer {
private:
    std::unique_ptr<LinearLayer> in_proj_;
    std::unique_ptr<LinearLayer> out_proj_;
    std::unique_ptr<Tensor> cached_proj_;
public:
    SymplecticTrialityMixer(size_t total_dim, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor* g_metric = nullptr);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output, const Tensor& cached_x, const Tensor* g_metric = nullptr);
    LinearLayer* in_proj() { return in_proj_.get(); }
    LinearLayer* out_proj() { return out_proj_.get(); }
};

class SasakiRouter {
public:
    SasakiRouter();
    std::unique_ptr<Tensor> route(const Tensor& x);
    std::unique_ptr<Tensor> backward(const Tensor& grad_probs, const Tensor& probs, const Tensor& x);
};

class E8MagicSquareMoE {
private:
    std::unique_ptr<MLP> experts_[16];
public:
    E8MagicSquareMoE(size_t dim, size_t hidden, int device_id = 0);
    std::unique_ptr<Tensor> forward(const Tensor& x, const Tensor& routing_probs);
    struct MoEBackwardResult {
        std::unique_ptr<Tensor> grad_in;
        std::unique_ptr<Tensor> grad_probs;
    };
    MoEBackwardResult backward(const Tensor& grad_output, const Tensor& probs, const Tensor& cached_x);
    
    MLP* expert(int idx) { return experts_[idx].get(); }
};

} // namespace geomath
