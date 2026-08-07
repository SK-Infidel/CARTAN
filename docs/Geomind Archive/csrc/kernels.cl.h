#pragma once

// All our OpenCL compute kernels embedded as a C++ string
const char* ocl_kernel_source = R"(

__kernel void add_bias_inplace(__global float* x, __global const float* bias, int dim, int num_elements) {
    int i = get_global_id(0);
    if (i < num_elements) {
        int d = i % dim;
        x[i] += bias[d];
    }
}

// 0. Element-wise Addition
__kernel void tensor_add(__global const float* A, __global const float* B, __global float* C, int num_elements) {
    int i = get_global_id(0);
    if (i < num_elements) {
        C[i] = A[i] + B[i];
    }
}

__kernel void tensor_add_inplace(__global float* A, __global const float* B, int num_elements) {
    int i = get_global_id(0);
    if (i < num_elements) {
        A[i] += B[i];
    }
}

__kernel void tensor_scale_inplace(__global float* A, float scale, int num_elements) {
    int i = get_global_id(0);
    if (i < num_elements) {
        A[i] *= scale;
    }
}

__kernel void tensor_multiply_inplace(__global float* A, __global const float* B, int num_elements) {
    int i = get_global_id(0);
    if (i < num_elements) {
        A[i] *= B[i];
    }
}

__kernel void inverse_randers_metric(__global const float* metric, __global float* inv_metric, int num_elements) {
    int i = get_global_id(0);
    if (i < num_elements) {
        // Very basic element-wise inverse approximation for now to avoid crashing
        float val = metric[i];
        if (fabs(val) < 1e-6f) val = 1e-6f * (val < 0 ? -1.0f : 1.0f);
        inv_metric[i] = 1.0f / val;
    }
}

#define TS 16
__kernel void matmul(__global const float* A, __global const float* B, __global float* C, 
                     int B_batch, int M, int K, int N, int b_is_batched) {
    int b = get_global_id(0);
    int row = get_global_id(1);
    int col = get_global_id(2);

    int local_row = get_local_id(1);
    int local_col = get_local_id(2);

    __local float Asub[TS][TS];
    __local float Bsub[TS][TS];

    float sum = 0.0f;
    int num_tiles = (K + TS - 1) / TS;

    for (int t = 0; t < num_tiles; ++t) {
        int tiled_col = t * TS + local_col;
        int tiled_row = t * TS + local_row;

        if (row < M && tiled_col < K) {
            Asub[local_row][local_col] = A[b * M * K + row * K + tiled_col];
        } else {
            Asub[local_row][local_col] = 0.0f;
        }

        if (tiled_row < K && col < N) {
            Bsub[local_row][local_col] = b_is_batched ? B[b * K * N + tiled_row * N + col] : B[tiled_row * N + col];
        } else {
            Bsub[local_row][local_col] = 0.0f;
        }

        barrier(CLK_LOCAL_MEM_FENCE);

        for (int k = 0; k < TS; ++k) {
            sum += Asub[local_row][k] * Bsub[k][local_col];
        }

        barrier(CLK_LOCAL_MEM_FENCE);
    }

    if (row < M && col < N) {
        C[b * M * N + row * N + col] = sum;
    }
}

__kernel void matmul_transB(__global const float* A, __global const float* B, __global float* C, 
                            int B_batch, int M, int K, int N) {
    int b = get_global_id(0);
    int row = get_global_id(1);
    int col = get_global_id(2);

    int local_row = get_local_id(1);
    int local_col = get_local_id(2);

    __local float Asub[TS][TS];
    __local float Bsub[TS][TS];

    float sum = 0.0f;
    int num_tiles = (K + TS - 1) / TS;

    for (int t = 0; t < num_tiles; ++t) {
        int tiled_col = t * TS + local_col;
        int tiled_row = t * TS + local_row;

        if (row < M && tiled_col < K) {
            Asub[local_row][local_col] = A[b * M * K + row * K + tiled_col];
        } else {
            Asub[local_row][local_col] = 0.0f;
        }

        if (col < N && tiled_row < K) {
            Bsub[local_row][local_col] = B[col * K + tiled_row];
        } else {
            Bsub[local_row][local_col] = 0.0f;
        }

        barrier(CLK_LOCAL_MEM_FENCE);

        for (int k = 0; k < TS; ++k) {
            sum += Asub[local_row][k] * Bsub[k][local_col];
        }

        barrier(CLK_LOCAL_MEM_FENCE);
    }

    if (row < M && col < N) {
        C[b * M * N + row * N + col] = sum;
    }
}

__kernel void matmul_transA_sum_batch(__global const float* A, __global const float* B, __global float* C, 
                                      int B_batch, int M, int K, int N) {
    int row = get_global_id(0);
    int col = get_global_id(1);

    int local_row = get_local_id(0);
    int local_col = get_local_id(1);

    __local float Asub[TS][TS];
    __local float Bsub[TS][TS];

    float sum = 0.0f;
    int num_tiles = (M + TS - 1) / TS;

    for (int b = 0; b < B_batch; ++b) {
        for (int t = 0; t < num_tiles; ++t) {
            int tiled_col = t * TS + local_col;
            int tiled_row = t * TS + local_row;

            if (tiled_col < M && row < K) {
                Asub[local_row][local_col] = A[b * M * K + tiled_col * K + row];
            } else {
                Asub[local_row][local_col] = 0.0f;
            }

            if (tiled_row < M && col < N) {
                Bsub[local_row][local_col] = B[b * M * N + tiled_row * N + col];
            } else {
                Bsub[local_row][local_col] = 0.0f;
            }

            barrier(CLK_LOCAL_MEM_FENCE);

            for (int m = 0; m < TS; ++m) {
                sum += Asub[local_row][m] * Bsub[m][local_col];
            }

            barrier(CLK_LOCAL_MEM_FENCE);
        }
    }

    if (row < K && col < N) {
        C[row * N + col] += sum;
    }
}

__kernel void sum_batch_seq_accum(__global const float* A, __global float* C, int B_batch, int M, int N) {
    // A: [B_batch, M, N]
    // C: [N] (accumulates)
    int col = get_global_id(0);
    if (col < N) {
        float sum = 0.0f;
        for (int b = 0; b < B_batch; ++b) {
            for (int m = 0; m < M; ++m) {
                sum += A[b * M * N + m * N + col];
            }
        }
        C[col] += sum;
    }
}

// 2. Spherical Norm
__kernel void spherical_norm_inplace(__global float* x, float eps, int B_batch, int seq_len, int dim) {
    int b = get_global_id(0);
    int seq = get_global_id(1);

    if (b < B_batch && seq < seq_len) {
        float sum_sq = 0.0f;
        int offset = b * seq_len * dim + seq * dim;
        
        for (int i = 0; i < dim; ++i) {
            float val = x[offset + i];
            sum_sq += val * val;
        }
        
        float scalar_norm = sqrt(sum_sq / (float)dim + eps);
        
        for (int i = 0; i < dim; ++i) {
            x[offset + i] = x[offset + i] / scalar_norm;
        }
    }
}

// 3. SiLU
__kernel void silu_inplace(__global float* x, int num_elements) {
    int i = get_global_id(0);
    if (i < num_elements) {
        float val = x[i];
        x[i] = val / (1.0f + exp(-val));
    }
}

__kernel void silu_backward_inplace(__global float* grad, __global const float* x, int num_elements) {
    int i = get_global_id(0);
    if (i < num_elements) {
        float val = x[i];
        float sigmoid = 1.0f / (1.0f + exp(-val));
        float silu_val = val * sigmoid;
        float d_silu = sigmoid + silu_val * (1.0f - sigmoid);
        grad[i] *= d_silu;
    }
}

