// src/cartanc/cartan_cuda_kernels.cu
// Native CUDA 13.2 GPU Acceleration Engine for CARTAN & GeoMind models
// Target Device: NVIDIA RTX 2000 Ada Generation (8GB VRAM)

#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

extern "C" {

// GPU Device Memory Pointers
static float* d_weights = NULL;
static float* d_hidden = NULL;
static float* d_logits = NULL;
static float* d_probs = NULL;
static int g_cuda_init = 0;

// CUDA Kernel: Vector-Matrix Multiplication (Hidden Vector * Weight Matrix -> Logits)
__global__ void k_vec_matmul_f32(const float* __restrict__ hidden, const float* __restrict__ weights, float* __restrict__ logits, int M, int N) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (col < N) {
        float sum = 0.0f;
        for (int r = 0; r < M; r++) {
            sum += hidden[r] * weights[r * N + col];
        }
        logits[col] = sum;
    }
}

// CUDA Kernel: Softmax + Cross-Entropy Gradient Backprop Update
__global__ void k_sgd_update_f32(float* __restrict__ weights, const float* __restrict__ hidden, const float* __restrict__ probs, int target_idx, float lr, int M, int N) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < M && col < N) {
        float target = (col == target_idx) ? 1.0f : 0.0f;
        float grad = (probs[col] - target) * hidden[row];
        weights[row * N + col] -= lr * grad;
    }
}

void cartan_cuda_init_if_needed(int M, int N) {
    if (g_cuda_init) return;
    cudaSetDevice(0);
    cudaMalloc((void**)&d_weights, sizeof(float) * M * N);
    cudaMalloc((void**)&d_hidden, sizeof(float) * M);
    cudaMalloc((void**)&d_logits, sizeof(float) * N);
    cudaMalloc((void**)&d_probs, sizeof(float) * N);
    cudaMemset(d_weights, 0, sizeof(float) * M * N);
    g_cuda_init = 1;
    printf("[GeoMind CUDA] Initialized CUDA 13.2 GPU Accelerator on NVIDIA RTX 2000 Ada (%d x %d matrix).\n", M, N);
}

double cartan_cuda_train_step_f32(const float* h_hidden, int target_idx, float lr, int M, int N) {
    cartan_cuda_init_if_needed(M, N);
    if (!h_hidden) return 0.0;

    // Copy hidden state vector to GPU VRAM
    cudaMemcpy(d_hidden, h_hidden, sizeof(float) * M, cudaMemcpyHostToDevice);

    // Grid Dimensions
    int threads_x = 256;
    int blocks_x = (N + threads_x - 1) / threads_x;
    
    // Launch CUDA Matmul Kernel on RTX 2000 Ada GPU
    k_vec_matmul_f32<<<blocks_x, threads_x>>>(d_hidden, d_weights, d_logits, M, N);
    cudaDeviceSynchronize();

    // Copy Logits back to Host for Softmax & Loss calculation
    float* h_logits = (float*)malloc(sizeof(float) * N);
    float max_l = -1e9f;
    cudaMemcpy(h_logits, d_logits, sizeof(float) * N, cudaMemcpyDeviceToHost);

    for (int c = 0; c < N; c++) {
        if (h_logits[c] > max_l) max_l = h_logits[c];
    }

    double sum_e = 0.0;
    float* h_probs = (float*)malloc(sizeof(float) * N);
    for (int c = 0; c < N; c++) {
        h_probs[c] = expf(h_logits[c] - max_l);
        sum_e += (double)h_probs[c];
    }
    if (sum_e <= 0.0) sum_e = 1.0;
    for (int c = 0; c < N; c++) h_probs[c] /= (float)sum_e;

    double loss = -log(h_probs[target_idx] > 1e-12f ? (double)h_probs[target_idx] : 1e-12);

    if (lr > 0.0f) {
        cudaMemcpy(d_probs, h_probs, sizeof(float) * N, cudaMemcpyHostToDevice);
        dim3 block(16, 16);
        dim3 grid((N + 15) / 16, (M + 15) / 16);
        k_sgd_update_f32<<<grid, block>>>(d_weights, d_hidden, d_probs, target_idx, lr, M, N);
        cudaDeviceSynchronize();
    }

    free(h_logits);
    free(h_probs);
    return loss;
}

} // extern "C"
