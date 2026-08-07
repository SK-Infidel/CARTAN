#include <torch/extension.h>
#include <vector>

// Forward pass for E8 Lie Bracket SSM
// Computes the sequential state updates entirely in C++ to avoid Python loop overhead.
torch::Tensor e8_ssm_forward(
    torch::Tensor x,
    torch::Tensor h_init,
    torch::Tensor drift_vecs,
    torch::Tensor W_x_weight,
    torch::Tensor W_y_weight,
    torch::Tensor W_out_weight,
    torch::Tensor norm_weight,
    torch::Tensor norm_bias) {

    // Ensure all tensors are handled by the same dispatcher
    at::NoGradGuard no_grad;
    
    auto batch_size = x.size(0);
    auto seq_len = x.size(1);
    auto dim = x.size(2);
    auto rank = W_x_weight.size(0);
    auto device = x.device();

    // Pre-transpose weights once to avoid O(L) view overhead inside the loop
    auto W_x_t = W_x_weight.t();
    auto W_y_t = W_y_weight.t();
    auto W_out_t = W_out_weight.t();

    // Batch L linear transforms into 1 GEMM
    auto proj_x_x = torch::matmul(x, W_x_t);
    auto proj_y_x = torch::matmul(x, W_y_t);

    // Pre-allocate buffers for intermediate vector results to avoid allocations in the loop
    auto proj_x_h = torch::empty({batch_size, rank}, x.options());
    auto proj_y_h = torch::empty({batch_size, rank}, x.options());

    auto h_t = h_init.clone();
    std::vector<torch::Tensor> states;
    states.reserve(seq_len);

    for (int64_t t = 0; t < seq_len; ++t) {
        auto x_t = x.select(1, t);
        auto px_t = proj_x_x.select(1, t);
        auto py_t = proj_y_x.select(1, t);
        auto drift_t = drift_vecs.select(1, t);

        at::mm_out(proj_x_h, h_t, W_x_t);
        at::mm_out(proj_y_h, h_t, W_y_t);

        // Commutator: [X, Y] = XY - YX
        auto comm = (px_t * proj_y_h) - (proj_x_h * py_t);
        auto divergence = torch::matmul(comm, W_out_t);

        // Randers-Sasaki state update with LayerNorm
        // h_t = tanh(norm(h_t + divergence + drift_t + x_t))
        auto combined = h_t + divergence + drift_t + x_t;
        h_t = torch::tanh(torch::layer_norm(combined, {dim}, norm_weight, norm_bias, 1e-5));

        states.push_back(h_t);
    }
    return torch::stack(states, 1);
}

// Bind the C++ function to Python
PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
    m.def("forward", &e8_ssm_forward, "E8 Lie Bracket SSM Forward Pass");
}
