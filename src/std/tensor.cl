extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr) -> void;
extern fn exp(x: float) -> float;
extern fn sqrt(x: float) -> float;
extern fn tanh(x: float) -> float;

struct Tensor {
    data: ptr;
    size: float;
}

fn tensor_alloc(size: float) -> ptr {
    let t = malloc(size * 8.0);
    return t;
}

fn zeros(size: float) -> ptr {
    let t = tensor_alloc(size);
    var i = 0.0;
    while (i < size) {
        t[i] = 0.0;
        i = i + 1.0;
    }
    return t;
}

fn ones(size: float) -> ptr {
    let t = tensor_alloc(size);
    var i = 0.0;
    while (i < size) {
        t[i] = 1.0;
        i = i + 1.0;
    }
    return t;
}

fn cartan_relu(arr: ptr, size: float) {
    if (arr == 0.0) { return; }
    var i = 0.0;
    while (i < size) {
        let v = arr[i];
        if (v < 0.0) { arr[i] = 0.0; }
        i = i + 1.0;
    }
}

fn relu(t: ptr) {
    cartan_relu(t, cartan_tree_len(t));
}

fn tensor_add(A: ptr, B: ptr, size: float) -> ptr {
    let out = tensor_alloc(size);
    var i = 0.0;
    while (i < size) {
        out[i] = A[i] + B[i];
        i = i + 1.0;
    }
    return out;
}

fn tensor_sub(A: ptr, B: ptr, size: float) -> ptr {
    let out = tensor_alloc(size);
    var i = 0.0;
    while (i < size) {
        out[i] = A[i] - B[i];
        i = i + 1.0;
    }
    return out;
}

fn tensor_mul(A: ptr, B: ptr, size: float) -> ptr {
    let out = tensor_alloc(size);
    var i = 0.0;
    while (i < size) {
        out[i] = A[i] * B[i];
        i = i + 1.0;
    }
    return out;
}

fn add(a: ptr, b: ptr) -> ptr {
    return tensor_add(a, b, cartan_tree_len(a));
}

fn sub(a: ptr, b: ptr) -> ptr {
    return tensor_sub(a, b, cartan_tree_len(a));
}

fn mul(a: ptr, b: ptr) -> ptr {
    return tensor_mul(a, b, cartan_tree_len(a));
}

fn tensor_sum(arr: ptr, size: float) -> float {
    if (arr == 0.0 || size <= 0.0) { return 0.0; }
    var s = 0.0;
    var i = 0.0;
    while (i < size) {
        s = s + arr[i];
        i = i + 1.0;
    }
    return s;
}

fn sum(t: ptr) -> float {
    return tensor_sum(t, cartan_tree_len(t));
}

fn tensor_mean(arr: ptr, size: float) -> float {
    if (size <= 0.0) { return 0.0; }
    return tensor_sum(arr, size) / size;
}

fn mean(t: ptr) -> float {
    return tensor_mean(t, cartan_tree_len(t));
}

fn tensor_max(arr: ptr, size: float) -> float {
    if (arr == 0.0 || size <= 0.0) { return 0.0; }
    var max_val = arr[0];
    var i = 1.0;
    while (i < size) {
        let v = arr[i];
        if (v > max_val) { max_val = v; }
        i = i + 1.0;
    }
    return max_val;
}

fn max(t: ptr) -> float {
    return tensor_max(t, cartan_tree_len(t));
}

fn tensor_min(arr: ptr, size: float) -> float {
    if (arr == 0.0 || size <= 0.0) { return 0.0; }
    var min_val = arr[0];
    var i = 1.0;
    while (i < size) {
        let v = arr[i];
        if (v < min_val) { min_val = v; }
        i = i + 1.0;
    }
    return min_val;
}

fn min(t: ptr) -> float {
    return tensor_min(t, cartan_tree_len(t));
}

fn tensor_sigmoid(arr: ptr, size: float) -> ptr {
    if (arr == 0.0) { return arr; }
    var i = 0.0;
    while (i < size) {
        let v = arr[i];
        arr[i] = 1.0 / (1.0 + exp(-v));
        i = i + 1.0;
    }
    return arr;
}

fn sigmoid(t: ptr) -> ptr {
    return tensor_sigmoid(t, cartan_tree_len(t));
}

fn tensor_silu(arr: ptr, size: float) -> ptr {
    if (arr == 0.0) { return arr; }
    var i = 0.0;
    while (i < size) {
        let v = arr[i];
        let sig = 1.0 / (1.0 + exp(-v));
        arr[i] = v * sig;
        i = i + 1.0;
    }
    return arr;
}

fn silu(t: ptr) -> ptr {
    return tensor_silu(t, cartan_tree_len(t));
}

fn tensor_gelu(arr: ptr, size: float) -> ptr {
    if (arr == 0.0) { return arr; }
    var i = 0.0;
    let sqrt_2_over_pi = 0.7978845608;
    while (i < size) {
        let v = arr[i];
        let inner = sqrt_2_over_pi * (v + 0.044715 * v * v * v);
        arr[i] = 0.5 * v * (1.0 + tanh(inner));
        i = i + 1.0;
    }
    return arr;
}

fn gelu(t: ptr) -> ptr {
    return tensor_gelu(t, cartan_tree_len(t));
}

fn tensor_softmax(arr: ptr, size: float) -> ptr {
    if (arr == 0.0 || size <= 0.0) { return arr; }
    let max_val = tensor_max(arr, size);
    var sum_exp = 0.0;
    var i = 0.0;
    while (i < size) {
        let v = exp(arr[i] - max_val);
        arr[i] = v;
        sum_exp = sum_exp + v;
        i = i + 1.0;
    }
    if (sum_exp > 0.0) {
        i = 0.0;
        while (i < size) {
            arr[i] = arr[i] / sum_exp;
            i = i + 1.0;
        }
    }
    return arr;
}

fn softmax(t: ptr) -> ptr {
    return tensor_softmax(t, cartan_tree_len(t));
}

fn cartan_tensor_to_dlpack(data_ptr: ptr, shape: ptr, ndim: float) -> ptr {
    return data_ptr;
}

fn cartan_tensor_from_dlpack(dlpack_ptr: ptr) -> ptr {
    return dlpack_ptr;
}



