// src/std/audio.cl
// CARTAN Standard Library: Native Audio Processing & Spectral Feature Extraction Module
// Provides STFT / DFT Harmonic Filterbank for E6 x SU(3) Spectral Stream Integration

include "src/std/math.cl";
include "src/std/collections.cl";

extern fn cartan_read_binary_file_data(path: string) -> ptr;
extern fn cartan_get_binary_file_size(path: string) -> float;
extern fn cartan_byte_at(buf: ptr, offset: float) -> float;
extern fn cartan_set_byte(buf: ptr, offset: float, val: float);
extern fn cartan_alloc_binary_buffer(size: float) -> ptr;
extern fn cartan_free_binary_buffer(buf: ptr);
extern fn cartan_write_binary_file(path: string, buf: ptr, size: float) -> float;


struct AudioBuffer {
    sample_rate: float;
    length: float;
    data: ptr;
}

fn audio_create_buffer(length: float, sample_rate: float) -> AudioBuffer {
    var sr = 16000.0;
    if (sample_rate > 0.0) { sr = sample_rate; }
    let data = cartan_tensor_alloc(length);
    return AudioBuffer { sample_rate: sr, length: length, data: data };
}

fn audio_get_sample(buf: AudioBuffer, idx: float) -> float {
    if (idx < 0.0 || idx >= buf.length) { return 0.0; }
    return cartan_vec_get_f32(buf.data, idx);
}

fn audio_set_sample(buf: AudioBuffer, idx: float, val: float) -> float {
    if (idx < 0.0 || idx >= buf.length) { return 0.0; }
    return cartan_vec_set_f32(buf.data, idx, val);
}

// Computes Discrete Fourier Transform (DFT) harmonic energy magnitudes across num_bins frequency bands
fn audio_compute_dft_spectrum(buf: AudioBuffer, num_bins: float) -> ptr {
    var K = 64.0;
    if (num_bins > 0.0) { K = num_bins; }
    let N = buf.length;
    let spectrum = cartan_tensor_alloc(K);
    if (N <= 0.0) { return spectrum; }

    let pi2 = 6.283185307179586;
    var k = 0.0;
    while (k < K) {
        var real_sum = 0.0;
        var imag_sum = 0.0;
        var n = 0.0;
        while (n < N) {
            let x_n = cartan_vec_get_f32(buf.data, n);
            let angle = (pi2 * k * n) / N;
            real_sum = real_sum + (x_n * cos(angle));
            imag_sum = imag_sum - (x_n * sin(angle));
            n = n + 1.0;
        }
        let mag = math_sqrt((real_sum * real_sum) + (imag_sum * imag_sum)) / N;
        cartan_vec_set_f32(spectrum, k, mag);
        k = k + 1.0;
    }
    return spectrum;
}

// Linear Projection of acoustic spectrum (K bins) to 320-D E6 x SU(3) Spectral Stream
fn audio_project_to_spectral_stream(spectrum: ptr, num_bins: float, target_dim: float) -> ptr {
    var dim = 320.0;
    if (target_dim > 0.0) { dim = target_dim; }
    var K = 64.0;
    if (num_bins > 0.0) { K = num_bins; }

    let out = cartan_tensor_alloc(dim);
    var d = 0.0;
    while (d < dim) {
        let bin_idx = math_floor((d * K) / dim);
        let spec_val = cartan_vec_get_f32(spectrum, bin_idx);
        let harmonic = sin((d + 1.0) * 0.1) * 0.7071;
        let proj_val = spec_val * (1.0 + harmonic);
        cartan_vec_set_f32(out, d, proj_val);
        d = d + 1.0;
    }
    return out;
}

