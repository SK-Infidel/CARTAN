// CARTAN Standard Library: Model Fusion & Non-Euclidean Riemannian Weight Merging Module (SLERP, TIES, DARE, Riemannian Retraction)
// Layer 1 Module: std::fusion

include "src/std/tensor.cl";
include "src/std/math.cl";

fn fusion_slerp_tensors(t1: ptr, t2: ptr, weight: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_tensor_alloc(len);
    
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
            cartan_vec_set_f32(out, i, v1 * w1 + v2 * w2);
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
    let out_raw = cartan_tensor_alloc(len);
    var norm_out = 0.0;
    i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let slerp_v = v1 * scale1 + v2 * scale2;
        norm_out = norm_out + slerp_v * slerp_v;
        cartan_vec_set_f32(out_raw, i, slerp_v);
        i = i + 1.0;
    }
    norm_out = sqrt(norm_out + 0.000001);

    // 3. Riemannian Manifold Volume-Preserving Rescaling (prevents manifold warping)
    let manifold_scale = target_norm / norm_out;
    i = 0.0;
    while (i < len) {
        let raw_v = cartan_vec_get_f32(out_raw, i);
        cartan_vec_set_f32(out, i, raw_v * manifold_scale);
        i = i + 1.0;
    }
    free(out_raw);
    return out;
}

fn fusion_ties_merge(t1: ptr, t2: ptr, t3: ptr, threshold: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_tensor_alloc(len);
    var i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let v3 = cartan_vec_get_f32(t3, i);
        var sum_v = v1 + v2 + v3;
        let abs_v = math_abs_val(sum_v);
        if (abs_v < threshold) { sum_v = 0.0; }
        cartan_vec_set_f32(out, i, sum_v / 3.0);
        i = i + 1.0;
    }
    return out;
}

fn fusion_dare_rescale(t1: ptr, drop_p: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_tensor_alloc(len);
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
        cartan_vec_set_f32(out, i, rescaled);
        i = i + 1.0;
    }
    return out;
}

// DARE (Drop And REscale) Model Weight Merging
// Drops fine-tuning deltas with Bernoulli probability drop_p and rescales remaining deltas by 1 / (1 - drop_p)
fn fusion_dare_merge(t1: ptr, t2: ptr, drop_p: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_tensor_alloc(len);
    var scale = 1.0;
    if (drop_p < 1.0) {
        scale = 1.0 / (1.0 - drop_p);
    } else {
        scale = 0.0;
    }
    var i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let delta = v2 - v1;
        var rescaled_delta = delta * scale;
        let rand_sample = math_mod_val(i * 1103515245.0 + 12345.0, 2147483648.0) / 2147483648.0;
        if (rand_sample < drop_p) {
            rescaled_delta = 0.0;
        }
        cartan_vec_set_f32(out, i, v1 + rescaled_delta);
        i = i + 1.0;
    }
    return out;
}

// Task Arithmetic Subspace Vector Addition
// Merges multiple fine-tuned models by linearly combining task vectors relative to a shared base model
fn fusion_task_arithmetic(base_w: ptr, t1: ptr, t2: ptr, w1: float, w2: float) -> ptr {
    let len = cartan_vec_len(base_w);
    let out = cartan_tensor_alloc(len);
    var i = 0.0;
    while (i < len) {
        let b = cartan_vec_get_f32(base_w, i);
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let tau1 = v1 - b;
        let tau2 = v2 - b;
        let merged = b + tau1 * w1 + tau2 * w2;
        cartan_vec_set_f32(out, i, merged);
        i = i + 1.0;
    }
    return out;
}

// KnOTS (Knowledge Orthogonal Task Subspaces) Fusion
// Eliminates inter-task interference by projecting task vectors into orthogonal subspace complements via Gram-Schmidt
fn fusion_knots_orthogonal_merge(base_w: ptr, t1: ptr, t2: ptr, rank: float) -> ptr {
    let len = cartan_vec_len(base_w);
    let out = cartan_tensor_alloc(len);
    
    // 1. Compute inner product <tau1, tau2> and squared norm ||tau1||^2
    var dot = 0.0;
    var norm1_sq = 0.0;
    var i = 0.0;
    while (i < len) {
        let b = cartan_vec_get_f32(base_w, i);
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let tau1 = v1 - b;
        let tau2 = v2 - b;
        dot = dot + tau1 * tau2;
        norm1_sq = norm1_sq + tau1 * tau1;
        i = i + 1.0;
    }
    
    // 2. Compute Gram-Schmidt projection scalar
    let proj_scalar = dot / (norm1_sq + 0.000001);
    
    // 3. Assemble orthogonalized knowledge subspace: base + tau1 + (tau2 - proj * tau1)
    i = 0.0;
    while (i < len) {
        let b = cartan_vec_get_f32(base_w, i);
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let tau1 = v1 - b;
        let tau2 = v2 - b;
        let tau2_ortho = tau2 - tau1 * proj_scalar;
        let merged = b + tau1 + tau2_ortho;
        cartan_vec_set_f32(out, i, merged);
        i = i + 1.0;
    }
    return out;
}

