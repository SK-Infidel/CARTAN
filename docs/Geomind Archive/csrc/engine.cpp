#include "engine.h"
#include <iostream>
#include <cmath>
#include <chrono>

namespace geomath {

static std::unique_ptr<Tensor> tensor_copy(const Tensor& src) {
    auto dst = std::make_unique<Tensor>(src.shape(), src.device());
    OCLBackend::get_instance().queue(src.device()).enqueueCopyBuffer(
        *src.buffer(), *dst->buffer(),
        0, 0, src.numel() * sizeof(float)
    );
    return dst;
}

void GeoMindHybridEngine::tensor_add_inplace(Tensor& a, const Tensor& b) {
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel(backend.program(a.device()), "tensor_add_inplace");
    kernel.setArg(0, *a.buffer());
    kernel.setArg(1, *b.buffer());
    kernel.setArg(2, static_cast<int>(a.numel()));
    backend.queue(a.device()).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(a.numel()), cl::NullRange);
}

E8StreamBlock::E8StreamBlock(int device_id) {
    e8_attn_ = std::make_unique<E8CosformerAttention>(248, 248, device_id);
    wave_ssm_ = std::make_unique<E8LatticeWaveSSM>(248, 64, device_id);
    spectral_mem_ = std::make_unique<SpectralMemory>(248, device_id);
    hyperbolic_ = std::make_unique<HyperbolicAttention>(248, device_id);
    topological_ = std::make_unique<TopologicalHomologyAttention>(248, device_id);
    ray_tracing_ = std::make_unique<GeodesicRayTracingAttention>(248, device_id);
    heat_diffusion_ = std::make_unique<HeatKernelDiffusionAttention>(248, device_id);
    triality_mixer_ = std::make_unique<SymplecticTrialityMixer>(248, device_id);
    
    router_ = std::make_unique<SasakiRouter>();
    moe_ = std::make_unique<E8MagicSquareMoE>(248, 1024, device_id);
    norm1_ = std::make_unique<SphericalNorm>(248, 1e-6f, device_id);
    norm2_ = std::make_unique<SphericalNorm>(248, 1e-6f, device_id);
    cache_ = std::make_unique<EngineCache>();
}