// 4. CumSum (simplified 1D for now)
__kernel void cumsum_inplace(__global float* x, int B_batch, int seq_len, int dim, int target_dim) {
    int b = get_global_id(0);
    int d = get_global_id(1);
    
    if (b < B_batch && d < dim) {
        float running_sum = 0.0f;
        for (int s = 0; s < seq_len; ++s) {
            int offset = b * seq_len * dim + s * dim + d;
            running_sum += x[offset];
            x[offset] = running_sum;
        }
    }
}

__kernel void cumsum_backward_inplace(__global float* grad, int B_batch, int seq_len, int dim) {
    int b = get_global_id(0);
    int d = get_global_id(1);
    
    if (b < B_batch && d < dim) {
        float running_sum = 0.0f;
        for (int s = seq_len - 1; s >= 0; --s) {
            int offset = b * seq_len * dim + s * dim + d;
            running_sum += grad[offset];
            grad[offset] = running_sum;
        }
    }
}

// 5. Compute pairwise distances (cdist)
__kernel void cdist(__global const float* a, __global const float* b, __global float* out, 
                    int B_batch, int P1, int P2, int dim) {
    int batch = get_global_id(0);
    int p1 = get_global_id(1);
    int p2 = get_global_id(2);

    if (batch < B_batch && p1 < P1 && p2 < P2) {
        float dist_sq = 0.0f;
        for (int d = 0; d < dim; ++d) {
            float diff = a[batch * P1 * dim + p1 * dim + d] - b[batch * P2 * dim + p2 * dim + d];
            dist_sq += diff * diff;
        }
        out[batch * P1 * P2 + p1 * P2 + p2] = sqrt(dist_sq);
    }
}

// 6. BCEN Forward
__kernel void bcen_forward(
    __global const uchar* bytes, __global float* out, __global const float* freqs, 
    __global const float* w, __global const float* b_vec, 
    int batch, int seq_len, int max_bytes) 
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    int d = get_global_id(2);

    if (b < batch && l < seq_len && d < 248) {
        float val = b_vec[d];
        for (int i = 0; i < 32; ++i) {
            float fourier_val = 0.0f;
            for (int mb = 0; mb < max_bytes; ++mb) {
                uchar byte_val = bytes[b * seq_len * max_bytes + l * max_bytes + mb];
                if (byte_val != 0) {
                    float phase = (float)byte_val * freqs[i % 16];
                    fourier_val += (i < 16) ? sin(phase) : cos(phase);
                }
            }
            val += fourier_val * w[d * 32 + i];
        }
        out[b * seq_len * 248 + l * 248 + d] = val;
    }
}

