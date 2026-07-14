@group(0) @binding(0) var<storage, read> a_data: array<f32>;
@group(0) @binding(1) var<storage, read> b_data: array<f32>;
@group(0) @binding(2) var<storage, read_write> out_data: array<f32>;

struct ShapeInfo {
    M: u32,
    K: u32,
    N: u32,
}
@group(0) @binding(3) var<uniform> shape: ShapeInfo;

@compute @workgroup_size(16, 16)
fn matmul(
    @builtin(global_invocation_id) global_id: vec3<u32>
) {
    let row = global_id.y;
    let col = global_id.x;

    if (row >= shape.M || col >= shape.N) {
        return;
    }

    var sum = 0.0;
    for (var k = 0u; k < shape.K; k = k + 1u) {
        sum = sum + a_data[row * shape.K + k] * b_data[k * shape.N + col];
    }
    out_data[row * shape.N + col] = sum;
}

@compute @workgroup_size(256)
fn add(
    @builtin(global_invocation_id) global_id: vec3<u32>
) {
    let i = global_id.x;
    out_data[i] = a_data[i] + b_data[i];
}

@compute @workgroup_size(256)
fn mse_loss(
    @builtin(global_invocation_id) global_id: vec3<u32>
) {
    let i = global_id.x;
    let diff = a_data[i] - b_data[i];
    out_data[i] = diff * diff;
}
