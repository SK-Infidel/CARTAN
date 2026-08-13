// src/std/tensor.cl
// CARTAN Standard Library: Tensor Creation, Reductions & Activations

extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr) -> void;
extern fn cartan_relu(arr: ptr, size: float) -> void;
extern fn cartan_matmul(A: ptr, B: ptr, out: ptr, M: float, K: float, N: float) -> void;
extern fn cartan_tensor_add(A: ptr, B: ptr, size: float) -> ptr;
extern fn cartan_tensor_sub(A: ptr, B: ptr, size: float) -> ptr;
extern fn cartan_tensor_mul(A: ptr, B: ptr, size: float) -> ptr;

extern fn cartan_tensor_sum(arr: ptr, size: float) -> float;
extern fn cartan_tensor_mean(arr: ptr, size: float) -> float;
extern fn cartan_tensor_max(arr: ptr, size: float) -> float;
extern fn cartan_tensor_min(arr: ptr, size: float) -> float;
extern fn cartan_tensor_softmax(arr: ptr, size: float) -> ptr;
extern fn cartan_tensor_gelu(arr: ptr, size: float) -> ptr;
extern fn cartan_tensor_silu(arr: ptr, size: float) -> ptr;
extern fn cartan_tensor_sigmoid(arr: ptr, size: float) -> ptr;
extern fn cartan_tensor_sample_topk(logits: ptr, size: float, top_k: float, temp: float) -> float;

struct Tensor {
    data: ptr;
    size: float;
}

fn zeros(size: float) -> ptr {
    return cartan_tensor_alloc(size);
}

fn ones(size: float) -> ptr {
    let t = cartan_tensor_alloc(size);
    var i = 0.0;
    while (i < size) {
        cartan_tree_set(t, i, 1.0);
        i = i + 1.0;
    }
    return t;
}

fn relu(t: ptr) {
    cartan_relu(t, cartan_tree_len(t));
}

fn add(a: ptr, b: ptr) -> ptr {
    return cartan_tensor_add(a, b, cartan_tree_len(a));
}

fn sub(a: ptr, b: ptr) -> ptr {
    return cartan_tensor_sub(a, b, cartan_tree_len(a));
}

fn mul(a: ptr, b: ptr) -> ptr {
    return cartan_tensor_mul(a, b, cartan_tree_len(a));
}

fn sum(t: ptr) -> float {
    return cartan_tensor_sum(t, cartan_tree_len(t));
}

fn mean(t: ptr) -> float {
    return cartan_tensor_mean(t, cartan_tree_len(t));
}

fn max(t: ptr) -> float {
    return cartan_tensor_max(t, cartan_tree_len(t));
}

fn min(t: ptr) -> float {
    return cartan_tensor_min(t, cartan_tree_len(t));
}

fn softmax(t: ptr) -> ptr {
    return cartan_tensor_softmax(t, cartan_tree_len(t));
}

fn gelu(t: ptr) -> ptr {
    return cartan_tensor_gelu(t, cartan_tree_len(t));
}

fn silu(t: ptr) -> ptr {
    return cartan_tensor_silu(t, cartan_tree_len(t));
}

fn sigmoid(t: ptr) -> ptr {
    return cartan_tensor_sigmoid(t, cartan_tree_len(t));
}
