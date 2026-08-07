#pragma once

#include "tensor.h"
#include <memory>

namespace geomath {

class LinearLayer {
private:
    std::unique_ptr<Tensor> weight_;
    std::unique_ptr<Tensor> bias_;
    std::unique_ptr<Tensor> weight_grad_;
    std::unique_ptr<Tensor> bias_grad_;
    
    std::unique_ptr<Tensor> cached_input_;
    
    size_t in_features_;
    size_t out_features_;

public:
    LinearLayer(size_t in_features, size_t out_features, int device_id = 0);
    
    std::unique_ptr<Tensor> forward(const Tensor& x);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output);
    
    Tensor* weight() { return weight_.get(); }
    Tensor* bias() { return bias_.get(); }
    Tensor* weight_grad() { return weight_grad_.get(); }
    Tensor* bias_grad() { return bias_grad_.get(); }
};

class MLP {
private:
    std::unique_ptr<LinearLayer> fc1_;
    std::unique_ptr<LinearLayer> fc2_;
    std::unique_ptr<Tensor> cached_hidden_;

public:
    MLP(size_t in_dim, size_t hidden_dim, size_t out_dim, int device_id = 0);
    
    std::unique_ptr<Tensor> forward(const Tensor& x);
    std::unique_ptr<Tensor> backward(const Tensor& grad_output);
    
    LinearLayer* fc1() { return fc1_.get(); }
    LinearLayer* fc2() { return fc2_.get(); }
};

} // namespace geomath
