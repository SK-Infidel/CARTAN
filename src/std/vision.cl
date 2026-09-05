// src/std/vision.cl
// CARTAN Standard Library: Native Computer Vision & Image Processing Module

include "src/std/tensor.cl";
include "src/std/math.cl";
include "src/std/string.cl";

extern fn cartan_read_binary_file_data(path: string) -> ptr;
extern fn cartan_get_binary_file_size(path: string) -> float;
extern fn cartan_byte_at(ptr: ptr, offset: float) -> float;
extern fn cartan_set_byte(ptr: ptr, offset: float, val: float);
extern fn cartan_alloc_binary_buffer(size: float) -> ptr;
extern fn cartan_free_binary_buffer(ptr: ptr);
extern fn cartan_write_binary_file(path: string, buf: ptr, size: float) -> float;
extern fn cartan_c_int_to_string(val: float) -> string;


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

fn vision_skip_ppm_whitespace(buf: ptr, pos: float, max_len: float) -> float {
    var p = pos;
    while (p < max_len) {
        let b = cartan_byte_at(buf, p);
        if (b == 35.0) {
            while (p < max_len && cartan_byte_at(buf, p) != 10.0) {
                p = p + 1.0;
            }
            if (p < max_len) { p = p + 1.0; }
        } else if (b == 32.0 || b == 9.0 || b == 10.0 || b == 13.0) {
            p = p + 1.0;
        } else {
            return p;
        }
    }
    return p;
}

fn vision_parse_ppm_int(buf: ptr, pos: float, max_len: float, out_val_ptr: ptr) -> float {
    var p = vision_skip_ppm_whitespace(buf, pos, max_len);
    var val = 0.0;
    while (p < max_len) {
        let b = cartan_byte_at(buf, p);
        if (b >= 48.0 && b <= 57.0) {
            val = val * 10.0 + (b - 48.0);
            p = p + 1.0;
        } else {
            break;
        }
    }
    cartan_vec_set_f32(out_val_ptr, 0.0, val);
    return p;
}

fn vision_save_ppm(img: Image, path: string) -> float {
    if (img.width <= 0.0 || img.height <= 0.0 || img.data == 0.0) { return 0.0; }
    let w = img.width;
    let h = img.height;
    let header_str = cartan_string_concat("P6\n", cartan_string_concat(cartan_c_int_to_string(w), cartan_string_concat(" ", cartan_string_concat(cartan_c_int_to_string(h), "\n255\n"))));
    let h_len = cartan_string_length(header_str);
    let total_bytes = h_len + (w * h * 3.0);
    let buf = cartan_alloc_binary_buffer(total_bytes);
    if (buf == 0.0) { return 0.0; }

    var i = 0.0;
    while (i < h_len) {
        let ch = c_cartan_string_char_at(header_str, i);
        cartan_set_byte(buf, i, ch);
        i = i + 1.0;
    }

    var y = 0.0;
    var out_idx = h_len;
    while (y < h) {
        var x = 0.0;
        while (x < w) {
            let r = math_clamp(vision_get_pixel(img, x, y, 0.0), 0.0, 255.0);
            let g = math_clamp(vision_get_pixel(img, x, y, 1.0), 0.0, 255.0);
            let b = math_clamp(vision_get_pixel(img, x, y, 2.0), 0.0, 255.0);
            cartan_set_byte(buf, out_idx + 0.0, r);
            cartan_set_byte(buf, out_idx + 1.0, g);
            cartan_set_byte(buf, out_idx + 2.0, b);
            out_idx = out_idx + 3.0;
            x = x + 1.0;
        }
        y = y + 1.0;
    }

    let res = cartan_write_binary_file(path, buf, total_bytes);
    cartan_free_binary_buffer(buf);
    return res;
}