GeoMindHybridEngine::GeoMindHybridEngine(int vocab_size, int num_streams, int device_id) : device_(device_id) {
    optimizer_ = std::make_unique<FinslerOptimizer>(0.0005f, 0.0f, 0.5f);
    embedding_ = std::make_unique<ContinuousEmbedding>(vocab_size, 248, device_id);
    optimizer_->add_layer("embedding_context", embedding_->weight_context(), nullptr, embedding_->weight_context_grad(), nullptr);
    optimizer_->add_layer("embedding_gauge", embedding_->weight_gauge(), nullptr, embedding_->weight_gauge_grad(), nullptr);
    
    num_streams_ = num_streams;
    for (int i = 0; i < num_streams_; ++i) {
        streams_.push_back(std::make_unique<E8StreamBlock>(device_id));
        auto& s = streams_.back();
        std::string pfx = "stream" + std::to_string(i) + "_";
        optimizer_->add_layer(pfx+"attn_q", s->e8_attn_->q_proj()->weight(), s->e8_attn_->q_proj()->bias(), s->e8_attn_->q_proj()->weight_grad(), s->e8_attn_->q_proj()->bias_grad());
        optimizer_->add_layer(pfx+"attn_k", s->e8_attn_->k_proj()->weight(), s->e8_attn_->k_proj()->bias(), s->e8_attn_->k_proj()->weight_grad(), s->e8_attn_->k_proj()->bias_grad());
        optimizer_->add_layer(pfx+"attn_v", s->e8_attn_->v_proj()->weight(), s->e8_attn_->v_proj()->bias(), s->e8_attn_->v_proj()->weight_grad(), s->e8_attn_->v_proj()->bias_grad());
        optimizer_->add_layer(pfx+"attn_o", s->e8_attn_->out_proj()->weight(), s->e8_attn_->out_proj()->bias(), s->e8_attn_->out_proj()->weight_grad(), s->e8_attn_->out_proj()->bias_grad());
        
        optimizer_->add_layer(pfx+"wave_wx", s->wave_ssm_->w_x()->weight(), s->wave_ssm_->w_x()->bias(), s->wave_ssm_->w_x()->weight_grad(), s->wave_ssm_->w_x()->bias_grad());
        optimizer_->add_layer(pfx+"wave_wy", s->wave_ssm_->w_y()->weight(), s->wave_ssm_->w_y()->bias(), s->wave_ssm_->w_y()->weight_grad(), s->wave_ssm_->w_y()->bias_grad());
        optimizer_->add_layer(pfx+"wave_wout", s->wave_ssm_->w_out()->weight(), s->wave_ssm_->w_out()->bias(), s->wave_ssm_->w_out()->weight_grad(), s->wave_ssm_->w_out()->bias_grad());
        
        optimizer_->add_layer(pfx+"spec_f", s->spectral_mem_->filter_proj()->weight(), s->spectral_mem_->filter_proj()->bias(), s->spectral_mem_->filter_proj()->weight_grad(), s->spectral_mem_->filter_proj()->bias_grad());
        optimizer_->add_layer(pfx+"spec_o", s->spectral_mem_->out_proj()->weight(), s->spectral_mem_->out_proj()->bias(), s->spectral_mem_->out_proj()->weight_grad(), s->spectral_mem_->out_proj()->bias_grad());
        
        optimizer_->add_layer(pfx+"hyp_i", s->hyperbolic_->in_proj()->weight(), s->hyperbolic_->in_proj()->bias(), s->hyperbolic_->in_proj()->weight_grad(), s->hyperbolic_->in_proj()->bias_grad());
        optimizer_->add_layer(pfx+"hyp_o", s->hyperbolic_->out_proj()->weight(), s->hyperbolic_->out_proj()->bias(), s->hyperbolic_->out_proj()->weight_grad(), s->hyperbolic_->out_proj()->bias_grad());
        
        optimizer_->add_layer(pfx+"topo_i", s->topological_->in_proj()->weight(), s->topological_->in_proj()->bias(), s->topological_->in_proj()->weight_grad(), s->topological_->in_proj()->bias_grad());
        optimizer_->add_layer(pfx+"topo_o", s->topological_->out_proj()->weight(), s->topological_->out_proj()->bias(), s->topological_->out_proj()->weight_grad(), s->topological_->out_proj()->bias_grad());
        
        optimizer_->add_layer(pfx+"ray_i", s->ray_tracing_->in_proj()->weight(), s->ray_tracing_->in_proj()->bias(), s->ray_tracing_->in_proj()->weight_grad(), s->ray_tracing_->in_proj()->bias_grad());
        optimizer_->add_layer(pfx+"ray_o", s->ray_tracing_->out_proj()->weight(), s->ray_tracing_->out_proj()->bias(), s->ray_tracing_->out_proj()->weight_grad(), s->ray_tracing_->out_proj()->bias_grad());
        
        optimizer_->add_layer(pfx+"heat_i", s->heat_diffusion_->in_proj()->weight(), s->heat_diffusion_->in_proj()->bias(), s->heat_diffusion_->in_proj()->weight_grad(), s->heat_diffusion_->in_proj()->bias_grad());
        optimizer_->add_layer(pfx+"heat_o", s->heat_diffusion_->out_proj()->weight(), s->heat_diffusion_->out_proj()->bias(), s->heat_diffusion_->out_proj()->weight_grad(), s->heat_diffusion_->out_proj()->bias_grad());
        
        optimizer_->add_layer(pfx+"triality_i", s->triality_mixer_->in_proj()->weight(), s->triality_mixer_->in_proj()->bias(), s->triality_mixer_->in_proj()->weight_grad(), s->triality_mixer_->in_proj()->bias_grad());
        optimizer_->add_layer(pfx+"triality_o", s->triality_mixer_->out_proj()->weight(), s->triality_mixer_->out_proj()->bias(), s->triality_mixer_->out_proj()->weight_grad(), s->triality_mixer_->out_proj()->bias_grad());
        
        for (int e = 0; e < 16; ++e) {
            optimizer_->add_layer(pfx+"moe"+std::to_string(e)+"_fc1", s->moe_->expert(e)->fc1()->weight(), s->moe_->expert(e)->fc1()->bias(), s->moe_->expert(e)->fc1()->weight_grad(), s->moe_->expert(e)->fc1()->bias_grad());
            optimizer_->add_layer(pfx+"moe"+std::to_string(e)+"_fc2", s->moe_->expert(e)->fc2()->weight(), s->moe_->expert(e)->fc2()->bias(), s->moe_->expert(e)->fc2()->weight_grad(), s->moe_->expert(e)->fc2()->bias_grad());
        }
    }
    
    // Initialize SFT member variables
    sft_buf_N_ = 0;
    sft_buf_V_ = 0;
    sft_embeds_capacity_V_ = 0;
    sft_best_wg_size_ = 0;
}

