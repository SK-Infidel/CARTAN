#pragma once

#include "tensor.h"
#include <memory>
#include <unordered_map>
#include <string>

namespace geomath {

class FinslerOptimizer {
private:
    float lr_;
    float weight_decay_;
    float gauge_strength_;
    
    // Optimizer state tracking
    std::unordered_map<std::string, Tensor*> params_;
    std::unordered_map<std::string, Tensor*> grads_;
    
    // Beta iteration state
    int step_count_;
    
    // Sparse update tracking
    std::unordered_map<std::string, std::vector<int>> active_indices_;
    std::unordered_map<std::string, cl::Buffer> d_active_indices_;
    std::unordered_map<std::string, size_t> d_active_indices_capacity_;

public:
    FinslerOptimizer(float lr = 0.01f, float weight_decay = 0.0f, float gauge_strength = 0.5f);
    ~FinslerOptimizer();
    
    // Register a layer's weight/bias into the optimizer manifold
    void add_layer(const std::string& name, Tensor* w, Tensor* b, Tensor* w_grad, Tensor* b_grad);
    
    // Step computes the optimal descent path and updates the weights
    float step(const Tensor* current_beta_coords = nullptr);
    
    // Set active indices for sparse updates (e.g. embeddings)
    void set_active_indices(const std::string& name, const std::vector<int>& indices);
    
    // Clear gradients to zero across the manifold
    void zero_grad();
    
    // Remove a layer's weight/bias from the optimizer manifold
    void remove_layer(const std::string& name);
    
    // Get all tracked parameters
    const std::unordered_map<std::string, Tensor*>& get_params() const { return params_; }
    
    // Get all tracked gradients
    const std::unordered_map<std::string, Tensor*>& get_grads() const { return grads_; }
    
    // Dynamically adjust learning rate
    void set_lr(float lr) { lr_ = lr; }
    
};

} // namespace geomath