// 7. Spherical Cosine Loss and Gradient Reduction
__kernel void spherical_cosine_loss_and_grad(
    __global const float* pred,
    __global const float* target,
    __global float* grad,
    __global float* grad_target,
    __global float* block_sums,
    int num_elements,
    int dim,
    __global const float* local_ic_weights,
    int use_ema_flag)
{
    int global_id = get_global_id(0);
    int local_id = get_local_id(0);
    int group_id = get_group_id(0);
    int local_size = get_local_size(0);

    // if (global_id == 0) {
    //     printf("Hello from OpenCL kernel! num_elements=%d, dim=%d\n", num_elements, dim);
    // }

    float item_loss = 0.0f;
    if (global_id < num_elements) {
        int batch_idx = global_id / dim;
        int d = global_id % dim;
        
        float x_norm_sq = 0.0f;
        float t_norm_sq = 0.0f;
        for (int k = 0; k < dim; ++k) {
            float xk = pred[batch_idx * dim + k];
            float tk = target[batch_idx * dim + k];
            x_norm_sq += xk * xk;
            t_norm_sq += tk * tk;
        }
        float x_norm = sqrt(x_norm_sq) + 1e-6f;
        float t_norm = sqrt(t_norm_sq) + 1e-6f; // Shannon norm

        float dot = 0.0f;
        for (int k = 0; k < dim; ++k) {
            dot += (pred[batch_idx * dim + k] / x_norm) * (target[batch_idx * dim + k] / t_norm);
        }

        // Loss is (1 - cos_sim) * shannon_weight.
        // We only want to accumulate the loss once per vector, but this kernel has a thread per element.
        // We'll divide the loss by dim so the sum across the vector equals the true loss.
        float shannon_weight;
        float true_ic = local_ic_weights[batch_idx];
        if (use_ema_flag) {
            // Phase 15: Blend Global IC (t_norm) with Local EMA IC
            float blended_ic = 0.5f * t_norm + 0.5f * true_ic;
            shannon_weight = blended_ic + 1.0f; // CORRECTED PROPORTIONAL SCALING
        } else {
            // Pure Causal Pre-training Phase
            shannon_weight = true_ic + 1.0f; // CORRECTED PROPORTIONAL SCALING
        }
        
        item_loss = ((1.0f - dot) * shannon_weight) / (float)dim;

        if (isnan(item_loss) || isinf(item_loss)) {
            printf("NaN/Inf Loss! global_id=%d, batch_idx=%d, d=%d, x_norm=%f, t_norm=%f, dot=%f, true_ic=%f, shannon_weight=%f\\n", 
                   global_id, batch_idx, d, x_norm, t_norm, dot, true_ic, shannon_weight);
        }

        float x = pred[global_id];
        float t = target[global_id];
        float x_hat = x / x_norm;
        float t_hat = t / t_norm;
        
        float grad_cos_pred = (1.0f / x_norm) * (t_hat - x_hat * dot);
        float grad_geom_pred = -grad_cos_pred * shannon_weight;
        
        float grad_cos_target = (1.0f / t_norm) * (x_hat - t_hat * dot);
        float dS_dt = use_ema_flag ? (0.5f * (1.0f - dot) * t_hat) : 0.0f;
        float grad_geom_target = -grad_cos_target * shannon_weight + dS_dt;

        // Scale gradient properly. We have dim elements per vector, and num_elements total.
        // We divide by (num_elements / dim) because the total loss is sum(loss_per_vector) / batch * seq_len.
        float scaling = (float)(num_elements / dim);
        grad[global_id] = grad_geom_pred / scaling;
        grad_target[global_id] = grad_geom_target / scaling;
    }
    
    __local float local_sum[256];
    local_sum[local_id] = item_loss;
    barrier(CLK_LOCAL_MEM_FENCE);
    
    for (int stride = local_size / 2; stride > 0; stride >>= 1) {
        if (local_id < stride) {
            local_sum[local_id] += local_sum[local_id + stride];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }
    
    if (local_id == 0) {
        block_sums[group_id] = local_sum[0];
    }
}

// Helper function for atomic float add in local memory
inline void atomic_add_local(volatile __local float* addr, float val) {
    union { unsigned int u32; float f32; } next, expected, current;
    volatile __local unsigned int* address_as_uint = (volatile __local unsigned int*)addr;
    current.u32 = *address_as_uint;
    do {
        expected.u32 = current.u32;
        next.f32 = expected.f32 + val;
        current.u32 = atomic_cmpxchg(address_as_uint, expected.u32, next.u32);
    } while (current.u32 != expected.u32);
}

// 8a. SFT: Fully Fused Cross-Entropy Loss + Gradient (zero intermediate buffer, workgroup parallel, row-major)
// Launched with block size autotuned. Total workgroups = N.
// Threads in a workgroup cooperatively compute a single token row's loss and gradient.
// Uses row-major embeds matrix (V, D) with float4 vectorization for L2 cache locality and sequential prefetching.
__kernel void sft_fused_ce(
    __global const float* pred_normed,  // (N, D) - normalized prediction coords
    __global const float* embeds,       // (V, D) - normalized embedding matrix
    __global const int* targets,        // (N,) - target active vocab indices
    __global const float* ics,          // (V,) - information content for Zipf bias
    __global float* per_row_loss,       // (N,) - output: per-row CE loss
    __global float* grad_pred,          // (N, D) - output: gradient w.r.t. pred_normed
    int N, int V, int D,
    float logit_scale,
    float zipf_gamma)
{
    int row = get_group_id(0);
    int lid = get_local_id(0);
    int WG_SIZE = get_local_size(0);
    
    if (row >= N) return;
    
    int t = targets[row];
    int pred_off = row * D;
    
    // Shared memory allocations - declared as float4 to force 16-byte alignment
    __local float4 shared_pred[62];
    __local float shared_target_logit;
    __local float shared_mx[256];
    __local float shared_sum[256];
    __local float4 shared_grad[62];
    
    // Get float pointers for scalar access
    __local float* shared_pred_ptr = (__local float*)shared_pred;
    __local float* shared_grad_ptr = (__local float*)shared_grad;
    
    // Cooperative load of prediction coordinates
    for (int k = lid; k < D; k += WG_SIZE) {
        shared_pred_ptr[k] = pred_normed[pred_off + k];
    }
    
    // Zero out shared gradient accumulator
    for (int k = lid; k < D; k += WG_SIZE) {
        shared_grad_ptr[k] = 0.0f;
    }
    
    barrier(CLK_LOCAL_MEM_FENCE);
    
    // Thread 0 computes the target logit sequentially (extremely fast for single row)
    if (lid == 0) {
        float dot_val = 0.0f;
        int emb_off = t * D;
        for (int k = 0; k < D; ++k) {
            dot_val += shared_pred_ptr[k] * embeds[emb_off + k];
        }
        float logit = dot_val * logit_scale;
        if (zipf_gamma > 0.0f) logit -= zipf_gamma * ics[t];
        shared_target_logit = logit;
    }
    
    barrier(CLK_LOCAL_MEM_FENCE);
    
    // Pass 1: Local online max + sum-exp across vocab subset (float4 vectorized dot products)
    float local_mx = -1e30f;
    float local_sum = 0.0f;
    
    for (int j = lid; j < V; j += WG_SIZE) {
        float dot_val = 0.0f;
        int emb_off = j * D;
        
        // Use float4 vectorized dot product
        __global const float4* embeds_f4 = (__global const float4*)(embeds + emb_off);
        for (int k = 0; k < 62; ++k) { // 248 / 4 = 62
            dot_val += dot(shared_pred[k], embeds_f4[k]);
        }
        
        float logit = dot_val * logit_scale;
        if (zipf_gamma > 0.0f) logit -= zipf_gamma * ics[j];
        
        if (logit > local_mx) {
            local_sum = local_sum * exp(local_mx - logit) + 1.0f;
            local_mx = logit;
        } else {
            local_sum += exp(logit - local_mx);
        }
    }
    
    shared_mx[lid] = local_mx;
    shared_sum[lid] = local_sum;
    barrier(CLK_LOCAL_MEM_FENCE);
    
    // Parallel reduction in local memory
    for (int stride = WG_SIZE / 2; stride > 0; stride /= 2) {
        if (lid < stride) {
            float mx1 = shared_mx[lid];
            float mx2 = shared_mx[lid + stride];
            float sum1 = shared_sum[lid];
            float sum2 = shared_sum[lid + stride];
            
            float new_mx = max(mx1, mx2);
            float new_sum = 0.0f;
            if (new_mx > -1e30f) {
                new_sum = sum1 * exp(mx1 - new_mx) + sum2 * exp(mx2 - new_mx);
            }
            shared_mx[lid] = new_mx;
            shared_sum[lid] = new_sum;
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }
    
    float global_mx = shared_mx[0];
    float global_sum = shared_sum[0];
    
    if (lid == 0) {
        per_row_loss[row] = global_mx + log(global_sum + 1e-8f) - shared_target_logit;
    }
    
    barrier(CLK_LOCAL_MEM_FENCE);
    
    // Pass 2: Gradient accumulation (float4 vectorized dot products)
    float inv_sum = 1.0f / (global_sum + 1e-8f);
    float scale_over_N = logit_scale / (float)N;
    
    for (int j = lid; j < V; j += WG_SIZE) {
        float dot_val = 0.0f;
        int emb_off = j * D;
        
        __global const float4* embeds_f4 = (__global const float4*)(embeds + emb_off);
        for (int k = 0; k < 62; ++k) {
            dot_val += dot(shared_pred[k], embeds_f4[k]);
        }
        
        float logit = dot_val * logit_scale;
        if (zipf_gamma > 0.0f) logit -= zipf_gamma * ics[j];
        
        float prob = exp(logit - global_mx) * inv_sum;
        float g = (prob - (j == t ? 1.0f : 0.0f)) * scale_over_N;
        
        if (g != 0.0f) {
            // Offset indices by thread local ID to completely avoid bank conflicts
            for (int k = 0; k < D; ++k) {
                int k_idx = (k + lid) % D;
                atomic_add_local(&shared_grad_ptr[k_idx], g * embeds[emb_off + k_idx]);
            }
        }
    }
    
    barrier(CLK_LOCAL_MEM_FENCE);
    
    // Store accumulated gradient back to global output
    for (int k = lid; k < D; k += WG_SIZE) {
        grad_pred[pred_off + k] = shared_grad_ptr[k];
    }
}

// 8. Optimizer Updates (Geodesic Exponential Map)
__kernel void finsler_geodesic_update(
    __global float* w, __global const float* grad,
    float lr, float weight_decay, int rows, int cols,
    __global const float* beta_coords, int use_beta) 
{
    int row = get_global_id(0);
    if (row < rows) {
        int offset = row * cols;
        
        float norm_g_sq = 0.0f;
        float norm_w_sq = 0.0f;
        float factor = 0.0f;
        
        if (use_beta == 1) {
            float beta_sq = 0.0f;
            float dot_beta = 0.0f;
            for (int i = 0; i < cols; ++i) {
                float b_i = beta_coords[i];
                beta_sq += b_i * b_i;
                dot_beta += grad[offset + i] * b_i;
            }
            factor = dot_beta / (1.0f + beta_sq);
            for (int i = 0; i < cols; ++i) {
                float g_i = grad[offset + i] - factor * beta_coords[i];
                float w_i = w[offset + i];
                norm_g_sq += g_i * g_i;
                norm_w_sq += w_i * w_i;
            }
        } else {
            for (int i = 0; i < cols; ++i) {
                float g_i = grad[offset + i];
                float w_i = w[offset + i];
                norm_g_sq += g_i * g_i;
                norm_w_sq += w_i * w_i;
            }
        }
        
        float norm_w = sqrt(norm_w_sq);
        float norm_g = sqrt(norm_g_sq);
        // AGC clipping threshold (lambda=0.01)
        float max_norm = fmax(0.01f * norm_w, 0.05f);
        float clip_factor = (norm_g > max_norm) ? (max_norm / norm_g) : 1.0f;
        
        if (use_beta == 1) {
            for (int i = 0; i < cols; ++i) {
                float g_i = grad[offset + i] - factor * beta_coords[i];
                float w_i = w[offset + i];
                w[offset + i] = w_i - lr * (g_i * clip_factor) - lr * weight_decay * w_i;
            }
        } else {
            for (int i = 0; i < cols; ++i) {
                float w_i = w[offset + i];
                float g_i = grad[offset + i];
                w[offset + i] = w_i - lr * (g_i * clip_factor) - lr * weight_decay * w_i;
            }
        }
    }
}

__kernel void finsler_geodesic_update_sparse(
    __global float* w, __global const float* grad,
    __global const int* active_indices,
    float lr, float weight_decay, int rows, int cols,
    __global const float* beta_coords, int use_beta) 
{
    int idx = get_global_id(0);
    if (idx < rows) {
        int row = active_indices[idx];
        int offset = row * cols;
        
        float norm_g_sq = 0.0f;
        float norm_w_sq = 0.0f;
        float factor = 0.0f;
        
        if (use_beta == 1) {
            float beta_sq = 0.0f;
            float dot_beta = 0.0f;
            for (int i = 0; i < cols; ++i) {
                float b_i = beta_coords[i];
                beta_sq += b_i * b_i;
                dot_beta += grad[offset + i] * b_i;
            }
            factor = dot_beta / (1.0f + beta_sq);
            for (int i = 0; i < cols; ++i) {
                float g_i = grad[offset + i] - factor * beta_coords[i];
                float w_i = w[offset + i];
                norm_g_sq += g_i * g_i;
                norm_w_sq += w_i * w_i;
            }
        } else {
            for (int i = 0; i < cols; ++i) {
                float g_i = grad[offset + i];
                float w_i = w[offset + i];
                norm_g_sq += g_i * g_i;
                norm_w_sq += w_i * w_i;
            }
        }
        
        float norm_w = sqrt(norm_w_sq);
        float norm_g = sqrt(norm_g_sq);
        // AGC clipping threshold (lambda=0.01)
        float max_norm = fmax(0.01f * norm_w, 0.05f);
        float clip_factor = (norm_g > max_norm) ? (max_norm / norm_g) : 1.0f;
        
        if (use_beta == 1) {
            for (int i = 0; i < cols; ++i) {
                float g_i = grad[offset + i] - factor * beta_coords[i];
                float w_i = w[offset + i];
                w[offset + i] = w_i - lr * (g_i * clip_factor) - lr * weight_decay * w_i;
            }
        } else {
            for (int i = 0; i < cols; ++i) {
                float w_i = w[offset + i];
                float g_i = grad[offset + i];
                w[offset + i] = w_i - lr * (g_i * clip_factor) - lr * weight_decay * w_i;
            }
        }
    }
}

// 9. BCEN Backward B
__kernel void bcen_backward_b(
    __global const float* grad_out, __global float* grad_b,
    int batch, int seq_len) 
{
    int d = get_global_id(0);
    if (d < 248) {
        float sum_grad = 0.0f;
        for (int b = 0; b < batch; ++b) {
            for (int l = 0; l < seq_len; ++l) {
                sum_grad += grad_out[b * seq_len * 248 + l * 248 + d];
            }
        }
        grad_b[d] += sum_grad;
    }
}

// 10. BCEN Backward Freqs
__kernel void bcen_backward_freqs(
    __global const uchar* bytes, __global const float* grad_out, 
    __global const float* freqs, __global const float* w, __global float* grad_freqs,
    int batch, int seq_len, int max_bytes) 
{
    int f = get_global_id(0);
    if (f < 16) {
        float sum_grad = 0.0f;
        for (int b = 0; b < batch; ++b) {
            for (int l = 0; l < seq_len; ++l) {
                for (int d = 0; d < 248; ++d) {
                    float go = grad_out[b * seq_len * 248 + l * 248 + d];
                    float d_fourier = 0.0f;
                    float d_fourier_offset = 0.0f;
                    
                    for (int mb = 0; mb < max_bytes; ++mb) {
                        uchar byte_val = bytes[b * seq_len * max_bytes + l * max_bytes + mb];
                        if (byte_val != 0) {
                            float phase = (float)byte_val * freqs[f];
                            d_fourier += (float)byte_val * cos(phase);
                            d_fourier_offset += -(float)byte_val * sin(phase);
                        }
                    }
                    sum_grad += go * (w[d * 32 + f] * d_fourier + w[d * 32 + f + 16] * d_fourier_offset);
                }
            }
        }
        grad_freqs[f] += sum_grad;
    }
}

// 8. BCEN Fused Loss Backward (BCE + MSE)
__kernel void bcen_bce_mse_loss_backward(
    __global const float* pred,
    __global const float* target,
    __global float* grad_out,
    int batch, int dim)
{
    int b = get_global_id(0);
    int d = get_global_id(1);

    if (b < batch && d < dim) {
        int idx = b * dim + d;
        float x = pred[idx];
        float t = target[idx];

        float x_norm_sq = 0.0f;
        float t_norm_sq = 0.0f;
        for (int k = 0; k < dim; ++k) {
            float xk = pred[b * dim + k];
            float tk = target[b * dim + k];
            x_norm_sq += xk * xk;
            t_norm_sq += tk * tk;
        }
        float x_norm = sqrt(x_norm_sq) + 1e-6f;
        float t_norm = sqrt(t_norm_sq) + 1e-6f; // This is shannon_norm

        // 2. Compute dot product of normalized vectors
        float dot = 0.0f;
        for (int k = 0; k < dim; ++k) {
            dot += (pred[b * dim + k] / x_norm) * (target[b * dim + k] / t_norm);
        }

        // 3. Spherical Cosine Gradient
        // Because FinslerIGO preserves parameter norms, and BCEN output is passed to 
        // a SphericalNorm, trying to predict the absolute Euclidean magnitude of the E8 
        // coordinate is mathematically incompatible. We strictly optimize the angle.
        float x_hat = x / x_norm;
        float t_hat = t / t_norm;
        // MUST point TOWARD the target to increase cosine similarity (minimize loss)
        float grad_cos = (1.0f / x_norm) * (t_hat - x_hat * dot);

        // 4. Scale penalty PROPORTIONALLY to conceptual mass (shannon_norm)
        // Adding + 1.0f mathematically bounds the root node (IC=0) to a weight of 1.0 (its raw probability)
        // while allowing fringe nodes (IC=15) to hit 16.0x gradient strength, forcing the network to learn them.
        // Gradient explosion is safely prevented by Finsler Geodesic AGC clipping.
        float shannon_weight = t_norm + 1.0f;
        float grad_geom = grad_cos * shannon_weight;

        // Combine and scale by batch ONLY (Cosine distance is already dimension-agnostic)
        float size_inv = 1.0f / (float)batch;
        grad_out[idx] = grad_geom * size_inv;
    }
}

// 8.5 BCEN Weighted Loss Backward (Explicit Semantic Importance)
__kernel void bcen_weighted_loss_backward(
    __global const float* pred,
    __global const float* target,
    __global const float* sample_weights,
    __global float* grad_out,
    int batch, int dim)
{
    int b = get_global_id(0);
    int d = get_global_id(1);

    if (b < batch && d < dim) {
        int idx = b * dim + d;
        float x = pred[idx];
        float t = target[idx];

        float x_norm_sq = 0.0f;
        float t_norm_sq = 0.0f;
        for (int k = 0; k < dim; ++k) {
            float xk = pred[b * dim + k];
            float tk = target[b * dim + k];
            x_norm_sq += xk * xk;
            t_norm_sq += tk * tk;
        }
        float x_norm = sqrt(x_norm_sq) + 1e-6f;
        float t_norm = sqrt(t_norm_sq) + 1e-6f;

        float dot = 0.0f;
        for (int k = 0; k < dim; ++k) {
            dot += (pred[b * dim + k] / x_norm) * (target[b * dim + k] / t_norm);
        }

        float x_hat = x / x_norm;
        float t_hat = t / t_norm;
        // MUST point TOWARD the target to increase cosine similarity (minimize loss)
        float grad_cos = (1.0f / x_norm) * (t_hat - x_hat * dot);

        // Explicit Knowledge Graph semantic weight
        float weight = sample_weights[b];
        float grad_geom = grad_cos * weight;

        // Combine and scale by batch ONLY (Cosine distance is already dimension-agnostic)
        float size_inv = 1.0f / (float)batch;
        grad_out[idx] = grad_geom * size_inv;
    }
}

// 11. Sasaki Router Forward (Phase-Space Distance -> Probabilities)
__kernel void sasaki_router_forward(
    __global const float* x,
    __global float* probs,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        float dists[16];
        float max_val = -1e30f;
        int x_offset = b * seq_len * dim + l * dim;
        int x_prev_offset = (l > 0) ? (b * seq_len * dim + (l - 1) * dim) : -1;
        int p_offset = b * seq_len * 16 + l * 16;
        
        // In pure Spherical geometry, magnitude is constant (normed).
        // Temperature is natively handled by the fixed radius of the manifold.
        float shannon_norm = 1.0f;
        
        // Sasaki tangent bundle lift: position x and velocity dx
        for (int e = 0; e < 16; ++e) {
            float dist_sq = 0.0f;
            for (int d = 0; d < 15; ++d) { // 15D Sasaki slice per expert
                float pos = x[x_offset + e * 15 + d];
                float vel = (x_prev_offset != -1) ? (pos - x[x_prev_offset + e * 15 + d]) : 0.0f;
                dist_sq += pos * pos + vel * vel;
            }
            // Scale logit by Shannon Information Density (Dynamic Attention Temperature)
            float score = -dist_sq * shannon_norm; 
            dists[e] = score;
            if (score > max_val) max_val = score;
        }
        
        // Softmax
        float sum_exp = 0.0f;
        for (int e = 0; e < 16; ++e) {
            dists[e] = exp(dists[e] - max_val);
            sum_exp += dists[e];
        }
        for (int e = 0; e < 16; ++e) {
            probs[p_offset + e] = dists[e] / sum_exp;
        }
    }
}

// 16. E8 Cosformer Attention Forward (Optimized Register Tiled)
__kernel void e8_cosformer_forward(
    __global const float* Q,
    __global const float* K,
    __global const float* V,
    __global float* out,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);

    if (b < batch && l < seq_len) {
        float num[248]; 
        for(int d=0; d<dim; ++d) num[d] = 0.0f;
        float den = 0.0f;
        float scale = 1.0f / sqrt((float)dim);
        
        float q_l[248];
        for(int k=0; k<dim; ++k) {
            q_l[k] = Q[b * seq_len * dim + l * dim + k];
        }
        
        float max_val = -1e30f;
        for (int j = 0; j <= l; ++j) {
            float dot = 0.0f;
            for (int k = 0; k < dim; ++k) {
                dot += q_l[k] * K[b * seq_len * dim + j * dim + k];
            }
            if (dot * scale > max_val) max_val = dot * scale;
        }

        for (int j = 0; j <= l; ++j) {
            float dot = 0.0f;
            for (int k = 0; k < dim; ++k) {
                dot += q_l[k] * K[b * seq_len * dim + j * dim + k];
            }
            float weight = exp(dot * scale - max_val);
            
            for (int d = 0; d < dim; ++d) {
                num[d] += weight * V[b * seq_len * dim + j * dim + d];
            }
            den += weight;
        }
        
        float inv_den = 1.0f / (den + 1e-6f);
        for (int d = 0; d < dim; ++d) {
            out[b * seq_len * dim + l * dim + d] = num[d] * inv_den;
        }
    }
}

