#pragma once

#define CL_HPP_TARGET_OPENCL_VERSION 300
#define CL_TARGET_OPENCL_VERSION 300
#include <CL/opencl.hpp>

#include <memory>
#include <string>
#include <stdexcept>
#include <vector>
#include <unordered_map>

namespace geomath {

class OCLBackend {
private:
    std::vector<cl::Context> contexts_;
    std::vector<cl::Device> devices_;
    std::vector<cl::Program> programs_;
    std::vector<bool> compiled_;

    OCLBackend();
    void compile_kernels(int device_id);

public:
    // Singleton pattern
    static OCLBackend& get_instance() {
        static OCLBackend instance;
        return instance;
    }

    int get_num_devices() const { return static_cast<int>(devices_.size()); }

    cl::Context& context(int device_id = 0) { return contexts_.at(device_id); }
    
    cl::CommandQueue& queue(int device_id = 0) { 
        static thread_local std::unordered_map<int, cl::CommandQueue> thread_queues;
        if (thread_queues.find(device_id) == thread_queues.end()) {
            cl_int err;
            thread_queues[device_id] = cl::CommandQueue(context(device_id), device(device_id), 0, &err);
            if (err != CL_SUCCESS) {
                throw std::runtime_error("Failed to create thread-local CommandQueue.");
            }
        }
        return thread_queues[device_id];
    }
    cl::Device& device(int device_id = 0) { return devices_.at(device_id); }
    cl::Program& program(int device_id = 0) { 
        if (!compiled_.at(device_id)) {
            compile_kernels(device_id);
        }
        return programs_.at(device_id); 
    }

    std::string get_device_info() const {
        std::string info = "";
        for (int i = 0; i < devices_.size(); ++i) {
            info += "Device ID [" + std::to_string(i) + "]: " + devices_[i].getInfo<CL_DEVICE_NAME>() + 
                    "\nVendor: " + devices_[i].getInfo<CL_DEVICE_VENDOR>() + "\n";
        }
        return info;
    }
};

} // namespace geomath
