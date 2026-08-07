#include "optimizer.h"
#include <cmath>

namespace geomath {

FinslerOptimizer::FinslerOptimizer(float lr, float weight_decay, float gauge_strength)
    : lr_(lr), weight_decay_(weight_decay), gauge_strength_(gauge_strength), step_count_(0) {
}

FinslerOptimizer::~FinslerOptimizer() {
}

void FinslerOptimizer::add_layer(const std::string& name, Tensor* w, Tensor* b, Tensor* w_grad, Tensor* b_grad) {

    if (w != nullptr) {
        params_[name + "_w"] = w;
        grads_[name + "_w"] = w_grad;
    }
    
    if (b != nullptr) {
        params_[name + "_b"] = b;
        grads_[name + "_b"] = b_grad;
    }
}

void FinslerOptimizer::set_active_indices(const std::string& name, const std::vector<int>& indices) {
    active_indices_[name] = indices;
    if (params_.count(name) > 0) {
        auto& backend = OCLBackend::get_instance();
        int dev = params_[name]->device();
        cl_int err;
        
        if (d_active_indices_.count(name) == 0 || d_active_indices_capacity_[name] < indices.size()) {
            d_active_indices_[name] = cl::Buffer(backend.context(dev), CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 
                                                 indices.size() * sizeof(int), (void*)indices.data(), &err);
            d_active_indices_capacity_[name] = indices.size();
            if (err != CL_SUCCESS) throw std::runtime_error("Failed to allocate active_indices buffer");
        } else {
            backend.queue(dev).enqueueWriteBuffer(d_active_indices_[name], CL_TRUE, 0, indices.size() * sizeof(int), indices.data());
        }
    }
}

float FinslerOptimizer::step(const Tensor* current_beta_coords) {
    step_count_++;
    
    // Standard learning rate
    float step_size = lr_;
    
    auto& backend = OCLBackend::get_instance();

    for (const auto& pair : params_) {
        const std::string& key = pair.first;
        
        auto& w = params_[key];
        auto& g = grads_[key];
        
        if (w->device() != g->device()) {
            throw std::runtime_error("Optimizer device mismatch");
        }
        int dev = w->device();
        
        auto shape = w->shape();
        int rows = 1;
        int cols = 1;
        if (shape.size() == 0) {
            rows = 1;
            cols = 1;
        } else if (shape.size() == 1) {
            rows = 1;
            cols = static_cast<int>(shape[0]);
        } else if (shape.size() == 2) {
            rows = static_cast<int>(shape[0]);
            cols = static_cast<int>(shape[1]);
        } else {
            rows = static_cast<int>(shape[0]);
            cols = static_cast<int>(w->numel() / (rows > 0 ? rows : 1));
        }
        
        // Ensure rows > 0 for OpenCL NDRange
        if (rows <= 0) rows = 1;
        bool is_sparse = (active_indices_.count(key) > 0 && d_active_indices_.count(key) > 0);
        int launch_rows = is_sparse ? static_cast<int>(active_indices_[key].size()) : rows;
        
        if (launch_rows == 0) continue; // Nothing to update
        
        // Original curved Finsler/geodesic updates
        std::string kernel_name = is_sparse ? "finsler_geodesic_update_sparse" : "finsler_geodesic_update";
        cl::Kernel kernel(backend.program(dev), kernel_name.c_str());
        
        // Beta extraction for Inverse Randers Metric (Sherman-Morrison G^-1)
        int use_beta = 0;
        Tensor* beta_tensor = nullptr;
        
        // Stream 0 is the flat backbone and uses a Euclidean optimizer. 
        // Streams 1-6 use the Inverse Randers Metric based on their drift vector 'b'.
        if (key.find("stream0") == std::string::npos && key.find("stream") != std::string::npos) {
            std::string b_key = key;
            if (key.substr(key.length() - 2) == "_w") {
                b_key = key.substr(0, key.length() - 2) + "_b";
            }
            if (params_.count(b_key) > 0) {
                beta_tensor = params_[b_key];
                use_beta = 1;
            }
        }
        
        kernel.setArg(0, *w->buffer());
        kernel.setArg(1, *g->buffer());
        
        if (is_sparse) {
            kernel.setArg(2, d_active_indices_[key]);
            kernel.setArg(3, step_size); 
            kernel.setArg(4, weight_decay_);
            kernel.setArg(5, launch_rows);
            kernel.setArg(6, cols);
            if (use_beta) {
                kernel.setArg(7, *beta_tensor->buffer());
                kernel.setArg(8, 1);
            } else {
                kernel.setArg(7, *w->buffer());
                kernel.setArg(8, 0);
            }
        } else {
            kernel.setArg(2, step_size); 
            kernel.setArg(3, weight_decay_);
            kernel.setArg(4, rows);
            kernel.setArg(5, cols);
            if (use_beta) {
                kernel.setArg(6, *beta_tensor->buffer());
                kernel.setArg(7, 1);
            } else {
                kernel.setArg(6, *w->buffer());
                kernel.setArg(7, 0);
            }
        }
        
        backend.queue(dev).enqueueNDRangeKernel(
            kernel, cl::NullRange, cl::NDRange(launch_rows), cl::NullRange
        );
    }
    
    // Prevent GPU queue from flooding ahead of Python (fixes Ctrl+C freezing)
    // Use device 0 as default sync point
    backend.queue(0).finish();
    
    return 1.0f;
}

void FinslerOptimizer::remove_layer(const std::string& name) {
    std::string w_key = name + "_w";
    std::string b_key = name + "_b";
    

    params_.erase(w_key);
    grads_.erase(w_key);
    params_.erase(b_key);
    grads_.erase(b_key);
    active_indices_.erase(w_key);
    d_active_indices_.erase(w_key);
    d_active_indices_capacity_.erase(w_key);
    active_indices_.erase(b_key);
    d_active_indices_.erase(b_key);
    d_active_indices_capacity_.erase(b_key);
}

void FinslerOptimizer::zero_grad() {
    for (const auto& pair : grads_) {
        pair.second->zero_();
    }
}

} // namespace geomath