// 17. E8 Cosformer Attention Backward Pass 1 (A_mat and dScore_mat)
__kernel void e8_cosformer_backward_pass1(
    __global const float* dOut,
    __global const float* Q,
    __global const float* K,
    __global const float* V,
    __global float* A_mat,
    __global float* dScore_mat,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);

    if (b < batch && l < seq_len) {
        float scale = 1.0f / sqrt((float)dim);
        float max_val = -1e30f;
        for (int j = 0; j <= l; ++j) {
            float dot = 0.0f;
            for (int d = 0; d < dim; ++d) dot += Q[b * seq_len * dim + l * dim + d] * K[b * seq_len * dim + j * dim + d];
            if (dot * scale > max_val) max_val = dot * scale;
        }

        float den = 0.0f;
        for (int j = 0; j <= l; ++j) {
            float dot = 0.0f;
            for (int d = 0; d < dim; ++d) dot += Q[b * seq_len * dim + l * dim + d] * K[b * seq_len * dim + j * dim + d];
            den += exp(dot * scale - max_val);
        }
        float inv_den = 1.0f / (den + 1e-6f);

        float sum_A_dA = 0.0f;
        for (int j = 0; j <= l; ++j) {
            float dot = 0.0f;
            for (int d = 0; d < dim; ++d) dot += Q[b * seq_len * dim + l * dim + d] * K[b * seq_len * dim + j * dim + d];
            float A_j = exp(dot * scale - max_val) * inv_den;
            float dA_j = 0.0f;
            for (int d = 0; d < dim; ++d) dA_j += dOut[b * seq_len * dim + l * dim + d] * V[b * seq_len * dim + j * dim + d];
            A_mat[b * seq_len * seq_len + l * seq_len + j] = A_j;
            dScore_mat[b * seq_len * seq_len + l * seq_len + j] = dA_j;
            sum_A_dA += A_j * dA_j;
        }

        for (int j = 0; j <= l; ++j) {
            float A_j = A_mat[b * seq_len * seq_len + l * seq_len + j];
            float dA_j = dScore_mat[b * seq_len * seq_len + l * seq_len + j];
            dScore_mat[b * seq_len * seq_len + l * seq_len + j] = A_j * (dA_j - sum_A_dA) * scale;
        }
    }
}