void check_nan_debug(const Tensor& t, const std::string& name) {
    auto& backend = OCLBackend::get_instance();
    std::vector<float> data(t.numel());
    backend.queue(t.device()).enqueueReadBuffer(*t.buffer(), CL_TRUE, 0, t.numel() * sizeof(float), data.data());
    int nans = 0;
    int infs = 0;
    float max_val = -1e30f;
    float min_val = 1e30f;
    for (float v : data) {
        if (std::isnan(v)) nans++;
        else if (std::isinf(v)) infs++;
        else {
            if (v > max_val) max_val = v;
            if (v < min_val) min_val = v;
        }
    }
    printf("[DEBUG] %s - NaNs: %d, Infs: %d, Min: %f, Max: %f\n", name.c_str(), nans, infs, min_val, max_val);
    fflush(stdout);
}

std::vector<std::unique_ptr<Tensor>> GeoMindHybridEngine::forward_all_streams(const int* token_ids, size_t batch, size_t seq_len, int attention_idx, uint32_t active_stream_mask, const Tensor* metric_tensor) {
    auto x_base = embedding_->forward(token_ids, batch, seq_len);
    // check_nan_debug(*x_base, "embedding_->forward");
    
    auto final_agg = std::make_unique<Tensor>(x_base->shape(), x_base->device());
    final_agg->zero_();

    int num_active = 0;
    for (int s = 0; s < num_streams_; ++s) {
        if ((active_stream_mask & (1 << s)) != 0) num_active++;
    }
    if (num_active == 0) num_active = 1;

    for (int s = 0; s < num_streams_; ++s) {
        if ((active_stream_mask & (1 << s)) == 0) {
            tensor_add_inplace(*final_agg, *x_base);
            continue;
        }

        auto& stream = streams_[s];
        
        stream->cache_->input_e8 = tensor_copy(*x_base);
        stream->cache_->norm1_x = tensor_copy(*x_base);
        stream->norm1_->forward_inplace(*stream->cache_->norm1_x, metric_tensor);
        
        // Weyl reflection inplace
        {
            auto& backend = OCLBackend::get_instance();
            cl::Kernel kernel(backend.program(device_), "weyl_reflect_inplace");
            kernel.setArg(0, *stream->cache_->norm1_x->buffer());
            kernel.setArg(1, s);
            kernel.setArg(2, static_cast<int>(batch));
            kernel.setArg(3, static_cast<int>(seq_len));
            kernel.setArg(4, static_cast<int>(248)); // dim
            backend.queue(device_).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq_len), cl::NullRange);
        }
        // check_nan_debug(*stream->cache_->norm1_x, "norm1_->forward_inplace");
        
        std::unique_ptr<Tensor> attn_out;
        int topo = s % 8;
        if (topo == 0) attn_out = stream->e8_attn_->forward(*stream->cache_->norm1_x, metric_tensor);
        else if (topo == 1) attn_out = stream->wave_ssm_->forward(*stream->cache_->norm1_x, metric_tensor);
        else if (topo == 2) attn_out = stream->spectral_mem_->forward(*stream->cache_->norm1_x, metric_tensor);
        else if (topo == 3) attn_out = stream->hyperbolic_->forward(*stream->cache_->norm1_x, metric_tensor);
        else if (topo == 4) attn_out = stream->topological_->forward(*stream->cache_->norm1_x, metric_tensor);
        else if (topo == 5) attn_out = stream->ray_tracing_->forward(*stream->cache_->norm1_x, metric_tensor);
        else if (topo == 6) attn_out = stream->heat_diffusion_->forward(*stream->cache_->norm1_x, metric_tensor);
        else attn_out = stream->triality_mixer_->forward(*stream->cache_->norm1_x, metric_tensor);
        
        // check_nan_debug(*attn_out, "attn_out (topo=" + std::to_string(topo) + ")");
        
        stream->cache_->attn_out = tensor_copy(*attn_out);
        
        stream->cache_->res1 = tensor_copy(*x_base);
        tensor_add_inplace(*stream->cache_->res1, *attn_out);
        // check_nan_debug(*stream->cache_->res1, "res1");
        
        stream->cache_->norm2_x = tensor_copy(*stream->cache_->res1);
        stream->norm2_->forward_inplace(*stream->cache_->norm2_x, metric_tensor);
        // check_nan_debug(*stream->cache_->norm2_x, "norm2_->forward_inplace");
        
        auto route_probs = stream->router_->route(*stream->cache_->norm2_x);
        // check_nan_debug(*route_probs, "router_->route");
        stream->cache_->router_probs = tensor_copy(*route_probs);
        
        auto moe_out = stream->moe_->forward(*stream->cache_->norm2_x, *route_probs);
        // check_nan_debug(*moe_out, "moe_->forward");
        
        stream->cache_->moe_out = tensor_copy(*stream->cache_->res1);
        tensor_add_inplace(*stream->cache_->moe_out, *moe_out);
        // check_nan_debug(*stream->cache_->moe_out, "res2 (moe_out)");

        tensor_add_inplace(*final_agg, *stream->cache_->moe_out);
    }
    
    auto& backend = OCLBackend::get_instance();
    cl::Kernel kernel_scale(backend.program(device_), "tensor_scale_inplace");
    kernel_scale.setArg(0, *final_agg->buffer());
    kernel_scale.setArg(1, 1.0f / num_streams_);
    kernel_scale.setArg(2, static_cast<int>(final_agg->numel()));
    backend.queue(device_).enqueueNDRangeKernel(kernel_scale, cl::NullRange, cl::NDRange(final_agg->numel()), cl::NullRange);

    // check_nan_debug(*final_agg, "final_agg");

    std::vector<std::unique_ptr<Tensor>> out;
    out.push_back(std::move(final_agg));
    return out;
}

