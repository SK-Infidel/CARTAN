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