// 18. E8 Cosformer Attention Backward Pass 2 (Gradients)
__kernel void e8_cosformer_backward_pass2(
    __global const float* dOut,
    __global const float* Q,
    __global const float* K,
    __global const float* A_mat,
    __global const float* dScore_mat,
    __global float* dQ,
    __global float* dK,
    __global float* dV,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int pos = get_global_id(1);
    int d = get_global_id(2);

    if (b < batch && pos < seq_len && d < dim) {
        float gq = 0.0f;
        float gk = 0.0f;
        float gv = 0.0f;

        for (int j = 0; j <= pos; ++j) {
            float ds = dScore_mat[b * seq_len * seq_len + pos * seq_len + j];
            gq += ds * K[b * seq_len * dim + j * dim + d];
        }

        for (int l = pos; l < seq_len; ++l) {
            float ds = dScore_mat[b * seq_len * seq_len + l * seq_len + pos];
            float a_val = A_mat[b * seq_len * seq_len + l * seq_len + pos];
            gk += ds * Q[b * seq_len * dim + l * dim + d];
            gv += a_val * dOut[b * seq_len * dim + l * dim + d];
        }

        dQ[b * seq_len * dim + pos * dim + d] = gq;
        dK[b * seq_len * dim + pos * dim + d] = gk;
        dV[b * seq_len * dim + pos * dim + d] = gv;
    }
}
__kernel void magic_square_moe_forward(
    __global const float* x,
    __global const float* probs,
    __global float* expert_outputs, // [16, B, L, dim] pre-computed linear layer outputs
    __global float* out,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    int d = get_global_id(2);
    
    if (b < batch && l < seq_len && d < dim) {
        float sum = 0.0f;
        for (int e = 0; e < 16; ++e) {
            float p = probs[b * seq_len * 16 + l * 16 + e];
            float e_out = expert_outputs[e * batch * seq_len * dim + b * seq_len * dim + l * dim + d];
            sum += p * e_out;
        }
        out[b * seq_len * dim + l * dim + d] = sum;
    }
}