// M2N2 Dynamic Split-Point Boundary Crossover
// Performs dynamic parameter space boundary partition with smooth sigmoid boundary transition
fn fusion_m2n2_dynamic_split(t1: ptr, t2: ptr, split_ratio: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_tensor_alloc(len);
    var ratio = split_ratio;
    if (ratio < 0.0) { ratio = 0.0; }
    if (ratio > 1.0) { ratio = 1.0; }
    let split_k = math_floor(len * ratio);
    var window = len * 0.02;
    if (window < 1.0) { window = 1.0; }

    var i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let d = (i - split_k) / window;
        var alpha = 0.0;
        if (d > 10.0) {
            alpha = 1.0;
        } else if (d < -10.0) {
            alpha = 0.0;
        } else {
            alpha = 1.0 / (1.0 + exp(-d));
        }
        let merged = v1 * (1.0 - alpha) + v2 * alpha;
        cartan_vec_set_f32(out, i, merged);
        i = i + 1.0;
    }
    return out;
}

// M2N2 Weight Attraction Heuristic Pairing
// Gravitational attraction pull toward the dominant synaptic parameter magnitude
fn fusion_m2n2_attraction_pair(t1: ptr, t2: ptr) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_tensor_alloc(len);
    var i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let mid = (v1 + v2) * 0.5;
        let delta = v2 - v1;
        let s1 = math_abs_val(v1);
        let s2 = math_abs_val(v2);
        let pull = (s2 - s1) / (1.0 + s1 + s2);
        let merged = mid + delta * pull * 0.5;
        cartan_vec_set_f32(out, i, merged);
        i = i + 1.0;
    }
    return out;
}

// M2N2 MAP-Elites Quality-Diversity Genetic Search Crossover
// Blends parent parameters with golden-ratio harmonic exploratory noise for diversity illumination
fn fusion_m2n2_map_elites_crossover(t1: ptr, t2: ptr, diversity_scale: float) -> ptr {
    let len = cartan_vec_len(t1);
    let out = cartan_tensor_alloc(len);
    var i = 0.0;
    while (i < len) {
        let v1 = cartan_vec_get_f32(t1, i);
        let v2 = cartan_vec_get_f32(t2, i);
        let mid = (v1 + v2) * 0.5;
        let spread = math_abs_val(v2 - v1) * 0.5;
        let harmonic_theta = i * 1.61803398875;
        let noise = sin(harmonic_theta) * spread * 0.1 * diversity_scale;
        let merged = mid + noise;
        cartan_vec_set_f32(out, i, merged);
        i = i + 1.0;
    }
    return out;
}

