// src/std/audio.cl
// CARTAN Standard Library: Native Audio Processing & Spectral Feature Extraction Module
// Provides STFT / DFT Harmonic Filterbank for E6 x SU(3) Spectral Stream Integration

include "src/std/math.cl";
include "src/std/collections.cl";

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