fn audio_save_wav(buf: AudioBuffer, path: string) -> float {
    if (buf.length <= 0.0 || buf.data == 0.0) { return 0.0; }
    let n = buf.length;
    let sr = buf.sample_rate;
    let data_size = n * 2.0;
    let file_size = 44.0 + data_size;
    let raw = cartan_alloc_binary_buffer(file_size);
    if (raw == 0.0) { return 0.0; }

    cartan_set_byte(raw, 0.0, 82.0); // 'R'
    cartan_set_byte(raw, 1.0, 73.0); // 'I'
    cartan_set_byte(raw, 2.0, 70.0); // 'F'
    cartan_set_byte(raw, 3.0, 70.0); // 'F'
    let riff_sz = file_size - 8.0;
    cartan_set_byte(raw, 4.0, math_mod(riff_sz, 256.0));
    cartan_set_byte(raw, 5.0, math_mod(floor(riff_sz / 256.0), 256.0));
    cartan_set_byte(raw, 6.0, math_mod(floor(riff_sz / 65536.0), 256.0));
    cartan_set_byte(raw, 7.0, math_mod(floor(riff_sz / 16777216.0), 256.0));
    cartan_set_byte(raw, 8.0, 87.0);  // 'W'
    cartan_set_byte(raw, 9.0, 65.0);  // 'A'
    cartan_set_byte(raw, 10.0, 86.0); // 'V'
    cartan_set_byte(raw, 11.0, 69.0); // 'E'

    cartan_set_byte(raw, 12.0, 102.0); // 'f'
    cartan_set_byte(raw, 13.0, 109.0); // 'm'
    cartan_set_byte(raw, 14.0, 116.0); // 't'
    cartan_set_byte(raw, 15.0, 32.0);  // ' '
    cartan_set_byte(raw, 16.0, 16.0);
    cartan_set_byte(raw, 17.0, 0.0);
    cartan_set_byte(raw, 18.0, 0.0);
    cartan_set_byte(raw, 19.0, 0.0);
    cartan_set_byte(raw, 20.0, 1.0);   // PCM = 1
    cartan_set_byte(raw, 21.0, 0.0);
    cartan_set_byte(raw, 22.0, 1.0);   // Mono = 1
    cartan_set_byte(raw, 23.0, 0.0);

    cartan_set_byte(raw, 24.0, math_mod(sr, 256.0));
    cartan_set_byte(raw, 25.0, math_mod(floor(sr / 256.0), 256.0));
    cartan_set_byte(raw, 26.0, math_mod(floor(sr / 65536.0), 256.0));
    cartan_set_byte(raw, 27.0, math_mod(floor(sr / 16777216.0), 256.0));

    let byte_rate = sr * 2.0;
    cartan_set_byte(raw, 28.0, math_mod(byte_rate, 256.0));
    cartan_set_byte(raw, 29.0, math_mod(floor(byte_rate / 256.0), 256.0));
    cartan_set_byte(raw, 30.0, math_mod(floor(byte_rate / 65536.0), 256.0));
    cartan_set_byte(raw, 31.0, math_mod(floor(byte_rate / 16777216.0), 256.0));

    cartan_set_byte(raw, 32.0, 2.0); // block align
    cartan_set_byte(raw, 33.0, 0.0);
    cartan_set_byte(raw, 34.0, 16.0); // bits per sample
    cartan_set_byte(raw, 35.0, 0.0);

    cartan_set_byte(raw, 36.0, 100.0); // 'd'
    cartan_set_byte(raw, 37.0, 97.0);  // 'a'
    cartan_set_byte(raw, 38.0, 116.0); // 't'
    cartan_set_byte(raw, 39.0, 97.0);  // 'a'
    cartan_set_byte(raw, 40.0, math_mod(data_size, 256.0));
    cartan_set_byte(raw, 41.0, math_mod(floor(data_size / 256.0), 256.0));
    cartan_set_byte(raw, 42.0, math_mod(floor(data_size / 65536.0), 256.0));
    cartan_set_byte(raw, 43.0, math_mod(floor(data_size / 16777216.0), 256.0));

    var i = 0.0;
    while (i < n) {
        let s = audio_get_sample(buf, i);
        let s_clamped = math_clamp(s, -1.0, 1.0);
        let s_int = floor(s_clamped * 32767.0);
        var u16 = s_int;
        if (s_int < 0.0) { u16 = s_int + 65536.0; }
        let b0 = math_mod(u16, 256.0);
        let b1 = math_mod(floor(u16 / 256.0), 256.0);
        cartan_set_byte(raw, 44.0 + (i * 2.0) + 0.0, b0);
        cartan_set_byte(raw, 44.0 + (i * 2.0) + 1.0, b1);
        i = i + 1.0;
    }

    let res = cartan_write_binary_file(path, raw, file_size);
    cartan_free_binary_buffer(raw);
    return res;
}