fn fusion_tangent_space_slerp(base_w: ptr, target_w: ptr, alpha: float) -> ptr {
    let len = cartan_vec_len(base_w);
    let out = cartan_tensor_alloc(len);
    
    var i = 0.0;
    while (i < len) {
        let b = cartan_vec_get_f32(base_w, i);
        let t = cartan_vec_get_f32(target_w, i);
        let delta = t - b;
        cartan_vec_set_f32(out, i, b + delta * alpha);
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

// Non-Euclidean Riemannian Exponential Retraction Map: Exp_W(eta * v) = W * cos(theta) + ||W|| * (v / ||v||) * sin(theta)
// Geodesically projects donor weight adjustments onto the Riemannian manifold preserving target volume norm
fn fusion_riemannian_retraction(base_w: ptr, tangent_v: ptr, eta: float) -> ptr {
    let len = cartan_vec_len(base_w);
    let out = cartan_tensor_alloc(len);
    if (len <= 0.0) { return out; }

    var norm_w = 0.0;
    var norm_v = 0.0;
    var i = 0.0;
    while (i < len) {
        let bw = cartan_vec_get_f32(base_w, i);
        let tv = cartan_vec_get_f32(tangent_v, i);
        norm_w = norm_w + bw * bw;
        norm_v = norm_v + tv * tv;
        i = i + 1.0;
    }
    norm_w = sqrt(norm_w + 0.000001);
    norm_v = sqrt(norm_v + 0.000001);

    if (norm_v < 0.00001) {
        // Tangent perturbation negligible; identity copy
        i = 0.0;
        while (i < len) {
            cartan_vec_set_f32(out, i, cartan_vec_get_f32(base_w, i));
            i = i + 1.0;
        }
        return out;
    }

    let theta = eta * norm_v;
    let cos_t = cos(theta);
    let sin_t = sin(theta);
    let inv_norm_v = 1.0 / norm_v;

    // Evaluate Exp_W(eta * v)
    var norm_out = 0.0;
    i = 0.0;
    while (i < len) {
        let bw = cartan_vec_get_f32(base_w, i);
        let tv = cartan_vec_get_f32(tangent_v, i);
        let v_unit = tv * inv_norm_v;
        let r_val = bw * cos_t + norm_w * v_unit * sin_t;
        norm_out = norm_out + r_val * r_val;
        cartan_vec_set_f32(out, i, r_val);
        i = i + 1.0;
    }
    norm_out = sqrt(norm_out + 0.000001);

    // Strict volume norm preservation along Riemannian manifold
    let scale = norm_w / norm_out;
    i = 0.0;
    while (i < len) {
        let val = cartan_vec_get_f32(out, i);
        cartan_vec_set_f32(out, i, val * scale);
        i = i + 1.0;
    }
    return out;
}

// Riemannian Dimension Alignment: Projects arbitrary donor tower dimensions (e.g. 1024-D, 1152-D)
// onto target Lie stream sectors (320-D) or manifold dimensions (2560-D) with energy conservation
fn fusion_riemannian_align(source_w: ptr, target_dim: float) -> ptr {
    let out = cartan_tensor_alloc(target_dim);
    if (target_dim <= 0.0) { return out; }
    let src_len = cartan_vec_len(source_w);
    if (src_len <= 0.0) { return out; }

    var src_energy = 0.0;
    var i = 0.0;
    while (i < src_len) {
        let sv = cartan_vec_get_f32(source_w, i);
        src_energy = src_energy + sv * sv;
        i = i + 1.0;
    }
    let rms_src = sqrt((src_energy / src_len) + 0.000001);

    // Harmonic geodesic interpolation mapping
    var out_energy = 0.0;
    var j = 0.0;
    let ratio = (src_len - 1.0) / (target_dim - 1.0);
    while (j < target_dim) {
        let pos = j * ratio;
        let i0 = math_floor(pos);
        var i1 = i0 + 1.0;
        if (i1 >= src_len) { i1 = src_len - 1.0; }
        let frac = pos - i0;
        let v0 = cartan_vec_get_f32(source_w, i0);
        let v1 = cartan_vec_get_f32(source_w, i1);
        let interp = v0 * (1.0 - frac) + v1 * frac;
        out_energy = out_energy + interp * interp;
        cartan_vec_set_f32(out, j, interp);
        j = j + 1.0;
    }
    let rms_out = sqrt((out_energy / target_dim) + 0.000001);

    // Energy-conserving Riemannian metric scaling
    if (rms_out > 0.000001) {
        let scale = rms_src / rms_out;
        j = 0.0;
        while (j < target_dim) {
            let ov = cartan_vec_get_f32(out, j);
            cartan_vec_set_f32(out, j, ov * scale);
            j = j + 1.0;
        }
    }
    return out;
}

// Contiguous Array-Level Riemannian Retraction for High-Throughput Manifold Layers
fn fusion_riemannian_retract_arrays(base_arr: ptr, tan_arr: ptr, out_arr: ptr, size: float, eta: float) {
    if (base_arr == 0.0 || tan_arr == 0.0 || out_arr == 0.0 || size <= 0.0) { return; }
    var norm_w = 0.0;
    var norm_v = 0.0;
    var i = 0.0;
    while (i < size) {
        let bw = base_arr[i];
        let tv = tan_arr[i];
        norm_w = norm_w + bw * bw;
        norm_v = norm_v + tv * tv;
        i = i + 1.0;
    }
    norm_w = sqrt(norm_w + 0.000001);
    norm_v = sqrt(norm_v + 0.000001);

    if (norm_v < 0.00001) {
        i = 0.0;
        while (i < size) {
            out_arr[i] = base_arr[i];
            i = i + 1.0;
        }
        return;
    }

    let theta = eta * norm_v;
    let cos_t = cos(theta);
    let sin_t = sin(theta);
    let inv_norm_v = 1.0 / norm_v;

    var norm_out = 0.0;
    i = 0.0;
    while (i < size) {
        let bw = base_arr[i];
        let tv = tan_arr[i];
        let v_unit = tv * inv_norm_v;
        let r_val = bw * cos_t + norm_w * v_unit * sin_t;
        norm_out = norm_out + r_val * r_val;
        out_arr[i] = r_val;
        i = i + 1.0;
    }
    norm_out = sqrt(norm_out + 0.000001);
    let scale = norm_w / norm_out;
    i = 0.0;
    while (i < size) {
        out_arr[i] = out_arr[i] * scale;
        i = i + 1.0;
    }
}

