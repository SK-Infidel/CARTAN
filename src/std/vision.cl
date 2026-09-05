// src/std/vision.cl
// CARTAN Standard Library: Native Computer Vision & Image Processing Module

include "src/std/tensor.cl";

struct Image {
    width: float;
    height: float;
    channels: float;
    data: ptr;
}

struct BoundingBox {
    x_min: float;
    y_min: float;
    x_max: float;
    y_max: float;
    confidence: float;
    class_id: float;
}

fn vision_create_image(w: float, h: float, c: float) -> Image {
    let size = w * h * c;
    let data = cartan_tensor_alloc(size);
    return Image { width: w, height: h, channels: c, data: data };
}

fn vision_image_to_tensor(img: Image) -> ptr {
    return img.data;
}

fn vision_tensor_to_image(t: ptr, w: float, h: float, c: float) -> Image {
    return Image { width: w, height: h, channels: c, data: t };
}

fn vision_normalize_standard(img: Image) -> ptr {
    let size = img.width * img.height * img.channels;
    let t = cartan_tensor_alloc(size);
    var i = 0.0;
    while (i < size) {
        let val = cartan_tree_get_f32(img.data, i);
        let norm_val = val / 255.0;
        cartan_tree_set(t, i, norm_val);
        i = i + 1.0;
    }
    return t;
}

fn vision_normalize(img: Image, mean_r: float, mean_g: float, mean_b: float, std_r: float, std_g: float, std_b: float) -> Image {
    var sr = 1.0;
    if (std_r != 0.0) { sr = std_r; }
    var sg = 1.0;
    if (std_g != 0.0) { sg = std_g; }
    var sb = 1.0;
    if (std_b != 0.0) { sb = std_b; }

    let plane_size = img.width * img.height;
    let out_img = vision_create_image(img.width, img.height, img.channels);
    var i = 0.0;
    while (i < plane_size) {
        let r = cartan_tree_get_f32(img.data, i);
        let norm_r = (r - mean_r) / sr;
        cartan_tree_set(out_img.data, i, norm_r);

        if (img.channels >= 2.0) {
            let g = cartan_tree_get_f32(img.data, i + plane_size);
            let norm_g = (g - mean_g) / sg;
            cartan_tree_set(out_img.data, i + plane_size, norm_g);
        }

        if (img.channels >= 3.0) {
            let b = cartan_tree_get_f32(img.data, i + plane_size * 2.0);
            let norm_b = (b - mean_b) / sb;
            cartan_tree_set(out_img.data, i + plane_size * 2.0, norm_b);
        }
        i = i + 1.0;
    }
    return out_img;
}

fn vision_resize_bilinear(img: Image, target_w: float, target_h: float) -> Image {
    let out_img = vision_create_image(target_w, target_h, img.channels);
    let scale_x = img.width / target_w;
    let scale_y = img.height / target_h;

    var y = 0.0;
    while (y < target_h) {
        var x = 0.0;
        while (x < target_w) {
            let src_x = x * scale_x;
            let src_y = y * scale_y;
            var c = 0.0;
            while (c < img.channels) {
                let src_idx = (src_y * img.width + src_x) * img.channels + c;
                let val = cartan_tree_get_f32(img.data, src_idx);
                let dst_idx = (y * target_w + x) * img.channels + c;
                cartan_tree_set(out_img.data, dst_idx, val);
                c = c + 1.0;
            }
            x = x + 1.0;
        }
        y = y + 1.0;
    }
    return out_img;
}

fn vision_conv2d(img: Image, kernel: ptr, kernel_size: float) -> Image {
    let out_img = vision_create_image(img.width, img.height, img.channels);
    let pad = (kernel_size - 1.0) / 2.0;

    var y = pad;
    while (y < img.height - pad) {
        var x = pad;
        while (x < img.width - pad) {
            var c = 0.0;
            while (c < img.channels) {
                var acc = 0.0;
                var ky = 0.0;
                while (ky < kernel_size) {
                    var kx = 0.0;
                    while (kx < kernel_size) {
                        let px = x + kx - pad;
                        let py = y + ky - pad;
                        let p_idx = (py * img.width + px) * img.channels + c;
                        let p_val = cartan_tree_get_f32(img.data, p_idx);
                        let k_idx = ky * kernel_size + kx;
                        let k_val = cartan_tree_get_f32(kernel, k_idx);
                        acc = acc + p_val * k_val;
                        kx = kx + 1.0;
                    }
                    ky = ky + 1.0;
                }
                let out_idx = (y * img.width + x) * img.channels + c;
                cartan_tree_set(out_img.data, out_idx, acc);
                c = c + 1.0;
            }
            x = x + 1.0;
        }
        y = y + 1.0;
    }
    return out_img;
}

fn vision_get_pixel(img: Image, x: float, y: float, c: float) -> float {
    if (x < 0.0 || x >= img.width || y < 0.0 || y >= img.height || c < 0.0 || c >= img.channels) {
        return 0.0;
    }
    let idx = (y * img.width + x) * img.channels + c;
    return cartan_vec_get_f32(img.data, idx);
}

fn vision_set_pixel(img: Image, x: float, y: float, c: float, val: float) -> float {
    if (x < 0.0 || x >= img.width || y < 0.0 || y >= img.height || c < 0.0 || c >= img.channels) {
        return 0.0;
    }
    let idx = (y * img.width + x) * img.channels + c;
    return cartan_vec_set_f32(img.data, idx, val);
}

// Extract a P x P receptive field patch from an Image as a flat tensor (P * P * C floats)
fn vision_extract_patch(img: Image, start_x: float, start_y: float, patch_w: float, patch_h: float) -> ptr {
    let total_feats = patch_w * patch_h * img.channels;
    let patch = cartan_tensor_alloc(total_feats);
    var py = 0.0;
    var out_idx = 0.0;
    while (py < patch_h) {
        var px = 0.0;
        while (px < patch_w) {
            let img_x = start_x + px;
            let img_y = start_y + py;
            var c = 0.0;
            while (c < img.channels) {
                var p_val = 0.0;
                if (img_x < img.width && img_y < img.height) {
                    let p_idx = (img_y * img.width + img_x) * img.channels + c;
                    p_val = cartan_vec_get_f32(img.data, p_idx) / 255.0;
                }
                cartan_vec_set_f32(patch, out_idx, p_val);
                out_idx = out_idx + 1.0;
                c = c + 1.0;
            }
            px = px + 1.0;
        }
        py = py + 1.0;
    }
    return patch;
}

// Linear projection of visual patch features (e.g. 768-D) to 320-D SO(10) x SU(4) Eikonal Stream
fn vision_project_to_eikonal_stream(patch_tensor: ptr, patch_size: float, target_dim: float) -> ptr {
    var dim = 320.0;
    if (target_dim > 0.0) { dim = target_dim; }
    var P = 768.0;
    if (patch_size > 0.0) { P = patch_size; }

    let out = cartan_tensor_alloc(dim);
    var d = 0.0;
    while (d < dim) {
        let feat_idx = math_floor((d * P) / dim);
        let pixel_val = cartan_vec_get_f32(patch_tensor, feat_idx);
        // Eikonal geodesic speed modulation
        let speed_factor = 1.0 / (1.0 + (pixel_val * pixel_val * 0.05));
        let proj_val = pixel_val * speed_factor;
        cartan_vec_set_f32(out, d, proj_val);
        d = d + 1.0;
    }
    return out;
}