fn audio_load_wav(path: string) -> AudioBuffer {
    let empty_buf = audio_create_buffer(0.0, 16000.0);
    let raw = cartan_read_binary_file_data(path);
    if (raw == 0.0) { return empty_buf; }
    let file_sz = cartan_get_binary_file_size(path);
    if (file_sz < 44.0) {
        cartan_free_binary_buffer(raw);
        return empty_buf;
    }

    if (cartan_byte_at(raw, 0.0) != 82.0 || cartan_byte_at(raw, 1.0) != 73.0 ||
        cartan_byte_at(raw, 2.0) != 70.0 || cartan_byte_at(raw, 3.0) != 70.0 ||
        cartan_byte_at(raw, 8.0) != 87.0 || cartan_byte_at(raw, 9.0) != 65.0 ||
        cartan_byte_at(raw, 10.0) != 86.0 || cartan_byte_at(raw, 11.0) != 69.0) {
        cartan_free_binary_buffer(raw);
        return empty_buf;
    }

    var pos = 12.0;
    var sample_rate = 16000.0;
    var channels = 1.0;
    var bits_per_sample = 16.0;
    var data_pos = 0.0;
    var data_size = 0.0;

    while (pos + 8.0 <= file_sz) {
        let id0 = cartan_byte_at(raw, pos + 0.0);
        let id1 = cartan_byte_at(raw, pos + 1.0);
        let id2 = cartan_byte_at(raw, pos + 2.0);
        let id3 = cartan_byte_at(raw, pos + 3.0);
        let chk_sz = cartan_byte_at(raw, pos + 4.0) +
                     cartan_byte_at(raw, pos + 5.0) * 256.0 +
                     cartan_byte_at(raw, pos + 6.0) * 65536.0 +
                     cartan_byte_at(raw, pos + 7.0) * 16777216.0;

        if (id0 == 102.0 && id1 == 109.0 && id2 == 116.0 && id3 == 32.0) {
            channels = cartan_byte_at(raw, pos + 10.0) + cartan_byte_at(raw, pos + 11.0) * 256.0;
            sample_rate = cartan_byte_at(raw, pos + 12.0) +
                          cartan_byte_at(raw, pos + 13.0) * 256.0 +
                          cartan_byte_at(raw, pos + 14.0) * 65536.0 +
                          cartan_byte_at(raw, pos + 15.0) * 16777216.0;
            bits_per_sample = cartan_byte_at(raw, pos + 22.0) + cartan_byte_at(raw, pos + 23.0) * 256.0;
        }

        if (id0 == 100.0 && id1 == 97.0 && id2 == 116.0 && id3 == 97.0) {
            data_pos = pos + 8.0;
            data_size = chk_sz;
            break;
        }

        pos = pos + 8.0 + chk_sz;
    }

    if (data_pos == 0.0 || data_size <= 0.0 || channels <= 0.0 || bits_per_sample != 16.0) {
        cartan_free_binary_buffer(raw);
        return empty_buf;
    }

    let bytes_per_sample = bits_per_sample / 8.0;
    let block_align = channels * bytes_per_sample;
    let total_frames = floor(data_size / block_align);

    let audio_buf = audio_create_buffer(total_frames, sample_rate);
    var i = 0.0;
    while (i < total_frames) {
        let frame_offset = data_pos + (i * block_align);
        if (frame_offset + block_align <= file_sz) {
            let b0 = cartan_byte_at(raw, frame_offset + 0.0);
            let b1 = cartan_byte_at(raw, frame_offset + 1.0);
            var u16 = b0 + b1 * 256.0;
            var s = 0.0;
            if (u16 >= 32768.0) { s = (u16 - 65536.0) / 32768.0; } else { s = u16 / 32768.0; }

            if (channels >= 2.0) {
                let rb0 = cartan_byte_at(raw, frame_offset + 2.0);
                let rb1 = cartan_byte_at(raw, frame_offset + 3.0);
                var ru16 = rb0 + rb1 * 256.0;
                var rs = 0.0;
                if (ru16 >= 32768.0) { rs = (ru16 - 65536.0) / 32768.0; } else { rs = ru16 / 32768.0; }
                s = (s + rs) * 0.5;
            }
            audio_set_sample(audio_buf, i, s);
        }
        i = i + 1.0;
    }

    cartan_free_binary_buffer(raw);
    return audio_buf;
}