fn vision_load_ppm(path: string) -> Image {
    let empty_img = vision_create_image(0.0, 0.0, 0.0);
    let raw_buf = cartan_read_binary_file_data(path);
    if (raw_buf == 0.0) { return empty_img; }
    let file_sz = cartan_get_binary_file_size(path);
    if (file_sz < 10.0) {
        cartan_free_binary_buffer(raw_buf);
        return empty_img;
    }

    if (cartan_byte_at(raw_buf, 0.0) != 80.0 || cartan_byte_at(raw_buf, 1.0) != 54.0) {
        cartan_free_binary_buffer(raw_buf);
        return empty_img;
    }

    let temp_box = cartan_tensor_alloc(1.0);
    var pos = vision_parse_ppm_int(raw_buf, 2.0, file_sz, temp_box);
    let w = cartan_vec_get_f32(temp_box, 0.0);

    pos = vision_parse_ppm_int(raw_buf, pos, file_sz, temp_box);
    let h = cartan_vec_get_f32(temp_box, 0.0);

    pos = vision_parse_ppm_int(raw_buf, pos, file_sz, temp_box);
    let max_v = cartan_vec_get_f32(temp_box, 0.0);

    if (pos < file_sz) {
        let b = cartan_byte_at(raw_buf, pos);
        if (b == 32.0 || b == 9.0 || b == 10.0 || b == 13.0) {
            pos = pos + 1.0;
        }
    }

    if (w <= 0.0 || h <= 0.0 || pos >= file_sz) {
        cartan_free_binary_buffer(raw_buf);
        return empty_img;
    }

    let img = vision_create_image(w, h, 3.0);
    var y = 0.0;
    var in_idx = pos;
    while (y < h) {
        var x = 0.0;
        while (x < w) {
            if (in_idx + 2.0 < file_sz) {
                let r = cartan_byte_at(raw_buf, in_idx + 0.0);
                let g = cartan_byte_at(raw_buf, in_idx + 1.0);
                let b = cartan_byte_at(raw_buf, in_idx + 2.0);
                vision_set_pixel(img, x, y, 0.0, r);
                vision_set_pixel(img, x, y, 1.0, g);
                vision_set_pixel(img, x, y, 2.0, b);
            }
            in_idx = in_idx + 3.0;
            x = x + 1.0;
        }
        y = y + 1.0;
    }

    cartan_free_binary_buffer(raw_buf);
    return img;
}

fn vision_save_bmp(img: Image, path: string) -> float {
    if (img.width <= 0.0 || img.height <= 0.0 || img.data == 0.0) { return 0.0; }
    let w = img.width;
    let h = img.height;
    let row_stride = floor((w * 3.0 + 3.0) / 4.0) * 4.0;
    let pixel_data_size = row_stride * h;
    let file_size = 54.0 + pixel_data_size;
    let buf = cartan_alloc_binary_buffer(file_size);
    if (buf == 0.0) { return 0.0; }

    // 1. BITMAPFILEHEADER (14 bytes)
    cartan_set_byte(buf, 0.0, 66.0); // 'B'
    cartan_set_byte(buf, 1.0, 77.0); // 'M'
    let fs_int = file_size;
    cartan_set_byte(buf, 2.0, math_mod(fs_int, 256.0));
    cartan_set_byte(buf, 3.0, math_mod(floor(fs_int / 256.0), 256.0));
    cartan_set_byte(buf, 4.0, math_mod(floor(fs_int / 65536.0), 256.0));
    cartan_set_byte(buf, 5.0, math_mod(floor(fs_int / 16777216.0), 256.0));
    cartan_set_byte(buf, 6.0, 0.0);
    cartan_set_byte(buf, 7.0, 0.0);
    cartan_set_byte(buf, 8.0, 0.0);
    cartan_set_byte(buf, 9.0, 0.0);
    cartan_set_byte(buf, 10.0, 54.0);
    cartan_set_byte(buf, 11.0, 0.0);
    cartan_set_byte(buf, 12.0, 0.0);
    cartan_set_byte(buf, 13.0, 0.0);

    // 2. BITMAPINFOHEADER (40 bytes)
    cartan_set_byte(buf, 14.0, 40.0);
    cartan_set_byte(buf, 15.0, 0.0);
    cartan_set_byte(buf, 16.0, 0.0);
    cartan_set_byte(buf, 17.0, 0.0);
    cartan_set_byte(buf, 18.0, math_mod(w, 256.0));
    cartan_set_byte(buf, 19.0, math_mod(floor(w / 256.0), 256.0));
    cartan_set_byte(buf, 20.0, math_mod(floor(w / 65536.0), 256.0));
    cartan_set_byte(buf, 21.0, math_mod(floor(w / 16777216.0), 256.0));
    cartan_set_byte(buf, 22.0, math_mod(h, 256.0));
    cartan_set_byte(buf, 23.0, math_mod(floor(h / 256.0), 256.0));
    cartan_set_byte(buf, 24.0, math_mod(floor(h / 65536.0), 256.0));
    cartan_set_byte(buf, 25.0, math_mod(floor(h / 16777216.0), 256.0));
    cartan_set_byte(buf, 26.0, 1.0);
    cartan_set_byte(buf, 27.0, 0.0);
    cartan_set_byte(buf, 28.0, 24.0);
    cartan_set_byte(buf, 29.0, 0.0);
    cartan_set_byte(buf, 30.0, 0.0);
    cartan_set_byte(buf, 31.0, 0.0);
    cartan_set_byte(buf, 32.0, 0.0);
    cartan_set_byte(buf, 33.0, 0.0);
    cartan_set_byte(buf, 34.0, math_mod(pixel_data_size, 256.0));
    cartan_set_byte(buf, 35.0, math_mod(floor(pixel_data_size / 256.0), 256.0));
    cartan_set_byte(buf, 36.0, math_mod(floor(pixel_data_size / 65536.0), 256.0));
    cartan_set_byte(buf, 37.0, math_mod(floor(pixel_data_size / 16777216.0), 256.0));

    // 3. Bottom-up scanlines, BGR
    var y = 0.0;
    while (y < h) {
        let file_row = h - 1.0 - y;
        let row_start = 54.0 + (file_row * row_stride);
        var x = 0.0;
        while (x < w) {
            let r = math_clamp(vision_get_pixel(img, x, y, 0.0), 0.0, 255.0);
            let g = math_clamp(vision_get_pixel(img, x, y, 1.0), 0.0, 255.0);
            let b = math_clamp(vision_get_pixel(img, x, y, 2.0), 0.0, 255.0);
            let px_off = row_start + (x * 3.0);
            cartan_set_byte(buf, px_off + 0.0, b);
            cartan_set_byte(buf, px_off + 1.0, g);
            cartan_set_byte(buf, px_off + 2.0, r);
            x = x + 1.0;
        }
        y = y + 1.0;
    }

    let res = cartan_write_binary_file(path, buf, file_size);
    cartan_free_binary_buffer(buf);
    return res;
}