float GeoMindHybridEngine::compute_loss_and_backward(const int* target_token_ids, const float* target_ic, const int* token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask, const Tensor* metric_tensor) {
    auto preds = forward_all_streams(token_ids, batch, seq_len, 0, active_stream_mask, metric_tensor);
    auto pred = preds[0].get();
    
    // Convert target token ids to target E8 coords using the embedding_
    auto target_e8 = embedding_->forward(target_token_ids, batch, seq_len);
    
    auto& backend = OCLBackend::get_instance();
    cl_int err;
    cl::Buffer local_ic_buffer(backend.context(device_), CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 
                               batch * seq_len * sizeof(float), const_cast<float*>(target_ic), &err);
    if (err != CL_SUCCESS) throw std::runtime_error("Failed to allocate local_ic_buffer");
    
    auto grad_stream = std::make_unique<Tensor>(pred->shape(), pred->device());
    auto target_grad_stream = std::make_unique<Tensor>(target_e8->shape(), target_e8->device());
    int numel = static_cast<int>(pred->numel());
    
    size_t local_size = 256;
    size_t num_blocks = (numel + local_size - 1) / local_size;
    cl::Buffer block_sums(backend.context(device_), CL_MEM_READ_WRITE, num_blocks * sizeof(float));
    
    cl::Kernel kernel(backend.program(device_), "spherical_cosine_loss_and_grad");
    kernel.setArg(0, *pred->buffer());
    kernel.setArg(1, *target_e8->buffer());
    kernel.setArg(2, *grad_stream->buffer());
    kernel.setArg(3, *target_grad_stream->buffer());
    kernel.setArg(4, block_sums);
    kernel.setArg(5, numel);
    kernel.setArg(6, static_cast<int>(248)); // dim
    kernel.setArg(7, local_ic_buffer);
    kernel.setArg(8, static_cast<int>(1)); // use_ema_flag
    
    size_t global_size = num_blocks * local_size;
    cl_int err_launch = backend.queue(device_).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(global_size), cl::NDRange(local_size));
    if (err_launch != CL_SUCCESS) {
        printf("ERROR: spherical_cosine_loss_and_grad launch failed with OpenCL error code: %d\n", err_launch);
        throw std::runtime_error("Kernel launch failed");
    }
    
    std::vector<float> host_sums(num_blocks);
    backend.queue(device_).enqueueReadBuffer(block_sums, CL_TRUE, 0, num_blocks * sizeof(float), host_sums.data());
    
    float total_loss = 0.0f;
    for (float s : host_sums) total_loss += s;
    total_loss /= static_cast<float>(batch * seq_len);
    
    embedding_->backward(*target_grad_stream, target_token_ids, batch, seq_len);

    this->backward(*grad_stream, token_ids, batch, seq_len, active_stream_mask, metric_tensor);
    
    cl_int err_finish = backend.queue(device_).finish();
    if (err_finish != CL_SUCCESS) {
        printf("ERROR: Backward pass crashed the OpenCL queue with error code: %d\n", err_finish);
    }
    
    return total_loss;
}

