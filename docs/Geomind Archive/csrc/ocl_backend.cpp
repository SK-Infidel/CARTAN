#include "ocl_backend.h"
#include "kernels.cl.h"
#include <iostream>
#include <fstream>
#include <sstream>

namespace geomath {

OCLBackend::OCLBackend() {
    std::vector<cl::Platform> platforms;
    cl::Platform::get(&platforms);

    if (platforms.empty()) {
        throw std::runtime_error("No OpenCL platforms found.");
    }

    std::vector<cl::Device> all_devices;

    // 1. Collect all GPUs
    for (auto& p : platforms) {
        std::vector<cl::Device> devices;
        p.getDevices(CL_DEVICE_TYPE_GPU, &devices);
        for (auto& d : devices) {
            all_devices.push_back(d);
        }
    }

    // Fallback to CPU
    if (all_devices.empty()) {
        for (auto& p : platforms) {
            std::vector<cl::Device> devices;
            p.getDevices(CL_DEVICE_TYPE_CPU, &devices);
            for (auto& d : devices) {
                all_devices.push_back(d);
            }
        }
    }

    if (all_devices.empty()) {
        throw std::runtime_error("No OpenCL device found.");
    }

    // Sort to put NVIDIA first for backwards compatibility
    for (auto& d : all_devices) {
        std::string vendor = d.getInfo<CL_DEVICE_VENDOR>();
        if (vendor.find("NVIDIA") != std::string::npos) {
            devices_.push_back(d);
        }
    }
    for (auto& d : all_devices) {
        std::string vendor = d.getInfo<CL_DEVICE_VENDOR>();
        if (vendor.find("NVIDIA") == std::string::npos) {
            devices_.push_back(d);
        }
    }

    contexts_.resize(devices_.size());
    programs_.resize(devices_.size());
    compiled_.resize(devices_.size(), false);

    for (int i = 0; i < devices_.size(); ++i) {
        contexts_[i] = cl::Context(devices_[i]);
        // Note: compile_kernels(i) is now deferred to lazy loading
    }
}

void OCLBackend::compile_kernels(int device_id) {
    if (compiled_[device_id]) return;

    cl::Device device = devices_[device_id];
    std::string vendor = device.getInfo<CL_DEVICE_VENDOR>();
    std::string name = device.getInfo<CL_DEVICE_NAME>();
    
    std::cout << "\n[GeoMath] JIT-Compiling Native OpenCL Engine for: " << name << "\n"
              << "          (Note: This may take up to 2-5 minutes on NVIDIA GPUs during the first boot. Please wait...)" << std::endl;

    std::string src;
    bool loaded_from_disk = false;
    
    std::ifstream file("csrc/kernels.cl.h");
    if (file.is_open()) {
        std::stringstream buffer;
        buffer << file.rdbuf();
        std::string content = buffer.str();
        size_t start = content.find("R\"(");
        size_t end = content.rfind(")\";");
        if (start != std::string::npos && end != std::string::npos && end > start) {
            src = content.substr(start + 3, end - (start + 3));
            loaded_from_disk = true;
        }
    }
    
    if (!loaded_from_disk) {
        src = std::string(ocl_kernel_source);
        std::cout << "[GeoMath] Loaded OpenCL kernels from embedded binary fallback" << std::endl;
    } else {
        std::cout << "[GeoMath] Loaded OpenCL kernels dynamically from csrc/kernels.cl.h (Hot-Reload Enabled)" << std::endl;
    }

    cl::Program::Sources sources;
    sources.push_back({src.c_str(), src.length()});
    
    cl::Program program(contexts_[device_id], sources);

    // Dropped -cl-std=CL2.0 because NVIDIA's compiler struggles/hangs with it.
    // Fallback to default OpenCL C version for maximum cross-vendor compatibility.
    std::string build_args = "-cl-fast-relaxed-math";
    cl_int err = program.build({device}, build_args.c_str());
    
    if (err != CL_SUCCESS) {
        std::string build_log = program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(device);
        std::cerr << "OpenCL Build Error: " << build_log << std::endl;
        throw std::runtime_error("Failed to build OpenCL program: " + build_log);
    }
    
    programs_[device_id] = program;
    compiled_[device_id] = true;
    std::cout << "[GeoMath] OpenCL Engine Compiled Successfully!\n" << std::endl;
}

} // namespace geomath
