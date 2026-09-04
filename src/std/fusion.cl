// CARTAN Standard Library: Model Fusion & Non-Euclidean Riemannian Weight Merging Module (SLERP, TIES, DARE, Riemannian Retraction)
// Layer 1 Module: std::fusion

include "src/std/tensor.cl";
include "src/std/math.cl";

fn fusion_slerp_tensors(t1: ptr, t2: ptr, weight: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_vec_create();
    
    // 1. Compute vector norms and cosine angle on S^(N-1) unit hypersphere
    var norm1 = 0.0;
    var norm2 = 0.0;
    var dot = 0.0;
    var i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        norm1 = norm1 + v1 * v1;
        norm2 = norm2 + v2 * v2;
        dot = dot + v1 * v2;
        i = i + 1.0;
    }
    norm1 = sqrt(norm1 + 0.000001);
    norm2 = sqrt(norm2 + 0.000001);
    let target_norm = norm1 * (1.0 - weight) + norm2 * weight;
    
    var cos_omega = dot / (norm1 * norm2);
    if (cos_omega > 0.9995) {
        // Linear fallback for nearly collinear vectors
        i = 0.0;
        let w1 = 1.0 - weight;
        let w2 = weight;
        while (i < len) {
            let v1 = cartan_vec_get_f32(t1, i);
            let v2 = cartan_vec_get_f32(t2, i);
            cartan_vec_push_f32(out, v1 * w1 + v2 * w2);
            i = i + 1.0;
        }
        return out;
    }
    if (cos_omega < -0.9995) { cos_omega = -0.9995; }
    
    let omega = acos(cos_omega);
    let sin_omega = sin(omega);
    let scale1 = sin((1.0 - weight) * omega) / sin_omega;
    let scale2 = sin(weight * omega) / sin_omega;

    // 2. Compute SLERP directional unit vectors
    var out_raw = cartan_vec_create();
    var norm_out = 0.0;
    i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let slerp_v = v1 * scale1 + v2 * scale2;
        norm_out = norm_out + slerp_v * slerp_v;
        cartan_vec_push_f32(out_raw, slerp_v);
        i = i + 1.0;
    }
    norm_out = sqrt(norm_out + 0.000001);

    // 3. Riemannian Manifold Volume-Preserving Rescaling (prevents manifold warping)
    let manifold_scale = target_norm / norm_out;
    i = 0.0;
    while (i < len) {
        let raw_v = cartan_vec_get_f32(out_raw, i);
        cartan_vec_push_f32(out, raw_v * manifold_scale);
        i = i + 1.0;
    }
    return out;
}

fn fusion_ties_merge(t1: ptr, t2: ptr, t3: ptr, threshold: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_vec_create();
    var i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let v3 = cartan_vec_get_f32(t3, i);
        var sum_v = v1 + v2 + v3;
        let abs_v = math_abs_val(sum_v);
        if (abs_v < threshold) { sum_v = 0.0; }
        cartan_vec_push_f32(out, sum_v / 3.0);
        i = i + 1.0;
    }
    return out;
}

fn fusion_dare_rescale(t1: ptr, drop_p: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_vec_create();
    var scale = 1.0;
    if (drop_p < 1.0) {
        scale = 1.0 / (1.0 - drop_p);
    }
    var i = 0.0;
    while (i < len) {
        let val = cartan_vec_get_f32(t1, i);
        var rescaled = val * scale;
        let rand_sample = math_mod_val(i * 1103515245.0 + 12345.0, 2147483648.0) / 2147483648.0;
        if (rand_sample < drop_p) {
            rescaled = 0.0;
        }
        cartan_vec_push_f32(out, rescaled);
        i = i + 1.0;
    }
    return out;
}

fn fusion_tangent_space_slerp(base_w: ptr, target_w: ptr, alpha: float) -> ptr {
    let len = cartan_vec_len(base_w);
    let out = cartan_vec_create();
    
    var i = 0.0;
    while (i < len) {
        let b = cartan_vec_get_f32(base_w, i);
        let t = cartan_vec_get_f32(target_w, i);
        let delta = t - b;
        cartan_vec_push_f32(out, b + delta * alpha);
        i = i + 1.0;
    }
    return out;
}

fn fusion_slerp_arrays(arr1: ptr, arr2: ptr, out_arr: ptr, size: float, weight: float) {
    if (arr1 == 0.0 || arr2 == 0.0 || out_arr == 0.0 || size <= 0.0) { return; }
    var norm1 = 0.0;
    var norm2 = 0.0;
    var dot = 0.0;
    var i = 0.0;
    while (i < size) {
        let v1 = arr1[i];
        let v2 = arr2[i];
        norm1 = norm1 + v1 * v1;
        norm2 = norm2 + v2 * v2;
        dot = dot + v1 * v2;
        i = i + 1.0;
    }
    norm1 = sqrt(norm1 + 0.000001);
    norm2 = sqrt(norm2 + 0.000001);
    let target_norm = norm1 * (1.0 - weight) + norm2 * weight;

    var cos_omega = dot / (norm1 * norm2);
    if (cos_omega > 0.9995) {
        i = 0.0;
        let w1 = 1.0 - weight;
        let w2 = weight;
        while (i < size) {
            out_arr[i] = arr1[i] * w1 + arr2[i] * w2;
            i = i + 1.0;
        }
        return;
    }
    if (cos_omega < -0.9995) { cos_omega = -0.9995; }

    let omega = acos(cos_omega);
    let sin_omega = sin(omega);
    let scale1 = sin((1.0 - weight) * omega) / sin_omega;
    let scale2 = sin(weight * omega) / sin_omega;

    var norm_out = 0.0;
    i = 0.0;
    while (i < size) {
        let slerp_v = arr1[i] * scale1 + arr2[i] * scale2;
        norm_out = norm_out + slerp_v * slerp_v;
        out_arr[i] = slerp_v;
        i = i + 1.0;
    }
    norm_out = sqrt(norm_out + 0.000001);
    let manifold_scale = target_norm / norm_out;
    i = 0.0;
    while (i < size) {
        out_arr[i] = out_arr[i] * manifold_scale;
        i = i + 1.0;
    }
}

fn fusion_ties_arrays(arr1: ptr, arr2: ptr, arr3: ptr, out_arr: ptr, size: float, threshold: float) {
    if (arr1 == 0.0 || arr2 == 0.0 || arr3 == 0.0 || out_arr == 0.0 || size <= 0.0) { return; }
    var i = 0.0;
    while (i < size) {
        var sum_v = arr1[i] + arr2[i] + arr3[i];
        let abs_v = math_abs_val(sum_v);
        if (abs_v < threshold) { sum_v = 0.0; }
        out_arr[i] = sum_v / 3.0;
        i = i + 1.0;
    }
}