fn vision_load_bmp(path: string) -> Image {
    let empty_img = vision_create_image(0.0, 0.0, 0.0);
    let raw_buf = cartan_read_binary_file_data(path);
    if (raw_buf == 0.0) { return empty_img; }
    let file_sz = cartan_get_binary_file_size(path);
    if (file_sz < 54.0) {
        cartan_free_binary_buffer(raw_buf);
        return empty_img;
    }

    if (cartan_byte_at(raw_buf, 0.0) != 66.0 || cartan_byte_at(raw_buf, 1.0) != 77.0) {
        cartan_free_binary_buffer(raw_buf);
        return empty_img;
    }

    let data_offset = cartan_byte_at(raw_buf, 10.0) + cartan_byte_at(raw_buf, 11.0) * 256.0 + cartan_byte_at(raw_buf, 12.0) * 65536.0 + cartan_byte_at(raw_buf, 13.0) * 16777216.0;
    let w = cartan_byte_at(raw_buf, 18.0) + cartan_byte_at(raw_buf, 19.0) * 256.0 + cartan_byte_at(raw_buf, 20.0) * 65536.0 + cartan_byte_at(raw_buf, 21.0) * 16777216.0;
    let raw_h = cartan_byte_at(raw_buf, 22.0) + cartan_byte_at(raw_buf, 23.0) * 256.0 + cartan_byte_at(raw_buf, 24.0) * 65536.0 + cartan_byte_at(raw_buf, 25.0) * 16777216.0;
    var is_top_down = 0.0;
    var h = raw_h;
    if (raw_h > 2147483648.0) {
        h = 4294967296.0 - raw_h;
        is_top_down = 1.0;
    }

    let bpp = cartan_byte_at(raw_buf, 28.0) + cartan_byte_at(raw_buf, 29.0) * 256.0;
    if (bpp != 24.0 && bpp != 32.0) {
        cartan_free_binary_buffer(raw_buf);
        return empty_img;
    }
    let bytes_per_pixel = bpp / 8.0;
    let row_stride = floor((w * bytes_per_pixel + 3.0) / 4.0) * 4.0;

    let img = vision_create_image(w, h, 3.0);
    var y = 0.0;
    while (y < h) {
        var file_row = h - 1.0 - y;
        if (is_top_down == 1.0) { file_row = y; }
        let row_start = data_offset + (file_row * row_stride);
        var x = 0.0;
        while (x < w) {
            let px_off = row_start + (x * bytes_per_pixel);
            if (px_off + 2.0 < file_sz) {
                let b = cartan_byte_at(raw_buf, px_off + 0.0);
                let g = cartan_byte_at(raw_buf, px_off + 1.0);
                let r = cartan_byte_at(raw_buf, px_off + 2.0);
                vision_set_pixel(img, x, y, 0.0, r);
                vision_set_pixel(img, x, y, 1.0, g);
                vision_set_pixel(img, x, y, 2.0, b);
            }
            x = x + 1.0;
        }
        y = y + 1.0;
    }

    cartan_free_binary_buffer(raw_buf);
    return img;
}