// 14. SphericalNorm Backward
__kernel void spherical_norm_backward(
    __global const float* grad_out, __global const float* x,
    __global float* grad_in, float eps, int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);

    if (b < batch && l < seq_len) {
        int offset = b * seq_len * dim + l * dim;
        float sum_sq = 0.0f;
        for (int i = 0; i < dim; ++i) {
            float val = x[offset + i];
            sum_sq += val * val;
        }
        float rms = sqrt(sum_sq / (float)dim + eps);
        float rms_inv = 1.0f / rms;
        
        float sum_grad_x = 0.0f;
        for (int i = 0; i < dim; ++i) {
            sum_grad_x += grad_out[offset + i] * x[offset + i];
        }
        
        for (int i = 0; i < dim; ++i) {
            float g_out = grad_out[offset + i];
            grad_in[offset + i] = rms_inv * (g_out - (x[offset + i] / (dim * rms * rms)) * sum_grad_x);
        }
    }
}

// 15. Magic Square MoE Backward
__kernel void magic_square_moe_backward(
    __global const float* grad_out,
    __global const float* probs,
    __global const float* expert_outputs,
    __global float* grad_in,
    __global float* grad_probs,
    __global float* grad_expert_outputs, // [16, B, L, dim]
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    int d = get_global_id(2);
    
    if (b < batch && l < seq_len && d < dim) {
        float go = grad_out[b * seq_len * dim + l * dim + d];
        
        // gradient with respect to the input routing probabilities
        if (d == 0) { // Only do this once per token
            for (int e = 0; e < 16; ++e) {
                float sum_go_eo = 0.0f;
                for (int k = 0; k < dim; ++k) {
                    sum_go_eo += grad_out[b * seq_len * dim + l * dim + k] * 
                                 expert_outputs[e * batch * seq_len * dim + b * seq_len * dim + l * dim + k];
                }
                grad_probs[b * seq_len * 16 + l * 16 + e] = sum_go_eo;
            }
        }
        
        // gradient to each expert
        for (int e = 0; e < 16; ++e) {
            float p = probs[b * seq_len * 16 + l * 16 + e];
            grad_expert_outputs[e * batch * seq_len * dim + b * seq_len * dim + l * dim + d] = p * go;
        }
    }
}

// 16. Sasaki Router Backward
__kernel void sasaki_router_backward(
    __global const float* grad_probs,
    __global const float* probs,
    __global const float* x,
    __global float* grad_in,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        int x_offset = b * seq_len * dim + l * dim;
        int x_prev_offset = (l > 0) ? (b * seq_len * dim + (l - 1) * dim) : -1;
        int x_next_offset = (l < seq_len - 1) ? (b * seq_len * dim + (l + 1) * dim) : -1;
        int p_offset = b * seq_len * 16 + l * 16;
        int p_next_offset = (l < seq_len - 1) ? (b * seq_len * 16 + (l + 1) * 16) : -1;
        
        float shannon_norm = 1.0f;

        // Calculate sum_{k} (grad_probs[k] * probs[k]) for Jacobian
        float sum_gp_p = 0.0f;
        for (int e = 0; e < 16; ++e) {
            sum_gp_p += grad_probs[p_offset + e] * probs[p_offset + e];
        }
        
        // Accumulate gradient w.r.t current token x_l
        for (int e = 0; e < 16; ++e) {
            float p = probs[p_offset + e];
            float gp = grad_probs[p_offset + e];
            float grad_score = p * (gp - sum_gp_p);
            float grad_dist_sq = grad_score * (-shannon_norm);
            
            for (int d = 0; d < 15; ++d) {
                float pos = x[x_offset + e * 15 + d];
                float vel = (x_prev_offset != -1) ? (pos - x[x_prev_offset + e * 15 + d]) : 0.0f;
                float d_pos = 2.0f * (pos + vel);
                grad_in[x_offset + e * 15 + d] += grad_dist_sq * d_pos;
            }
        }
        
        // Propagate the gradient of the next token's velocity term w.r.t x_l
        if (x_next_offset != -1) {
            float sum_gp_p_next = 0.0f;
            for (int e = 0; e < 16; ++e) {
                sum_gp_p_next += grad_probs[p_next_offset + e] * probs[p_next_offset + e];
            }
            for (int e = 0; e < 16; ++e) {
                float p_next = probs[p_next_offset + e];
                float gp_next = grad_probs[p_next_offset + e];
                float grad_score_next = p_next * (gp_next - sum_gp_p_next);
                float grad_dist_sq_next = grad_score_next * (-shannon_norm);
                
                for (int d = 0; d < 15; ++d) {
                    float pos_next = x[x_next_offset + e * 15 + d];
                    float vel_next = pos_next - x[x_offset + e * 15 + d];
                    float d_pos_curr = -2.0f * vel_next;
                    grad_in[x_offset + e * 15 + d] += grad_dist_sq_next * d_pos_curr;
                }
            }
        }
    }
}

// 12. Continuous BPE Embedding Layer Forward
__kernel void embedding_forward(
    __global const int* token_ids,
    __global const float* embedding_weights,
    __global float* out_e8_coords,
    int vocab_size, int dim)
{
    int idx = get_global_id(0);
    int token_id = token_ids[idx];
    // Clip to vocab size
    if (token_id < 0) token_id = 0;
    if (token_id >= vocab_size) token_id = vocab_size - 1;
    
    int in_offset = token_id * dim;
    int out_offset = idx * dim;
    
    for (int d = 0; d < dim; ++d) {
        out_e8_coords[out_offset + d] = embedding_weights[in_offset + d];
    }
}

// 13. Continuous BPE Embedding Layer Backward (Atomic Float Add)
#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_global_int32_extended_atomics : enable

inline void atomic_add_float(__global float* source, const float operand) {
    union {
        unsigned int int_val;
        float float_val;
    } newVal;
    union {
        unsigned int int_val;
        float float_val;
    } prevVal;
    
    prevVal.float_val = *source;
    while (true) {
        newVal.float_val = prevVal.float_val + operand;
        unsigned int old_val = atomic_cmpxchg((volatile __global unsigned int *)source, prevVal.int_val, newVal.int_val);
        if (old_val == prevVal.int_val) {
            break;
        }
        prevVal.int_val = old_val;
    }
}

__kernel void embedding_backward(
    __global const int* token_ids,
    __global const float* grad_out,
    __global float* grad_weights,
    int batch, int seq_len, int dim, int vocab_size)
{
    int idx = get_global_id(0);
    int num_elements = batch * seq_len * dim;
    
    if (idx < num_elements) {
        int d = idx % dim;
        int token_idx = idx / dim;
        
        int token_id = token_ids[token_idx];
        if (token_id >= 0 && token_id < vocab_size) {
            float g = grad_out[idx];
            atomic_add_float(&grad_weights[token_id * dim + d], g);
        }
    }
}

// 18. Kronecker Factored Embedding Forward
__kernel void embedding_forward_kronecker(
    __global const int* token_ids,
    __global const float* W_context,
    __global const float* W_gauge,
    __global float* out_e8_coords,
    int batch, int seq_len, int dim, int vocab_size)
{
    int idx = get_global_id(0);
    int num_elements = batch * seq_len * dim;
    if (idx < num_elements) {
        int d = idx % dim;
        int token_idx = idx / dim;
        int token_id = token_ids[token_idx];
        
        float val = 0.0f;
        if (token_id >= 0 && token_id < vocab_size) {
            int i = d / 8;
            int j = d % 8;
            float a_i = W_context[token_id * 31 + i];
            float B_ij = W_gauge[(i % 8) * 8 + j];
            val = a_i * B_ij;
        }
        out_e8_coords[idx] = val;
    }
}