void GeoMindHybridEngine::backward(const Tensor& grad_output, const int* token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask, const Tensor* metric_tensor) {
    auto grad_x_base = std::make_unique<Tensor>(grad_output.shape(), grad_output.device());
    grad_x_base->zero_();

    int num_active = 0;
    for (int s = 0; s < num_streams_; ++s) {
        if ((active_stream_mask & (1 << s)) != 0) num_active++;
    }
    if (num_active == 0) num_active = 1;

    for (int s = 0; s < num_streams_; ++s) {
        if ((active_stream_mask & (1 << s)) == 0) continue; 
        
        auto& stream = streams_[s];
        
        auto grad_out_agg = tensor_copy(grad_output);
        auto& backend = OCLBackend::get_instance();
        cl::Kernel kernel_scale(backend.program(device_), "tensor_scale_inplace");
        kernel_scale.setArg(0, *grad_out_agg->buffer());
        kernel_scale.setArg(1, 1.0f / num_streams_);
        kernel_scale.setArg(2, static_cast<int>(grad_out_agg->numel()));
        backend.queue(device_).enqueueNDRangeKernel(kernel_scale, cl::NullRange, cl::NDRange(grad_out_agg->numel()), cl::NullRange);

        const Tensor* bwd_metric = metric_tensor;
        std::unique_ptr<Tensor> inv_metric_tensor;
        
        if (metric_tensor) {
            inv_metric_tensor = std::make_unique<Tensor>(metric_tensor->shape(), metric_tensor->device());
            cl::Kernel kernel_inv(backend.program(device_), "inverse_randers_metric");
            kernel_inv.setArg(0, *metric_tensor->buffer());
            kernel_inv.setArg(1, *inv_metric_tensor->buffer());
            kernel_inv.setArg(2, static_cast<int>(metric_tensor->numel()));
            backend.queue(device_).enqueueNDRangeKernel(kernel_inv, cl::NullRange, cl::NDRange(metric_tensor->numel()), cl::NullRange);
            bwd_metric = inv_metric_tensor.get();
            
            // Use the NON euclidian inverse randers metric to send things back down the path that they came
            cl::Kernel kernel_mult(backend.program(device_), "tensor_multiply_inplace");
            kernel_mult.setArg(0, *grad_out_agg->buffer());
            kernel_mult.setArg(1, *inv_metric_tensor->buffer());
            kernel_mult.setArg(2, static_cast<int>(grad_out_agg->numel()));
            backend.queue(device_).enqueueNDRangeKernel(kernel_mult, cl::NullRange, cl::NDRange(grad_out_agg->numel()), cl::NullRange);
        }

        auto moe_res = stream->moe_->backward(*grad_out_agg, *stream->cache_->router_probs, *stream->cache_->norm2_x);
        auto route_grad = stream->router_->backward(*moe_res.grad_probs, *stream->cache_->router_probs, *stream->cache_->norm2_x);
        
        auto combined_grad_norm2 = tensor_copy(*moe_res.grad_in);
        tensor_add_inplace(*combined_grad_norm2, *route_grad);
        
        auto norm2_grad = stream->norm2_->backward(*combined_grad_norm2, *stream->cache_->norm2_x, bwd_metric);
        
        auto grad_res1 = tensor_copy(*grad_out_agg);
        tensor_add_inplace(*grad_res1, *norm2_grad);
        
        std::unique_ptr<Tensor> grad_topo;
        int topo = s % 8;
        if (topo == 0) grad_topo = stream->e8_attn_->backward(*grad_res1, *stream->cache_->norm1_x, bwd_metric);
        else if (topo == 1) grad_topo = stream->wave_ssm_->backward(*grad_res1, *stream->cache_->norm1_x, bwd_metric);
        else if (topo == 2) grad_topo = stream->spectral_mem_->backward(*grad_res1, *stream->cache_->norm1_x, bwd_metric);
        else if (topo == 3) grad_topo = stream->hyperbolic_->backward(*grad_res1, *stream->cache_->norm1_x, bwd_metric);
        else if (topo == 4) grad_topo = stream->topological_->backward(*grad_res1, *stream->cache_->norm1_x, bwd_metric);
        else if (topo == 5) grad_topo = stream->ray_tracing_->backward(*grad_res1, *stream->cache_->norm1_x, bwd_metric);
        else if (topo == 6) grad_topo = stream->heat_diffusion_->backward(*grad_res1, *stream->cache_->norm1_x, bwd_metric);
        else grad_topo = stream->triality_mixer_->backward(*grad_res1, *stream->cache_->norm1_x, bwd_metric);
        
        // Weyl reflection inplace on grad_topo
        {
            cl::Kernel kernel(backend.program(device_), "weyl_reflect_inplace");
            kernel.setArg(0, *grad_topo->buffer());
            kernel.setArg(1, s);
            kernel.setArg(2, static_cast<int>(batch));
            kernel.setArg(3, static_cast<int>(seq_len));
            kernel.setArg(4, static_cast<int>(248)); // dim
            backend.queue(device_).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(batch, seq_len), cl::NullRange);
        }

        auto norm1_grad = stream->norm1_->backward(*grad_topo, *stream->cache_->norm1_x, bwd_metric);
        
        tensor_add_inplace(*grad_x_base, *norm1_grad);
        tensor_add_inplace(*grad_x_base, *grad_res1);
    }
    
    // Accumulate identity gradients from ghost streams
    int num_inactive = num_streams_ - num_active;
    if (num_inactive > 0) {
        auto ghost_grad = tensor_copy(grad_output);
        auto& backend = OCLBackend::get_instance();
        cl::Kernel kernel_scale(backend.program(device_), "tensor_scale_inplace");
        kernel_scale.setArg(0, *ghost_grad->buffer());
        kernel_scale.setArg(1, (float)num_inactive / num_streams_);
        kernel_scale.setArg(2, static_cast<int>(ghost_grad->numel()));
        backend.queue(device_).enqueueNDRangeKernel(kernel_scale, cl::NullRange, cl::NDRange(ghost_grad->numel()), cl::NullRange);
        
        tensor_add_inplace(*grad_x_base, *ghost_grad);
    }
    
    embedding_->backward(*grad_x_base, token_ids, batch, seq_len);
}

