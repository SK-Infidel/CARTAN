// Force recompile after adding semantic weight loss kernel
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/numpy.h>
#include "tensor.h"
#include "mlp_layers.h"
#include "ocl_backend.h"
#include "optimizer.h"
#include "math_primitives.h"
#include "engine.h"

namespace py = pybind11;

PYBIND11_MODULE(geomath, m) {
    m.doc() = "GeoMath OpenCL Compute Engine for Finsler Geometry";

    // Bind get_device_info
    m.def("get_device_info", []() {
        return geomath::OCLBackend::get_instance().get_device_info();
    });

    // Bind Tensor
    py::class_<geomath::Tensor>(m, "Tensor")
        .def(py::init([](std::vector<size_t> shape, int device_id) {
            return new geomath::Tensor(shape, device_id);
        }), py::arg("shape"), py::arg("device_id") = 0)
        .def("shape", &geomath::Tensor::shape)
        .def("numel", &geomath::Tensor::numel)
        .def("zero_", &geomath::Tensor::zero_)
        .def("device", &geomath::Tensor::device)
        .def("to", &geomath::Tensor::to)
        // Helper to copy data from NumPy to OpenCL Tensor
        .def("copy_from_numpy", [](geomath::Tensor& t, py::array_t<float> array) {
            py::buffer_info buf = array.request();
            if (static_cast<size_t>(buf.size) != t.numel()) throw std::runtime_error("Size mismatch");
            t.copy_from_host(static_cast<float*>(buf.ptr));
        })
        // Helper to copy data from OpenCL Tensor to NumPy
        .def("numpy", [](geomath::Tensor& t) {
            auto result = py::array_t<float>(t.shape());
            py::buffer_info buf = result.request();
            t.copy_to_host(static_cast<float*>(buf.ptr));
            return result;
        })
        .def("copy_from_numpy", [](geomath::Tensor& t, py::array_t<float> arr) {
            py::buffer_info buf = arr.request();
            if (static_cast<size_t>(buf.size) != t.numel()) throw std::runtime_error("Size mismatch for copy_from_numpy");
            t.copy_from_host(static_cast<float*>(buf.ptr));
        });

    // Bind LinearLayer
    py::class_<geomath::LinearLayer>(m, "LinearLayer")
        .def(py::init([](size_t in_features, size_t out_features, int device_id) {
            return new geomath::LinearLayer(in_features, out_features, device_id);
        }), py::arg("in_features"), py::arg("out_features"), py::arg("device_id") = 0)
        .def("forward", &geomath::LinearLayer::forward)
        .def("backward", &geomath::LinearLayer::backward);

    // Bind Activation Functions
    m.def("silu_inplace", &geomath::silu_inplace);
    m.def("silu_backward_inplace", &geomath::silu_backward_inplace);
    
    // Bind Math Primitives
    m.def("tanh_inplace", &geomath::tanh_inplace);
    m.def("sin_inplace", &geomath::sin_inplace);
    m.def("cos_inplace", &geomath::cos_inplace);
    m.def("exp_inplace", &geomath::exp_inplace);
    m.def("rms_norm_inplace", &geomath::rms_norm_inplace);
    m.def("cumsum_inplace", &geomath::cumsum_inplace);
    m.def("matmul", &geomath::matmul);

    // Bind FinslerBackend
    py::class_<geomath::FinslerBackend>(m, "FinslerBackend")
        .def(py::init<>())
        .def("compute_e8_forward", &geomath::FinslerBackend::compute_e8_forward)
        .def("compute_e8_backward", &geomath::FinslerBackend::compute_e8_backward);

    // Bind FinslerOptimizer
    py::class_<geomath::FinslerOptimizer>(m, "FinslerOptimizer")
        .def(py::init<float, float, float>(),
             py::arg("lr") = 0.01f, py::arg("weight_decay") = 0.0f, py::arg("gauge_strength") = 0.5f)
        .def("add_layer", &geomath::FinslerOptimizer::add_layer)
        .def("step", &geomath::FinslerOptimizer::step, py::arg("current_beta_coords") = nullptr)
        .def("zero_grad", &geomath::FinslerOptimizer::zero_grad);

    // Bind GeoMindEngine (forced recompile)
    py::class_<geomath::GeoMindHybridEngine>(m, "GeoMindEngine")
        .def(py::init([](int vocab_size, int num_streams, int device_id) {
            return new geomath::GeoMindHybridEngine(vocab_size, num_streams, device_id);
        }), py::arg("vocab_size"), py::arg("num_streams"), py::arg("device_id") = 0)
        .def("forward", [](geomath::GeoMindHybridEngine& engine, py::array_t<int> token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask, geomath::Tensor* metric_tensor) {
            py::buffer_info buf = token_ids.request();
            if (static_cast<size_t>(buf.size) != batch * seq_len) throw std::runtime_error("Size mismatch for token_ids");
            return engine.forward(static_cast<int*>(buf.ptr), batch, seq_len, active_stream_mask, metric_tensor);
        }, py::arg("token_ids"), py::arg("batch"), py::arg("seq_len"), py::arg("active_stream_mask") = 0xFF, py::arg("metric_tensor") = nullptr)
        .def("forward_all_streams", [](geomath::GeoMindHybridEngine& engine,
                                       py::array_t<int> token_ids,
                                       int attention_idx,
                                       uint32_t active_stream_mask,
                                       std::optional<py::array_t<float>> metric_tensor) {
            
            py::buffer_info buf = token_ids.request();
            if (buf.ndim != 2) throw std::runtime_error("token_ids must be 2D [batch, seq_len]");
            
            size_t batch = buf.shape[0];
            size_t seq_len = buf.shape[1];
            
            const geomath::Tensor* metric_ptr = nullptr;
            std::unique_ptr<geomath::Tensor> cpp_metric;
            if (metric_tensor.has_value()) {
                py::buffer_info mbuf = metric_tensor->request();
                if (mbuf.ndim != 3) throw std::runtime_error("metric_tensor must be 3D [batch, seq_len, dim]");
                cpp_metric = std::make_unique<geomath::Tensor>(
                    std::vector<size_t>{(size_t)mbuf.shape[0], (size_t)mbuf.shape[1], (size_t)mbuf.shape[2]}, 0
                );
                cpp_metric->copy_from_host(static_cast<float*>(mbuf.ptr));
                metric_ptr = cpp_metric.get();
            }
            
            auto stream_tensors = engine.forward_all_streams(static_cast<const int*>(buf.ptr), batch, seq_len, attention_idx, active_stream_mask, metric_ptr);
            
            // Convert to a list of numpy arrays
            py::list out_list;
            for (auto& t : stream_tensors) {
                auto out_shape = t->shape();
                py::array_t<float> out_arr({out_shape[0], out_shape[1], out_shape[2]});
                t->copy_to_host(static_cast<float*>(out_arr.request().ptr));
                out_list.append(out_arr);
            }
            return out_list;
        }, py::arg("token_ids"), py::arg("attention_idx") = 0, py::arg("active_stream_mask") = 0xFF, py::arg("metric_tensor") = py::none())
        .def("backward", [](geomath::GeoMindHybridEngine& engine, const geomath::Tensor& grad_output, py::array_t<int> token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask, geomath::Tensor* metric_tensor) {
            py::buffer_info buf = token_ids.request();
            engine.backward(grad_output, static_cast<int*>(buf.ptr), batch, seq_len, active_stream_mask, metric_tensor);
        }, py::arg("grad_output"), py::arg("token_ids"), py::arg("batch"), py::arg("seq_len"), py::arg("active_stream_mask") = 0xFF, py::arg("metric_tensor") = nullptr)
        .def("compute_loss_and_backward", [](geomath::GeoMindHybridEngine& engine, py::array_t<int> target_token_ids, py::array_t<float> target_ic, py::array_t<int> token_ids, size_t batch, size_t seq_len, uint32_t active_stream_mask, geomath::Tensor* metric_tensor) {
            py::buffer_info buf1 = target_token_ids.request();
            py::buffer_info buf2 = target_ic.request();
            py::buffer_info buf3 = token_ids.request();
            if (static_cast<size_t>(buf1.size) != batch * seq_len) throw std::runtime_error("Size mismatch for target_token_ids");
            if (static_cast<size_t>(buf2.size) != batch * seq_len) throw std::runtime_error("Size mismatch for target_ic");
            if (static_cast<size_t>(buf3.size) != batch * seq_len) throw std::runtime_error("Size mismatch for token_ids");
            return engine.compute_loss_and_backward(static_cast<int*>(buf1.ptr), static_cast<float*>(buf2.ptr), static_cast<int*>(buf3.ptr), batch, seq_len, active_stream_mask, metric_tensor);
        }, py::arg("target_token_ids"), py::arg("target_ic"), py::arg("token_ids"), py::arg("batch"), py::arg("seq_len"), py::arg("active_stream_mask") = 0xFF, py::arg("metric_tensor") = nullptr)
        .def("step", &geomath::GeoMindHybridEngine::step)
        .def("zero_grad", &geomath::GeoMindHybridEngine::zero_grad)
        .def("reset_context", &geomath::GeoMindHybridEngine::reset_local_context)
        .def("set_learning_rate", &geomath::GeoMindHybridEngine::set_learning_rate)
        .def("set_embeddings_frozen", &geomath::GeoMindHybridEngine::set_embeddings_frozen)
        
        .def("get_parameters", &geomath::GeoMindHybridEngine::get_parameters, py::return_value_policy::reference)
        .def("get_gradients", &geomath::GeoMindHybridEngine::get_gradients, py::return_value_policy::reference)
        
        .def("sft_ce_forward_backward", [](geomath::GeoMindHybridEngine& engine,
                geomath::Tensor& pred_normed, geomath::Tensor& norm_embeds,
                geomath::Tensor& active_ics,
                py::array_t<int32_t, py::array::c_style | py::array::forcecast> targets_arr,
                int N, int V, float logit_scale, float zipf_gamma,
                geomath::Tensor& grad_out) -> std::pair<float, std::vector<float>> {
            auto buf = targets_arr.request();
            float avg_loss = engine.sft_ce_forward_backward(
                pred_normed, norm_embeds, active_ics,
                static_cast<const int*>(buf.ptr), N, V,
                logit_scale, zipf_gamma, grad_out);
            return {avg_loss, engine.get_last_sft_losses()};
        }, py::arg("pred_normed"), py::arg("norm_embeds"), py::arg("active_ics"),
           py::arg("targets"), py::arg("N"), py::arg("V"),
           py::arg("logit_scale"), py::arg("zipf_gamma"),
           py::arg("grad_out"));
}
