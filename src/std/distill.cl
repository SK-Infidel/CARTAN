// CARTAN Standard Library: Teacher-Student Knowledge Distillation Module
// Layer 1 Module: std::distill

include "src/std/tensor.cl";
include "src/std/math.cl";

fn distill_kl_divergence_loss(teacher_logits: ptr, student_logits: ptr, temp: float) -> float {
    let len = cartan_vec_len(teacher_logits);
    if (len == 0.0) { return 0.0; }
    var t = temp;
    if (temp <= 0.0) { t = 1.0; }

    var sum_p = 0.0;
    var sum_q = 0.0;
    var i = 0.0;
    while (i < len) {
        sum_p = sum_p + exp(cartan_vec_get_f32(teacher_logits, i) / t);
        sum_q = sum_q + exp(cartan_vec_get_f32(student_logits, i) / t);
        i = i + 1.0;
    }
    if (sum_p <= 0.0) { sum_p = 1.0; }
    if (sum_q <= 0.0) { sum_q = 1.0; }

    var loss = 0.0;
    i = 0.0;
    while (i < len) {
        let p = exp(cartan_vec_get_f32(teacher_logits, i) / t) / sum_p;
        let q = exp(cartan_vec_get_f32(student_logits, i) / t) / sum_q;
        if (p > 0.000001) {
            let kl = p * log(p / (q + 0.000001));
            loss = loss + kl;
        }
        i = i + 1.0;
    }
    return loss * (t * t);
}

fn distill_logit_matching_step(teacher_logits: ptr, student_logits: ptr, temp: float) -> float {
    return distill_kl_divergence_loss(teacher_logits, student_logits, temp);
}

fn distill_sparse_hierarchy_loss(tree_distance: float, manifold_distance: float, top_k_mask: float) -> float {
    if (top_k_mask == 0.0) { return 0.0; }
    let diff = tree_distance - manifold_distance;
    return diff * diff * 0.01;
}

fn distill_kl_divergence_arrays(teacher_logits: ptr, student_logits: ptr, size: float, temp: float) -> float {
    if (teacher_logits == 0.0 || student_logits == 0.0 || size <= 0.0) { return 0.0; }
    var t = temp;
    if (temp <= 0.0) { t = 1.0; }

    var sum_p = 0.0;
    var sum_q = 0.0;
    var i = 0.0;
    while (i < size) {
        sum_p = sum_p + exp(teacher_logits[i] / t);
        sum_q = sum_q + exp(student_logits[i] / t);
        i = i + 1.0;
    }
    if (sum_p <= 0.0) { sum_p = 1.0; }
    if (sum_q <= 0.0) { sum_q = 1.0; }

    var loss = 0.0;
    i = 0.0;
    while (i < size) {
        let p = exp(teacher_logits[i] / t) / sum_p;
        let q = exp(student_logits[i] / t) / sum_q;
        if (p > 0.000001) {
            let kl = p * log(p / (q + 0.000001));
            loss = loss + kl;
        }
        i = i + 1.0;
    }
    return loss * (t * t);
}

fn distill_feature_matching_mse(teacher_features: ptr, student_features: ptr, dim: float) -> float {
    if (teacher_features == 0.0 || student_features == 0.0 || dim <= 0.0) { return 0.0; }
    var sum_sq = 0.0;
    var i = 0.0;
    while (i < dim) {
        let diff = teacher_features[i] - student_features[i];
        sum_sq = sum_sq + diff * diff;
        i = i + 1.0;
    }
    return sum_sq / dim;
}