float GeoMindHybridEngine::step() {
    return optimizer_->step();
}

void GeoMindHybridEngine::zero_grad() {
    optimizer_->zero_grad();
    embedding_->weight_context_grad()->zero_();
    embedding_->weight_gauge_grad()->zero_();
}


// ============================================================================
// FinslerBackend
// ============================================================================
FinslerBackend::FinslerBackend() {}

std::unique_ptr<Tensor> FinslerBackend::compute_e8_forward(const Tensor& input_embeddings, const Tensor& e8_metric_tensor) {
    auto out = std::make_unique<Tensor>(input_embeddings.shape(), input_embeddings.device());
    out->zero_();
    return out;
}

std::unique_ptr<Tensor> FinslerBackend::compute_e8_backward(const Tensor& grad_output, const Tensor& e8_metric_tensor) {
    auto grad_in = std::make_unique<Tensor>(grad_output.shape(), grad_output.device());
    grad_in->zero_();
    return grad_in;
}

// ============================================================================
// Engine Missing Methods
// ============================================================================
std::unique_ptr<Tensor> GeoMindHybridEngine::forward(const int* token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask, const Tensor* metric_tensor) {
    auto preds = forward_all_streams(token_ids, batch, seq_len, 0, active_stream_mask, metric_tensor);
    return std::move(preds[0]);
}