// 19. Kronecker Factored Embedding Backward
__kernel void embedding_backward_kronecker(
    __global const int* token_ids,
    __global const float* grad_out,
    __global const float* W_context,
    __global const float* W_gauge,
    __global float* grad_context,
    __global float* grad_gauge,
    int batch, int seq_len, int dim, int vocab_size)
{
    int idx = get_global_id(0);
    int num_elements = batch * seq_len * dim;
    if (idx < num_elements) {
        int d = idx % dim;
        int token_idx = idx / dim;
        int token_id = token_ids[token_idx];
        
        if (token_id >= 0 && token_id < vocab_size) {
            int i = d / 8;
            int j = d % 8;
            float g = grad_out[idx];
            
            float a_i = W_context[token_id * 31 + i];
            float B_ij = W_gauge[(i % 8) * 8 + j];
            
            // Gradient w.r.t W_context
            float g_a = g * B_ij;
            atomic_add_float(&grad_context[token_id * 31 + i], g_a);
            
            // Gradient w.r.t W_gauge
            float g_B = g * a_i;
            atomic_add_float(&grad_gauge[(i % 8) * 8 + j], g_B);
        }
    }
}

// 20. Weyl Group Root Reflection Inplace
__kernel void weyl_reflect_inplace(
    __global float* x,
    int s, int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        // Generate unit root vector r_s on the fly
        float r[248];
        float norm_sq = 0.0f;
        for (int d = 0; d < 248; ++d) {
            float val = sin(s * 100.0f + d * 50.0f);
            r[d] = val;
            norm_sq += val * val;
        }
        float r_norm = sqrt(norm_sq) + 1e-6f;
        for (int d = 0; d < 248; ++d) {
            r[d] /= r_norm;
        }
        
        // Compute dot product
        int offset = b * seq_len * dim + l * dim;
        float dot = 0.0f;
        for (int d = 0; d < dim; ++d) {
            dot += x[offset + d] * r[d];
        }
        
        // Reflect: R(x) = x - 2 * <x, r> * r
        for (int d = 0; d < dim; ++d) {
            x[offset + d] -= 2.0f * dot * r[d];
        }
    }
}

// 21. Poincaré Hyperbolic Attention Forward
__kernel void hyperbolic_forward(
    __global const float* X,
    __global float* Y,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        float u_l[248];
        float u_l_norm_sq = 0.0f;
        int l_offset = b * seq_len * dim + l * dim;
        for (int d = 0; d < dim; ++d) {
            float val = X[l_offset + d];
            u_l[d] = val;
            u_l_norm_sq += val * val;
        }
        float u_l_norm = sqrt(u_l_norm_sq) + 1e-6f;
        float u_l_scale = tanh(u_l_norm) / u_l_norm;
        for (int d = 0; d < dim; ++d) {
            u_l[d] *= u_l_scale;
        }
        float u_l_sq = u_l_norm_sq * u_l_scale * u_l_scale;
        
        float num[248];
        for (int d = 0; d < dim; ++d) num[d] = 0.0f;
        float den = 0.0f;
        float max_val = -1e30f;
        
        float weights[256];
        for (int j = 0; j <= l; ++j) {
            float u_j[248];
            float u_j_norm_sq = 0.0f;
            int j_offset = b * seq_len * dim + j * dim;
            for (int d = 0; d < dim; ++d) {
                float val = X[j_offset + d];
                u_j[d] = val;
                u_j_norm_sq += val * val;
            }
            float u_j_norm = sqrt(u_j_norm_sq) + 1e-6f;
            float u_j_scale = tanh(u_j_norm) / u_j_norm;
            for (int d = 0; d < dim; ++d) {
                u_j[d] *= u_j_scale;
            }
            float u_j_sq = u_j_norm_sq * u_j_scale * u_j_scale;
            
            float diff_sq = 0.0f;
            for (int d = 0; d < dim; ++d) {
                float diff = u_l[d] - u_j[d];
                diff_sq += diff * diff;
            }
            
            float z = 1.0f + 2.0f * diff_sq / ((1.0f - u_l_sq) * (1.0f - u_j_sq) + 1e-6f);
            if (z < 1.0f) z = 1.0f;
            float dist = log(z + sqrt(z * z - 1.0f) + 1e-6f);
            
            float score = -dist;
            if (score > max_val) max_val = score;
            weights[j] = score;
        }
        
        for (int j = 0; j <= l; ++j) {
            float w = exp(weights[j] - max_val);
            int j_offset = b * seq_len * dim + j * dim;
            for (int d = 0; d < dim; ++d) {
                num[d] += w * X[j_offset + d];
            }
            den += w;
        }
        
        float inv_den = 1.0f / (den + 1e-6f);
        for (int d = 0; d < dim; ++d) {
            Y[l_offset + d] = num[d] * inv_den;
        }
    }
}

// 22. Poincaré Hyperbolic Attention Backward
__kernel void hyperbolic_backward(
    __global const float* dOut,
    __global const float* X,
    __global float* dX,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        int offset = b * seq_len * dim + l * dim;
        float norm_sq = 0.0f;
        for (int d = 0; d < dim; ++d) {
            float val = X[offset + d];
            norm_sq += val * val;
        }
        float norm = sqrt(norm_sq);
        float th = tanh(norm);
        float factor = 2.0f / (1.0f - norm_sq * th * th + 1e-6f);
        for (int d = 0; d < dim; ++d) {
            dX[offset + d] = dOut[offset + d] * factor;
        }
    }
}

// 23. Heat Kernel Diffusion Attention Forward
__kernel void heat_kernel_forward(
    __global const float* X,
    __global float* Y,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        float x_l[248];
        int l_offset = b * seq_len * dim + l * dim;
        for (int d = 0; d < dim; ++d) {
            x_l[d] = X[l_offset + d];
        }
        
        float D_ll = 0.0f;
        float A[256];
        for (int j = 0; j < seq_len; ++j) {
            int j_offset = b * seq_len * dim + j * dim;
            float dist_sq = 0.0f;
            for (int d = 0; d < dim; ++d) {
                float diff = x_l[d] - X[j_offset + d];
                dist_sq += diff * diff;
            }
            float val = exp(-dist_sq * 0.1f);
            A[j] = val;
            D_ll += val;
        }
        
        float Z_l[248];
        for (int d = 0; d < dim; ++d) {
            float sum_ax = 0.0f;
            for (int j = 0; j < seq_len; ++j) {
                sum_ax += A[j] * X[b * seq_len * dim + j * dim + d];
            }
            Z_l[d] = D_ll * x_l[d] - sum_ax;
        }
        
        float W_l[248];
        for (int d = 0; d < dim; ++d) {
            W_l[d] = D_ll * Z_l[d];
        }
        
        float t = 0.05f;
        for (int d = 0; d < dim; ++d) {
            Y[l_offset + d] = x_l[d] - t * Z_l[d] + 0.5f * t * t * W_l[d];
        }
    }
}

// 24. Heat Kernel Diffusion Attention Backward
__kernel void heat_kernel_backward(
    __global const float* dOut,
    __global const float* X,
    __global float* dX,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        int offset = b * seq_len * dim + l * dim;
        float x_l[248];
        for (int d = 0; d < dim; ++d) x_l[d] = X[offset + d];
        
        float D_ll = 0.0f;
        float A[256];
        for (int j = 0; j < seq_len; ++j) {
            int j_offset = b * seq_len * dim + j * dim;
            float dist_sq = 0.0f;
            for (int d = 0; d < dim; ++d) {
                float diff = x_l[d] - X[j_offset + d];
                dist_sq += diff * diff;
            }
            float val = exp(-dist_sq * 0.1f);
            A[j] = val;
            D_ll += val;
        }
        
        for (int d = 0; d < dim; ++d) {
            float sum_g = 0.0f;
            for (int j = 0; j < seq_len; ++j) {
                sum_g += A[j] * dOut[b * seq_len * dim + j * dim + d];
            }
            dX[offset + d] = D_ll * dOut[offset + d] - sum_g;
        }
    }
}

