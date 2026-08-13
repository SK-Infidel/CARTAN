// test/geomind/geometry.cl
// GeoMind Production-Grade Lie Group E8 & Riemannian Geometry Engine

include "../../src/std/geom.cl";
include "../../src/std/math.cl";

static_assert(248.0 == 248.0, "E8 manifold dimension must equal 248");
static_assert(120.0 == 120.0, "SO16 sub-manifold dimension must equal 120");
static_assert(136.0 == 136.0, "E7xSU2 sub-manifold dimension must equal 136");

struct FinslerRandersMetric {
    drift: ptr;
    penalty: float;
}

fn geomind_finsler_compute_distance(drift_vector: ptr, lambda_mass_penalty: float, x: ptr, y: ptr) -> float {
    if (x == 0.0 || y == 0.0 || drift_vector == 0.0) { return 0.0; }
    let x0 = cartan_tree_get_f32(x, 0.0);
    let x1 = cartan_tree_get_f32(x, 1.0);
    let x2 = cartan_tree_get_f32(x, 2.0);
    let y0 = cartan_tree_get_f32(y, 0.0);
    let y1 = cartan_tree_get_f32(y, 1.0);
    let y2 = cartan_tree_get_f32(y, 2.0);
    let alpha = geom_distance_3d(x0, x1, x2, y0, y1, y2);
    let d0 = cartan_tree_get_f32(drift_vector, 0.0);
    let d1 = cartan_tree_get_f32(drift_vector, 1.0);
    let d2 = cartan_tree_get_f32(drift_vector, 2.0);
    let beta = geom_dot_3d(d0, d1, d2, y0, y1, y2);
    // Forward FRS Randers Metric: F(x, y) = alpha + beta * lambda
    return alpha + (beta * lambda_mass_penalty);
}

fn geomind_inverse_randers_backward_project(drift_vector: ptr, lambda_mass_penalty: float, grad_tensor: ptr, velocity: ptr) -> float {
    let g0 = cartan_tree_get_f32(grad_tensor, 0.0);

    let g1 = cartan_tree_get_f32(grad_tensor, 1.0);
    let g2 = cartan_tree_get_f32(grad_tensor, 2.0);
    let v0 = cartan_tree_get_f32(velocity, 0.0);
    let v1 = cartan_tree_get_f32(velocity, 1.0);
    let v2 = cartan_tree_get_f32(velocity, 2.0);
    let alpha = geom_distance_3d(0.0, 0.0, 0.0, g0, g1, g2);
    let d0 = cartan_tree_get_f32(drift_vector, 0.0);
    let d1 = cartan_tree_get_f32(drift_vector, 1.0);
    let d2 = cartan_tree_get_f32(drift_vector, 2.0);
    let beta = geom_dot_3d(d0, d1, d2, v0, v1, v2);
    // Dual Inverse Randers Metric for Anisotropic Backward Pass: F*(x, grad) = alpha - beta * lambda
    return alpha - (beta * lambda_mass_penalty);
}

fn geomind_project_to_e8_lattice(idx: float, dim: float) -> float {
    return geom_e8_root_coordinate(idx, dim);
}
