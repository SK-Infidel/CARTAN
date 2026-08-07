#pragma once

#include "tensor.h"
#include "modules.h"
#include "optimizer.h"
#include <memory>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

namespace geomath {

struct EngineCache {
    std::unique_ptr<Tensor> input_e8; // Replaces bcen_out
    std::unique_ptr<Tensor> norm1_x;
    std::unique_ptr<Tensor> attn_out;
    std::unique_ptr<Tensor> res1;
    std::unique_ptr<Tensor> norm2_x;
    std::unique_ptr<Tensor> router_probs;
    std::unique_ptr<Tensor> moe_out;
};

class E8StreamBlock {
public:
    std::unique_ptr<E8CosformerAttention> e8_attn_;
    std::unique_ptr<E8LatticeWaveSSM> wave_ssm_;
    std::unique_ptr<SpectralMemory> spectral_mem_;
    std::unique_ptr<HyperbolicAttention> hyperbolic_;
    std::unique_ptr<TopologicalHomologyAttention> topological_;
    std::unique_ptr<GeodesicRayTracingAttention> ray_tracing_;
    std::unique_ptr<HeatKernelDiffusionAttention> heat_diffusion_;
    std::unique_ptr<SymplecticTrialityMixer> triality_mixer_;
    std::unique_ptr<SasakiRouter> router_;
    std::unique_ptr<E8MagicSquareMoE> moe_;
    std::unique_ptr<SphericalNorm> norm1_;
    std::unique_ptr<SphericalNorm> norm2_;
    std::unique_ptr<EngineCache> cache_;

    E8StreamBlock(int device_id = 0);
};

class FinslerOptimizer;

class GeoMindHybridEngine {
private:
    int device_;
    void tensor_add_inplace(Tensor& a, const Tensor& b);
    
    std::unique_ptr<ContinuousEmbedding> embedding_;
    std::vector<std::unique_ptr<E8StreamBlock>> streams_;
    
    // Optimizer
    std::unique_ptr<geomath::FinslerOptimizer> optimizer_;
    
    // Phase 15: Dynamic EMA Probability Tracking
    int num_streams_;
    std::unordered_map<std::string, float> local_ema_freqs_;
    float ema_alpha_ = 0.01f;
    float local_total_tokens_ = 0.0f;
    
    // Persistent OpenCL Buffers to avoid reallocation overhead
    std::unique_ptr<cl::Buffer> target_norms_buffer_;
    size_t target_norms_capacity_ = 0;
    
    std::unique_ptr<cl::Buffer> block_sums_buffer_;
    size_t block_sums_capacity_ = 0;
    
    std::unique_ptr<cl::Buffer> local_ic_buffer_;
    size_t local_ic_capacity_ = 0;
    
    // GPU-accelerated SFT CE loss buffers (allocated on first use, reused)
    std::unique_ptr<Tensor> sft_logits_;       // (N, V) - intermediate logits, becomes grad_logits
    std::unique_ptr<Tensor> sft_loss_buf_;      // (N,) - per-row CE losses
    std::unique_ptr<cl::Buffer> sft_targets_buf_;  // (N,) int buffer for target indices
    std::unique_ptr<Tensor> sft_embeds_transposed_; // (248, V) transposed embeddings buffer
    int sft_buf_N_ = 0;
    int sft_buf_V_ = 0;
    int sft_embeds_capacity_V_ = 0;
    int sft_best_wg_size_ = 0;
    std::vector<float> last_sft_losses_;
    
public:
    GeoMindHybridEngine(int vocab_size = 200000, int num_streams = 7, int device_id = 0);
    std::unique_ptr<Tensor> forward(const int* token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask = 0x7F, const Tensor* metric_tensor = nullptr);
    
    // Returns the 7 independent unaggregated stream tensors for domain testing
    std::vector<std::unique_ptr<Tensor>> forward_all_streams(const int* token_ids, size_t batch, size_t seq_len, int attention_idx, uint32_t active_stream_mask = 0x7F, const Tensor* metric_tensor = nullptr);
    
    void backward(const Tensor& grad_output, const int* token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask = 0x7F, const Tensor* metric_tensor = nullptr);
    float compute_loss_and_backward(const int* target_token_ids, const float* target_ic, const int* token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask = 0x7F, const Tensor* metric_tensor = nullptr);
    float step();
    void zero_grad();
    void reset_local_context();
    void set_learning_rate(float lr);
    void set_embeddings_frozen(bool frozen);
    
    std::unordered_map<std::string, Tensor*> get_parameters();
    std::unordered_map<std::string, Tensor*> get_gradients();
    
    std::vector<float> get_last_sft_losses() const { return last_sft_losses_; }
    
    // GPU-accelerated SFT cross-entropy: logits + softmax + CE loss + gradient all on GPU.
    // Returns scalar mean CE loss. grad_pred_normed_out is filled with gradients w.r.t. pred_normed.
    float sft_ce_forward_backward(
        const Tensor& pred_normed,     // (N, 248) normalized prediction coords on GPU
        const Tensor& norm_embeds,     // (V, 248) normalized embedding matrix on GPU  
        const Tensor& active_ics,      // (V,) information content for Zipf bias on GPU
        const int* targets,            // (N,) target active vocab indices on CPU
        int N, int V,
        float logit_scale, float zipf_gamma,
        Tensor& grad_pred_normed_out); // (N, 248) output gradient on GPU
};

// Expose Finsler backend class to match bindings
class FinslerBackend {
public:
    FinslerBackend();
    std::unique_ptr<Tensor> compute_e8_forward(const Tensor& input_embeddings, const Tensor& e8_metric_tensor);
    std::unique_ptr<Tensor> compute_e8_backward(const Tensor& grad_output, const Tensor& e8_metric_tensor);
};

} // namespace geomath