void GeoMindHybridEngine::reset_local_context() {
    // Empty for now
}

void GeoMindHybridEngine::set_learning_rate(float lr) {
    optimizer_->set_lr(lr);
}

std::unordered_map<std::string, Tensor*> GeoMindHybridEngine::get_parameters() {
    auto params = optimizer_->get_params();
    if (params.count("embedding_context_w") == 0) {
        params["embedding_context_w"] = embedding_->weight_context();
    }
    if (params.count("embedding_gauge_w") == 0) {
        params["embedding_gauge_w"] = embedding_->weight_gauge();
    }
    params["embedding_context_w_grad"] = embedding_->weight_context_grad();
    params["embedding_gauge_w_grad"] = embedding_->weight_gauge_grad();
    return params;
}

void GeoMindHybridEngine::set_embeddings_frozen(bool frozen) {
    if (frozen) {
        optimizer_->remove_layer("embedding_context");
        optimizer_->remove_layer("embedding_gauge");
    } else {
        if (optimizer_->get_params().count("embedding_context_w") == 0) {
            optimizer_->add_layer("embedding_context", embedding_->weight_context(), nullptr, embedding_->weight_context_grad(), nullptr);
            optimizer_->add_layer("embedding_gauge", embedding_->weight_gauge(), nullptr, embedding_->weight_gauge_grad(), nullptr);
        }
    }
}

std::unordered_map<std::string, Tensor*> GeoMindHybridEngine::get_gradients() {
    // Return a copy of the optimizer's gradient map so Python can read any layer's gradient
    auto grads = optimizer_->get_grads();
    // Also include the embedding grads (always available regardless of frozen state)
    grads["embedding_context_w_grad"] = embedding_->weight_context_grad();
    grads["embedding_gauge_w_grad"] = embedding_->weight_gauge_grad();
    return grads;
}

