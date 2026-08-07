#pragma once

#include "ocl_backend.h"
#include <vector>
#include <memory>
#include <stdexcept>
#include <numeric>
#include <unordered_map>
#include <mutex>

namespace geomath {

class BufferPool {
private:
    std::mutex mutex_;
    std::unordered_map<int, std::unordered_map<size_t, std::vector<cl::Buffer*>>> pool_;

public:
    static BufferPool& get() {
        static BufferPool instance;
        return instance;
    }

    cl::Buffer* acquire(size_t bytes, int device_id) {
        std::lock_guard<std::mutex> lock(mutex_);
        auto& list = pool_[device_id][bytes];
        if (!list.empty()) {
            auto buf = list.back();
            list.pop_back();
            return buf;
        }
        cl_int err = CL_SUCCESS;
        auto& backend = OCLBackend::get_instance();
        cl::Buffer* buf = new cl::Buffer(
            backend.context(device_id), 
            CL_MEM_READ_WRITE, 
            bytes, 
            nullptr, &err
        );
        if (err != CL_SUCCESS) {
            throw std::runtime_error("Failed to allocate OpenCL buffer. Error code: " + std::to_string(err));
        }
        return buf;
    }

    void release(size_t bytes, int device_id, cl::Buffer* buf) {
        std::lock_guard<std::mutex> lock(mutex_);
        pool_[device_id][bytes].push_back(buf);
    }
};

class Tensor {
private:
    std::shared_ptr<cl::Buffer> buffer_;
    std::vector<size_t> shape_;
    std::vector<size_t> strides_;
    size_t num_elements_;
    bool is_device_memory_;
    float* raw_host_data_; // For pybind compatibility
    int device_id_;

    void compute_strides() {
        strides_.resize(shape_.size());
        size_t stride = 1;
        for (int i = static_cast<int>(shape_.size()) - 1; i >= 0; --i) {
            strides_[i] = stride;
            stride *= shape_[i];
        }
    }

public:
    // Allocate a new tensor on the device
    Tensor(std::vector<size_t> shape, int device_id = 0)
        : shape_(shape), is_device_memory_(true), raw_host_data_(nullptr), device_id_(device_id) {
        
        num_elements_ = std::accumulate(shape.begin(), shape.end(), 1ULL, std::multiplies<size_t>());
        compute_strides();

        size_t bytes = num_elements_ * sizeof(float);
        auto* raw_buf = BufferPool::get().acquire(bytes, device_id);
        
        buffer_ = std::shared_ptr<cl::Buffer>(raw_buf, [bytes, device_id](cl::Buffer* b) {
            BufferPool::get().release(bytes, device_id, b);
        });
    }

    // Wrap existing data (e.g. from Python/NumPy via PyBind11)
    Tensor(float* raw_data, std::vector<size_t> shape, bool is_device = false, int device_id = 0)
        : shape_(shape), is_device_memory_(is_device), raw_host_data_(raw_data), device_id_(device_id) {
        num_elements_ = std::accumulate(shape.begin(), shape.end(), 1ULL, std::multiplies<size_t>());
        compute_strides();
        
        size_t bytes = num_elements_ * sizeof(float);
        auto* raw_buf = BufferPool::get().acquire(bytes, device_id);
        
        buffer_ = std::shared_ptr<cl::Buffer>(raw_buf, [bytes, device_id](cl::Buffer* b) {
            BufferPool::get().release(bytes, device_id, b);
        });
        
        // Copy the raw CPU data to the GPU immediately
        if (!is_device && raw_data != nullptr) {
            auto& backend = OCLBackend::get_instance();
            backend.queue(device_id_).enqueueWriteBuffer(*buffer_, CL_TRUE, 0, bytes, raw_data);
        }
    }
    
    // Create a shallow copy sharing the same underlying OpenCL buffer
    Tensor(std::shared_ptr<cl::Buffer> buffer, std::vector<size_t> shape, int device_id = 0)
        : buffer_(buffer), shape_(shape), is_device_memory_(true), raw_host_data_(nullptr), device_id_(device_id) {
        num_elements_ = std::accumulate(shape.begin(), shape.end(), 1ULL, std::multiplies<size_t>());
        compute_strides();
    }

    ~Tensor() = default;

    // Disable copy to prevent accidental massive memory duplication
    Tensor(const Tensor&) = delete;
    Tensor& operator=(const Tensor&) = delete;

    // Enable move semantics
    Tensor(Tensor&& other) noexcept
        : buffer_(std::move(other.buffer_)), shape_(std::move(other.shape_)),
          strides_(std::move(other.strides_)), num_elements_(other.num_elements_),
          is_device_memory_(other.is_device_memory_), raw_host_data_(other.raw_host_data_),
          device_id_(other.device_id_) {
        other.num_elements_ = 0;
        other.raw_host_data_ = nullptr;
    }

    std::shared_ptr<cl::Buffer> buffer() const { return buffer_; }
    size_t numel() const { return num_elements_; }
    const std::vector<size_t>& shape() const { return shape_; }
    int device() const { return device_id_; }

    // Copies data from CPU to GPU
    void copy_from_host(const float* host_data) {
        auto& backend = OCLBackend::get_instance();
        backend.queue(device_id_).enqueueWriteBuffer(*buffer_, CL_TRUE, 0, num_elements_ * sizeof(float), host_data);
    }

    // Copies data from GPU to CPU
    void copy_to_host(float* host_data) const {
        auto& backend = OCLBackend::get_instance();
        backend.queue(device_id_).enqueueReadBuffer(*buffer_, CL_TRUE, 0, num_elements_ * sizeof(float), host_data);
    }

    // Initializes tensor with zero
    void zero_() {
        auto& backend = OCLBackend::get_instance();
        float zero = 0.0f;
        backend.queue(device_id_).enqueueFillBuffer(*buffer_, zero, 0, num_elements_ * sizeof(float));
    }

    void sync_to_host() {
        if (raw_host_data_ != nullptr) {
            copy_to_host(raw_host_data_);
        }
    }

    void sync_from_host() {
        if (raw_host_data_ != nullptr) {
            copy_from_host(raw_host_data_);
        }
    }

    // Transfer Tensor to a different device via host bounce
    Tensor to(int target_device) const {
        if (target_device == device_id_) {
            throw std::runtime_error("Tensor is already on the target device");
        }
        
        Tensor new_tensor(shape_, target_device);
        std::vector<float> host_buffer(num_elements_);
        copy_to_host(host_buffer.data());
        new_tensor.copy_from_host(host_buffer.data());
        return new_tensor;
    }
};

} // namespace geomath