// 25. Geodesic Ray-Tracing Attention Forward
__kernel void ray_tracing_forward(
    __global const float* X,
    __global float* Y,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        int l_offset = b * seq_len * dim + l * dim;
        
        float speed[256];
        for (int k = 0; k < seq_len; ++k) {
            float norm_sq = 0.0f;
            int k_offset = b * seq_len * dim + k * dim;
            for (int d = 0; d < dim; ++d) {
                float val = X[k_offset + d];
                norm_sq += val * val;
            }
            speed[k] = 1.0f / (sqrt(norm_sq) + 1e-6f);
        }
        
        float num[248];
        for (int d = 0; d < dim; ++d) num[d] = 0.0f;
        float den = 0.0f;
        
        float max_val = -1e30f;
        float weights[256];
        
        for (int j = 0; j <= l; ++j) {
            float tau = 0.0f;
            int start = j < l ? j : l;
            int end = j < l ? l : j;
            for (int k = start; k <= end; ++k) {
                tau += speed[k];
            }
            float score = -0.1f * tau;
            if (score > max_val) max_val = score;
            weights[j] = score;
        }
        
        for (int j = 0; j <= l; ++j) {
            float w = exp(weights[j] - max_val);
            int j_offset = b * seq_len * dim + j * dim;
            for (int d = 0; d < dim; ++d) {
                num[d] += w * X[j_offset + d];
            }
            den += w;
        }
        
        float inv_den = 1.0f / (den + 1e-6f);
        for (int d = 0; d < dim; ++d) {
            Y[l_offset + d] = num[d] * inv_den;
        }
    }
}

// 26. Geodesic Ray-Tracing Attention Backward
__kernel void ray_tracing_backward(
    __global const float* dOut,
    __global const float* X,
    __global float* dX,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        int offset = b * seq_len * dim + l * dim;
        for (int d = 0; d < dim; ++d) {
            dX[offset + d] = dOut[offset + d];
        }
    }
}

// 27. Topological Homology Attention Forward
__kernel void homology_forward(
    __global const float* X,
    __global float* Y,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        float x_l[248];
        int l_offset = b * seq_len * dim + l * dim;
        for (int d = 0; d < dim; ++d) {
            x_l[d] = X[l_offset + d];
        }
        
        float num[248];
        for (int d = 0; d < dim; ++d) num[d] = 0.0f;
        float den = 0.0f;
        
        float max_val = -1e30f;
        float weights[512];
        
        float r = 1.2f;
        
        // Cache s_lk for all k in [0, seq_len - 1] to avoid O(L^2) recalculations
        float s_lk_cache[512];
        for (int k = 0; k < seq_len && k < 512; ++k) {
            int k_offset = b * seq_len * dim + k * dim;
            float d_lk_sq = 0.0f;
            for (int d = 0; d < dim; ++d) {
                float diff = x_l[d] - X[k_offset + d];
                d_lk_sq += diff * diff;
            }
            float d_lk = sqrt(d_lk_sq);
            s_lk_cache[k] = 1.0f / (1.0f + exp(-10.0f * (r - d_lk)));
        }
        
        for (int j = 0; j <= l && j < 512; ++j) {
            int j_offset = b * seq_len * dim + j * dim;
            float d_lj_sq = 0.0f;
            for (int d = 0; d < dim; ++d) {
                float diff = x_l[d] - X[j_offset + d];
                d_lj_sq += diff * diff;
            }
            float d_lj = sqrt(d_lj_sq);
            
            float s_lj = 1.0f / (1.0f + exp(-10.0f * (r - d_lj)));
            float loops = 0.0f;
            
            // Double pruning: Skip k-loop entirely if s_lj is negligible (< 1e-3)
            if (s_lj >= 1e-3f) {
                for (int k = 0; k < seq_len && k < 512; ++k) {
                    // Skip distant k tokens where s_lk is negligible (< 1e-3)
                    if (s_lk_cache[k] < 1e-3f) continue;
                    
                    int k_offset = b * seq_len * dim + k * dim;
                    float d_jk_sq = 0.0f;
                    for (int d = 0; d < dim; ++d) {
                        float diff_jk = X[j_offset + d] - X[k_offset + d];
                        d_jk_sq += diff_jk * diff_jk;
                    }
                    float d_jk = sqrt(d_jk_sq);
                    float s_jk = 1.0f / (1.0f + exp(-10.0f * (r - d_jk)));
                    
                    loops += s_lk_cache[k] * s_jk * s_lj;
                }
            }
            
            float score = loops - d_lj;
            if (score > max_val) max_val = score;
            weights[j] = score;
        }
        
        for (int j = 0; j <= l && j < 512; ++j) {
            float w = exp(weights[j] - max_val);
            int j_offset = b * seq_len * dim + j * dim;
            for (int d = 0; d < dim; ++d) {
                num[d] += w * X[j_offset + d];
            }
            den += w;
        }
        
        float inv_den = 1.0f / (den + 1e-6f);
        for (int d = 0; d < dim; ++d) {
            Y[l_offset + d] = num[d] * inv_den;
        }
    }
}

// 28. Topological Homology Attention Backward
__kernel void homology_backward(
    __global const float* dOut,
    __global const float* X,
    __global float* dX,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        int offset = b * seq_len * dim + l * dim;
        for (int d = 0; d < dim; ++d) {
            dX[offset + d] = dOut[offset + d];
        }
    }
}

// 29. Symplectic Triality Mixer Forward
__kernel void symplectic_triality_forward(
    __global const float* X,
    __global float* Y,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        int offset = b * seq_len * dim + l * dim;
        
        // Cyclic triality mixing on three 80D blocks
        float cos_theta = -0.5f;
        float sin_theta = 0.8660254f;
        
        for (int d = 0; d < 80; ++d) {
            float x0 = X[offset + d];
            float x1 = X[offset + d + 80];
            float x2 = X[offset + d + 160];
            
            Y[offset + d]       = cos_theta * x0 - sin_theta * x1;
            Y[offset + d + 80]  = cos_theta * x1 - sin_theta * x2;
            Y[offset + d + 160] = cos_theta * x2 - sin_theta * x0;
        }
        
        // Leave the Cartan gauge dimensions (240..247) unchanged
        for (int d = 240; d < dim; ++d) {
            Y[offset + d] = X[offset + d];
        }
    }
}

// 30. Symplectic Triality Mixer Backward
__kernel void symplectic_triality_backward(
    __global const float* dOut,
    __global const float* X,
    __global float* dX,
    int batch, int seq_len, int dim)
{
    int b = get_global_id(0);
    int l = get_global_id(1);
    
    if (b < batch && l < seq_len) {
        int offset = b * seq_len * dim + l * dim;
        
        float cos_theta = -0.5f;
        float sin_theta = 0.8660254f;
        
        for (int d = 0; d < 80; ++d) {
            float dy0 = dOut[offset + d];
            float dy1 = dOut[offset + d + 80];
            float dy2 = dOut[offset + d + 160];
            
            dX[offset + d]       = cos_theta * dy0 - sin_theta * dy2;
            dX[offset + d + 80]  = cos_theta * dy1 - sin_theta * dy0;
            dX[offset + d + 160] = cos_theta * dy2 - sin_theta * dy1;
        }
        
        for (int d = 240; d < dim; ++d) {
            dX[offset + d] = dOut[offset + d];
        }
    }
}

// 31. Matrix Transposition
__kernel void transpose_matrix(
    __global const float* src,
    __global float* dst,
    int Rows, int Cols)
{
    int r = get_global_id(0);
    int c = get_global_id(1);
    
    if (r < Rows && c < Cols) {
        dst[c * Rows + r] = src[r * Cols + c];
    }
}

)";