float GeoMindHybridEngine::sft_ce_forward_backward(
    const Tensor& pred_normed,     // (N, 248) on GPU
    const Tensor& norm_embeds,     // (V, 248) on GPU
    const Tensor& active_ics,      // (V,) on GPU
    const int* targets,            // (N,) on CPU
    int N, int V,
    float logit_scale, float zipf_gamma,
    Tensor& grad_pred_normed_out)  // (N, 248) output on GPU
{
    auto& backend = OCLBackend::get_instance();
    int dev = device_;
    
    // Allocate or reallocate per-row loss, target, and transposition buffers if dimensions change
    bool dims_changed = (sft_buf_N_ != N || sft_buf_V_ != V);
    if (dims_changed) {
        sft_loss_buf_ = std::make_unique<Tensor>(std::vector<size_t>{(size_t)N}, dev);
        
        cl_int err;
        sft_targets_buf_ = std::make_unique<cl::Buffer>(
            backend.context(dev), CL_MEM_READ_ONLY, N * sizeof(int), nullptr, &err);
        if (err != CL_SUCCESS) {
            printf("ERROR: Failed to allocate SFT targets buffer: %d\n", err);
            return -1.0f;
        }
        
        sft_buf_N_ = N;
        sft_buf_V_ = V;
    }
    
    // Upload targets (CPU int array) to GPU
    backend.queue(dev).enqueueWriteBuffer(*sft_targets_buf_, CL_TRUE, 0, N * sizeof(int), targets);
    
    // Prepare the main SFT fused CE kernel
    cl::Kernel kernel(backend.program(dev), "sft_fused_ce");
    kernel.setArg(0, *pred_normed.buffer());               // pred_normed (N, D)
    kernel.setArg(1, *norm_embeds.buffer());                // embeds (V, D) - row-major
    kernel.setArg(2, *sft_targets_buf_);                    // targets (N,)
    kernel.setArg(3, *active_ics.buffer());                 // ics (V,)
    kernel.setArg(4, *sft_loss_buf_->buffer());             // per_row_loss (N,)
    kernel.setArg(5, *grad_pred_normed_out.buffer());       // grad_pred (N, D)
    kernel.setArg(6, N);
    kernel.setArg(7, V);
    kernel.setArg(8, 248);                                  // D
    kernel.setArg(9, logit_scale);
    kernel.setArg(10, zipf_gamma);
    
    // Run hardware-in-the-loop autotuning sweep over WG_SIZE candidates on first call
    if (sft_best_wg_size_ == 0) {
        printf("\n[GeoMath] Initiating SFT GPU Kernel Autotuner...\n");
        fflush(stdout);
        double best_time = 1e9;
        int candidate_sizes[] = {64, 128, 256};
        
        for (int sz : candidate_sizes) {
            // Warm up iteration
            for (int iter = 0; iter < 2; ++iter) {
                backend.queue(dev).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(N * sz), cl::NDRange(sz));
            }
            backend.queue(dev).finish();
            
            // Timing loop
            auto t_start = std::chrono::high_resolution_clock::now();
            for (int iter = 0; iter < 10; ++iter) {
                backend.queue(dev).enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(N * sz), cl::NDRange(sz));
            }
            backend.queue(dev).finish();
            auto t_end = std::chrono::high_resolution_clock::now();
            double duration = std::chrono::duration<double, std::milli>(t_end - t_start).count();
            double avg_ms = duration / 10.0;
            
            printf("  - Candidate WG_SIZE = %d: %.3f ms\n", sz, avg_ms);
            fflush(stdout);
            if (avg_ms < best_time) {
                best_time = avg_ms;
                sft_best_wg_size_ = sz;
            }
        }
        printf("[GeoMath] Autotuning complete. Optimal WG_SIZE selected: %d (Avg: %.3f ms)\n\n", sft_best_wg_size_, best_time);
        fflush(stdout);
    }
    
    // Launch kernel with optimal workgroup size
    backend.queue(dev).enqueueNDRangeKernel(
        kernel, cl::NullRange, cl::NDRange(N * sft_best_wg_size_), cl::NDRange(sft_best_wg_size_));
    
    // Sync GPU and read per-row losses back to CPU
    backend.queue(dev).finish();
    
    std::vector<float> host_losses(N);
    backend.queue(dev).enqueueReadBuffer(*sft_loss_buf_->buffer(), CL_TRUE, 0,
                                         N * sizeof(float), host_losses.data());
    
    last_sft_losses_ = host_losses;
    
    float total_loss = 0.0f;
    for (int i = 0; i < N; ++i) total_loss += host_losses[i];
    total_loss /= static_cast<float>(N);
    
    return total_loss;
}

} // namespace geomath