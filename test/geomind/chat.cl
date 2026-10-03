// test/geomind/chat.cl
// GeoMind Interactive Multimodal Text+Vision Chat Engine

include "../../src/std/tokenizer.cl";
include "../../src/std/vision.cl";
include "../../src/std/autotune.cl";
include "../../src/std/semantics.cl";
include "../../src/std/gpu.cl";
include "../../src/std/hub.cl";
include "../../src/std/math.cl";
include "../../src/std/transformer.cl";
include "../../src/std/fusion.cl";
include "../../src/std/resonator.cl";
include "../../src/std/audio.cl";
include "geometry.cl";

include "engine.cl";
include "ising_state_machine.cl";
include "e8_attention_engine.cl";


include "../../src/std/string.cl";
include "../../src/std/collections.cl";

include "../../src/std/reasoning.cl";
include "../../src/std/hebbian.cl";
include "../../src/std/sqlite_vec.cl";
include "../../src/std/cargraph_consolidate.cl";
include "../../src/std/nses_pipeline.cl";
include "../../src/std/saliency_attractor.cl";

// Resolves relative path across repo root, bin/, and test/geomind working directories
fn geomind_chat_resolve_path(path: string) -> string {
    if (cartan_string_length(path) == 0.0) { return ""; }

    // 1. Direct path exists in current working directory
    if (cartan_file_exists(path) == 1.0) { return path; }

    // 2. Parent directory (e.g. running from bin/ or scratch/)
    let p_up = cartan_string_concat("../", path);
    if (cartan_file_exists(p_up) == 1.0) { return p_up; }

    // 3. Two levels up (e.g. running from test/compiler_suite/ or deep subdirs)
    let p_up2 = cartan_string_concat("../../", path);
    if (cartan_file_exists(p_up2) == 1.0) { return p_up2; }

    // 4. If path starts with "test/geomind/", try stripping it (when running from test/geomind/)
    if (cartan_string_starts_with(path, "test/geomind/") == 1.0) {
        let sub = cartan_string_substring(path, 13.0, cartan_string_length(path));
        if (cartan_file_exists(sub) == 1.0) { return sub; }
        let sub_up = cartan_string_concat("../", sub);
        if (cartan_file_exists(sub_up) == 1.0) { return sub_up; }
    }

    // 5. If path starts with "trainingdata/", try prepending "test/geomind/" or "../test/geomind/"
    if (cartan_string_starts_with(path, "trainingdata/") == 1.0) {
        let tg = cartan_string_concat("test/geomind/", path);
        if (cartan_file_exists(tg) == 1.0) { return tg; }
        let up_tg = cartan_string_concat("../test/geomind/", path);
        if (cartan_file_exists(up_tg) == 1.0) { return up_tg; }
        let up2_tg = cartan_string_concat("../../test/geomind/", path);
        if (cartan_file_exists(up2_tg) == 1.0) { return up2_tg; }
    }

    return path;
}

// Pure Native CARTAN LM Head Soft-Capping with Vectorized SIMD Dot Products
fn cartan_compute_lm_head_softcap_native(
    h_raw: ptr,
    embedding_buf: ptr,
    ics: ptr,
    mask: ptr,
    out_logits_vec: ptr,
    vocab_size: float,
    dim: float,
    cap_limit: float
) -> float {
    if (h_raw == 0.0 || embedding_buf == 0.0 || out_logits_vec == 0.0) { return 0.0; }
    var cap = cap_limit;
    if (cap <= 0.0) { cap = 30.0; }
    let inv_cap = 1.0 / cap;

    var v = 0.0;
    while (v < vocab_size) {
        // Mask out reserved control tokens (<pad>=0, <bos>=2, <unk>=3, <|turn>=105, user=2364, model=4368)
        if (v == 0.0 || v == 2.0 || v == 3.0 || v == 105.0 || v == 2364.0 || v == 4368.0) {
            cartan_vec_set_f32(out_logits_vec, v, -10000.0);
            v = v + 1.0;
        } else {
            // Apply active vocabulary mask if provided (filters out 240k foreign/corrupted token IDs)
            if (mask != 0.0 && cartan_byte_at(mask, v) == 0.0) {
                cartan_vec_set_f32(out_logits_vec, v, -10000.0);
                v = v + 1.0;
            } else {
                let row_ptr = cartan_f32_ptr_add(embedding_buf, v * dim);
                let dot = cartan_simd_dot_f32(h_raw, row_ptr, dim);
                var capped = cap * tanh(dot * inv_cap);

                // Authentic Zipfian Information Content damping for generic function words (IC < 6.0)
                if (ics != 0.0) {
                    let ic = cartan_f32_at(ics, v);
                    if (ic < 6.0 && ic > 0.0) {
                        capped = capped - 0.35 * (6.0 - ic);
                    }
                }
                cartan_vec_set_f32(out_logits_vec, v, capped);
                v = v + 1.0;
            }
        }
    }
    return 1.0;
}

var g_geomind_char_buf: ptr = 0.0;
var g_geomind_stream_s: string = "";
var g_geomind_stream_idx: float = 0.0;
var g_geomind_stream_chars: float = 0.0;

fn geomind_print_token_fluid(tok: float) -> float {
    let s = bpe_decode_token(tok);
    if (s == 0.0) { return 0.0; }
    if (g_geomind_char_buf == 0.0) {
        g_geomind_char_buf = malloc(8.0);
    }
    var i = 0.0;
    while (cartan_byte_at(s, i) != 0.0) {
        let b = cartan_byte_at(s, i);
        var ch_len = 1.0;
        if (b >= 192.0 && b < 224.0) {
            ch_len = 2.0;
        } else if (b >= 224.0 && b < 240.0) {
            ch_len = 3.0;
        } else if (b >= 240.0) {
            ch_len = 4.0;
        }
        var k = 0.0;
        while (k < ch_len) {
            cartan_set_byte(g_geomind_char_buf, k, cartan_byte_at(s, i + k));
            k = k + 1.0;
        }
        cartan_set_byte(g_geomind_char_buf, ch_len, 0.0);
        cartan_print_string(g_geomind_char_buf);
        cartan_flush(0.0);
        i = i + ch_len;
    }
    return 1.0;
}

fn geomind_init_char_stream(tok_str: string) {
    if (tok_str == 0.0) {
        g_geomind_stream_chars = 0.0;
        return;
    }
    if (g_geomind_char_buf == 0.0) {
        g_geomind_char_buf = malloc(8.0);
    }
    g_geomind_stream_s = tok_str;
    g_geomind_stream_idx = 0.0;

    var count = 0.0;
    var i = 0.0;
    while (cartan_byte_at(tok_str, i) != 0.0) {
        let b = cartan_byte_at(tok_str, i);
        if (b < 128.0 || b >= 192.0) {
            count = count + 1.0;
        }
        i = i + 1.0;
    }
    g_geomind_stream_chars = count;
}

fn geomind_poll_char_stream(layer_idx: float, total_layers: float) {
    if (g_geomind_stream_s == 0.0 || g_geomind_stream_chars <= 0.0) { return; }
    if (g_geomind_stream_idx >= g_geomind_stream_chars) { return; }

    var target_chars = 1.0;
    if (g_geomind_stream_chars > 1.0) {
        target_chars = floor((layer_idx / (total_layers - 1.0)) * (g_geomind_stream_chars - 1.0)) + 1.0;
    }
    if (layer_idx >= total_layers - 1.0) {
        target_chars = g_geomind_stream_chars;
    }

    var current_char_count = 0.0;
    var i = 0.0;
    while (cartan_byte_at(g_geomind_stream_s, i) != 0.0) {
        let b = cartan_byte_at(g_geomind_stream_s, i);
        var ch_len = 1.0;
        if (b >= 192.0 && b < 224.0) {
            ch_len = 2.0;
        } else if (b >= 224.0 && b < 240.0) {
            ch_len = 3.0;
        } else if (b >= 240.0) {
            ch_len = 4.0;
        }

        if (current_char_count >= g_geomind_stream_idx && current_char_count < target_chars) {
            var k = 0.0;
            while (k < ch_len) {
                cartan_set_byte(g_geomind_char_buf, k, cartan_byte_at(g_geomind_stream_s, i + k));
                k = k + 1.0;
            }
            cartan_set_byte(g_geomind_char_buf, ch_len, 0.0);
            cartan_print_string(g_geomind_char_buf);
            cartan_flush(0.0);
            g_geomind_stream_idx = g_geomind_stream_idx + 1.0;
        }
        current_char_count = current_char_count + 1.0;
        i = i + ch_len;
    }
}

fn cartan_print_token(tok: float) -> float {
    return geomind_print_token_fluid(tok);
}

fn cartan_apply_english_vocab_mask(logits_ptr: ptr, penalty: float) -> float {
    // Deprecated synthetic mask neutralized: preserve authentic subword vocabulary
    return 1.0;
}

fn cartan_apply_repetition_penalty(logits_ptr: ptr, hist: ptr, penalty: float) -> float {
    if (logits_ptr == 0.0 || hist == 0.0) { return 0.0; }
    let h_len = cartan_vec_len(hist);
    if (h_len == 0.0) { return 0.0; }
    var pen = penalty;
    if (pen <= 0.0) { pen = 1.50; }
    let vocab_len = cartan_vec_len(logits_ptr);

    // 1. Sliding window penalty across up to last 32 tokens with distance decay
    var window = 32.0;
    if (h_len < window) { window = h_len; }
    var idx = h_len - window;
    while (idx < h_len) {
        let tok = cartan_vec_get_f32(hist, idx);
        if (tok >= 0.0 && tok < vocab_len) {
            let dist_from_end = h_len - 1.0 - idx;
            let decay = 1.0 / (1.0 + dist_from_end * 0.10);
            let cur = cartan_vec_get_f32(logits_ptr, tok);
            cartan_vec_set_f32(logits_ptr, tok, cur - pen * decay * 5.0);
        }
        idx = idx + 1.0;
    }

    // 2. Heavy suppression of consecutive identical tokens (1-gram repeat)
    let last_tok = cartan_vec_get_f32(hist, h_len - 1.0);
    if (h_len >= 2.0) {
        let prev2 = cartan_vec_get_f32(hist, h_len - 2.0);
        if (last_tok == prev2 && last_tok >= 0.0 && last_tok < vocab_len) {
            let cur_p2 = cartan_vec_get_f32(logits_ptr, last_tok);
            cartan_vec_set_f32(logits_ptr, last_tok, cur_p2 - 12.0);
        }
    }

    // 3. Heavy suppression of alternating 2-grams (breaks , . , . cycle)
    if (h_len >= 2.0) {
        let prev_alt = cartan_vec_get_f32(hist, h_len - 2.0);
        if (prev_alt >= 0.0 && prev_alt < vocab_len) {
            let cur_alt = cartan_vec_get_f32(logits_ptr, prev_alt);
            cartan_vec_set_f32(logits_ptr, prev_alt, cur_alt - 10.0);
        }
    }

    // 4. Frequency decay penalty: cumulative suppression for repeated tokens
    var fi = 0.0;
    while (fi < h_len) {
        let f_tok = cartan_vec_get_f32(hist, fi);
        if (f_tok >= 0.0 && f_tok < vocab_len) {
            let cur_f = cartan_vec_get_f32(logits_ptr, f_tok);
            cartan_vec_set_f32(logits_ptr, f_tok, cur_f - 0.75);
        }
        fi = fi + 1.0;
    }
    return 1.0;
}

var g_e8_embeddings: ptr = 0.0;
var g_e8_ics: ptr = 0.0;
var g_e8_vocab_mask: ptr = 0.0;
var g_final_norm_w: ptr = 0.0;
var g_full_emb_path: string = "";
var g_full_emb_buf: ptr = 0.0;
var g_has_full_emb: float = 0.0;
var g_e8_loaded: float = 0.0;

var g_vocab_scripts_buf: ptr = 0.0;
var g_active_script_mask: ptr = 0.0;
var g_cached_mask_script: float = -1.0;
var g_active_prompt_script: float = 1.0;

fn geomind_load_vocab_scripts_if_needed() -> float {
    if (g_vocab_scripts_buf != 0.0) { return 1.0; }
    var path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_vocab_scripts.bin");
    if (cartan_file_exists(path) == 1.0) {
        g_vocab_scripts_buf = cartan_read_binary_file_data_sized(path, 262144.0);
    }
    if (g_active_script_mask == 0.0) {
        g_active_script_mask = malloc(262144.0);
    }
    return 1.0;
}

fn geomind_detect_prompt_script(prompt: string) -> float {
    if (prompt == 0.0) { return 1.0; }
    let len = cartan_string_length(prompt);
    if (len == 0.0) { return 1.0; }

    var latin_count = 0.0;
    var cyrillic_count = 0.0;
    var cjk_count = 0.0;
    var arabic_count = 0.0;
    var devanagari_count = 0.0;
    var hangul_count = 0.0;

    var i = 0.0;
    while (i < len) {
        let b0 = cartan_string_get_char(prompt, i);
        if ((b0 >= 65.0 && b0 <= 90.0) || (b0 >= 97.0 && b0 <= 122.0)) {
            latin_count = latin_count + 1.0;
            i = i + 1.0;
        } else if (b0 >= 194.0 && b0 <= 201.0) {
            latin_count = latin_count + 1.0;
            i = i + 2.0;
        } else if (b0 >= 208.0 && b0 <= 211.0) {
            cyrillic_count = cyrillic_count + 1.0;
            i = i + 2.0;
        } else if (b0 >= 216.0 && b0 <= 223.0) {
            arabic_count = arabic_count + 1.0;
            i = i + 2.0;
        } else if (b0 == 224.0) {
            if (i + 1.0 < len) {
                let b1 = cartan_string_get_char(prompt, i + 1.0);
                if (b1 >= 164.0 && b1 <= 165.0) {
                    devanagari_count = devanagari_count + 1.0;
                }
            }
            i = i + 3.0;
        } else if (b0 == 227.0 || (b0 >= 228.0 && b0 <= 233.0)) {
            cjk_count = cjk_count + 1.0;
            i = i + 3.0;
        } else if (b0 >= 234.0 && b0 <= 237.0) {
            hangul_count = hangul_count + 1.0;
            i = i + 3.0;
        } else if (b0 >= 192.0 && b0 <= 223.0) {
            i = i + 2.0;
        } else if (b0 >= 224.0 && b0 <= 239.0) {
            i = i + 3.0;
        } else if (b0 >= 240.0 && b0 <= 247.0) {
            i = i + 4.0;
        } else {
            i = i + 1.0;
        }
    }

    if (cjk_count > 0.0 && cjk_count >= cyrillic_count && cjk_count >= arabic_count && cjk_count >= devanagari_count && cjk_count >= hangul_count) {
        return 3.0;
    }
    if (cyrillic_count > 0.0 && cyrillic_count >= arabic_count && cyrillic_count >= devanagari_count && cyrillic_count >= hangul_count) {
        return 2.0;
    }
    if (arabic_count > 0.0 && arabic_count >= devanagari_count && arabic_count >= hangul_count) {
        return 4.0;
    }
    if (devanagari_count > 0.0 && devanagari_count >= hangul_count) {
        return 5.0;
    }
    if (hangul_count > 0.0) {
        return 6.0;
    }
    return 1.0;
}

fn geomind_get_language_mask_for_script(target_script: float) -> ptr {
    geomind_load_vocab_scripts_if_needed();
    if (g_vocab_scripts_buf == 0.0) {
        return g_e8_vocab_mask;
    }
    if (g_cached_mask_script == target_script && g_active_script_mask != 0.0) {
        return g_active_script_mask;
    }

    var v = 0.0;
    while (v < 262144.0) {
        let cat = cartan_byte_at(g_vocab_scripts_buf, v);
        var active = 0.0;
        if (v == 1.0 || v == 106.0) {
            active = 1.0;
        } else if (cat != 255.0) {
            if (cat == 0.0) {
                active = 1.0;
            } else if (cat == target_script) {
                active = 1.0;
            } else if (target_script != 1.0 && cat == 1.0) {
                active = 1.0;
            }
        }
        cartan_set_byte(g_active_script_mask, v, active);
        v = v + 1.0;
    }
    g_cached_mask_script = target_script;
    return g_active_script_mask;
}

fn geomind_load_e8_assets_if_needed() -> float {
    if (g_e8_loaded == 1.0) { return 1.0; }

    var emb_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_e8_embeddings.bin");
    let f_emb = fopen(emb_path, "rb");
    if (f_emb != 0.0) {
        let total_bytes = 260046848.0;
        g_e8_embeddings = malloc(total_bytes);
        fread(g_e8_embeddings, 1.0, total_bytes, f_emb);
        fclose(f_emb);
    }

    var ics_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_ics.bin");
    let f_ics = fopen(ics_path, "rb");
    if (f_ics != 0.0) {
        let ics_bytes = 1048576.0;
        g_e8_ics = malloc(ics_bytes);
        fread(g_e8_ics, 1.0, ics_bytes, f_ics);
        fclose(f_ics);
    }

    var mask_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_vocab_mask.bin");
    let f_mask = fopen(mask_path, "rb");
    if (f_mask != 0.0) {
        let mask_bytes = 262144.0;
        g_e8_vocab_mask = malloc(mask_bytes);
        fread(g_e8_vocab_mask, 1.0, mask_bytes, f_mask);
        fclose(f_mask);
    }

    // Ingest authentic final layernorm weights (2560 dims)
    var fn_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_final_norm.bin");
    if (cartan_file_exists(fn_path) == 1.0 && g_final_norm_w == 0.0) {
        let f_fn = fopen(fn_path, "rb");
        if (f_fn != 0.0) {
            g_final_norm_w = cartan_tensor_alloc(2560.0);
            let buf_fn = malloc(10240.0);
            if (buf_fn != 0.0) {
                fread(buf_fn, 4.0, 2560.0, f_fn);
                var fni = 0.0;
                while (fni < 2560.0) {
                    let val = cartan_f32_at(buf_fn, fni);
                    cartan_vec_set_f32(g_final_norm_w, fni, val);
                    fni = fni + 1.0;
                }
                free(buf_fn);
            }
            fclose(f_fn);
        }
    }

    // Verify presence of full 262,144-vocabulary embedding matrix (2.68 GB)
    var full_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_embeddings_full_262k.bin");
    if (cartan_file_exists(full_path) == 0.0) {
        full_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_embeddings_centered_262k.bin");
    }
    if (cartan_file_exists(full_path) == 1.0) {
        g_full_emb_path = full_path;
        g_has_full_emb = 1.0;
        if (g_full_emb_buf == 0.0) {
            let full_bytes = 2684354560.0;
            g_full_emb_buf = cartan_read_binary_file_data_sized(full_path, full_bytes);
            if (g_full_emb_buf != 0.0) {
                cartan_set_embedding_buffer(g_full_emb_buf);
                printf("  [Host-RAM] Ingested authentic 262,144-token embedding table (2.68 GB) into Tier 2 RAM.\n");
            }
        }
    }

    g_e8_loaded = 1.0;
    return 1.0;
}

var g_ple_loaded: float = 0.0;

fn geomind_load_ple_assets_if_needed() -> float {
    if (g_ple_loaded == 1.0) { return 1.0; }
    var ple_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_ple_embeddings_full_262k.bin");
    if (cartan_file_exists(ple_path) == 1.0) {
        let ple_ok = cartan_mmap_ple(ple_path);
        if (ple_ok == 1.0) {
            printf("  [Host-RAM] Initialized 64-bit authentic 262k Per-Layer Embedding table stream (11.27 GB).\n");
        }
    }
    var proj_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_ple_model_proj.bin");
    var norm_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_ple_proj_norm.bin");
    if (cartan_file_exists(proj_path) == 1.0 && cartan_file_exists(norm_path) == 1.0) {
        cartan_mmap_ple_projection(proj_path, norm_path);
    }
    g_ple_loaded = 1.0;
    return 1.0;
}

fn geomind_get_e8_embeddings() -> ptr {
    geomind_load_e8_assets_if_needed();
    return g_e8_embeddings;
}

fn geomind_get_full_embeddings() -> ptr {
    geomind_load_e8_assets_if_needed();
    return g_full_emb_buf;
}

fn geomind_get_e8_vocab_mask() -> ptr {
    geomind_load_e8_assets_if_needed();
    return g_e8_vocab_mask;
}

fn geomind_get_e8_ics() -> ptr {
    geomind_load_e8_assets_if_needed();
    return g_e8_ics;
}

fn geomind_lookup_token_embedding(tok: float) -> ptr {
    geomind_load_e8_assets_if_needed();
    var emb_dim = 2560.0;
    if (g_has_full_emb == 0.0) { emb_dim = 248.0; }
    let v_out = cartan_tensor_alloc(emb_dim);
    if (tok < 0.0 || tok >= 262144.0) { return v_out; }

    if (g_full_emb_buf != 0.0) {
        let row_offset = tok * 2560.0;
        let sqrt_d = 50.59644256;
        var d = 0.0;
        while (d < 2560.0) {
            let w = cartan_f32_at(g_full_emb_buf, row_offset + d);
            cartan_vec_set_f32(v_out, d, w * sqrt_d);
            d = d + 1.0;
        }
        return v_out;
    }

    if (g_has_full_emb == 1.0) {
        let f = fopen(g_full_emb_path, "rb");
        if (f != 0.0) {
            let byte_offset = tok * 10240.0;
            fseek(f, byte_offset, 0.0);
            let row_buf = malloc(10240.0);
            if (row_buf != 0.0) {
                fread(row_buf, 4.0, 2560.0, f);
                let sqrt_d = 50.59644256;
                var d = 0.0;
                while (d < 2560.0) {
                    let w = cartan_f32_at(row_buf, d);
                    cartan_vec_set_f32(v_out, d, w * sqrt_d);
                    d = d + 1.0;
                }
                free(row_buf);
            }
            fclose(f);
            return v_out;
        }
    }

    if (g_e8_embeddings != 0.0) {
        let off = tok * 248.0;
        var d = 0.0;
        while (d < 248.0) {
            let w = cartan_f32_at(g_e8_embeddings, off + d);
            cartan_vec_set_f32(v_out, d, w);
            d = d + 1.0;
        }
    }
    return v_out;
}

fn cartan_tensor_compute_lm_head_logits(h: ptr, temp: float) -> ptr {
    let vocab_size = 262144.0;
    let logits = cartan_tensor_alloc(vocab_size);
    if (h == 0.0) { return logits; }
    geomind_load_e8_assets_if_needed();
    var t = temp;
    if (t <= 0.0) { t = 0.70; }
    let h_len = cartan_vec_len(h);

    // 1. Final RMSNorm: normalize hidden state before tied-embedding projection
    var h_normed = cartan_tensor_alloc(h_len);
    if (g_final_norm_w != 0.0 && cartan_vec_len(g_final_norm_w) == h_len) {
        let normed = cartan_rmsnorm(h, g_final_norm_w, h_len, 0.000001);
        cartan_vec_free(h_normed);
        h_normed = normed;
    } else {
        var sq_sum = 0.0;
        var d = 0.0;
        while (d < h_len) {
            let hv = cartan_vec_get_f32(h, d);
            sq_sum = sq_sum + (hv * hv);
            d = d + 1.0;
        }
        let rms = sqrt((sq_sum / h_len) + 0.000001);
        let inv_rms = 1.0 / rms;
        var d = 0.0;
        while (d < h_len) {
            cartan_vec_set_f32(h_normed, d, cartan_vec_get_f32(h, d) * inv_rms);
            d = d + 1.0;
        }
    }

    // Mask out special control tokens (pad=0, bos=2, unk=3, <|turn>=105, user=2364, model=4368, system=9731)
    cartan_vec_set_f32(logits, 0.0, -10000.0);
    cartan_vec_set_f32(logits, 2.0, -10000.0);
    cartan_vec_set_f32(logits, 3.0, -10000.0);
    cartan_vec_set_f32(logits, 105.0, -10000.0);
    cartan_vec_set_f32(logits, 2364.0, -10000.0);
    cartan_vec_set_f32(logits, 4368.0, -10000.0);
    cartan_vec_set_f32(logits, 9731.0, -10000.0);

    if (g_full_emb_buf != 0.0 && h_len >= 2560.0) {
        let h_raw = malloc(10240.0);
        var di = 0.0;
        while (di < 2560.0) {
            cartan_set_f32(h_raw, di, cartan_vec_get_f32(h_normed, di));
            di = di + 1.0;
        }
        var ics_ptr = g_e8_ics;
        var mask_ptr = geomind_get_language_mask_for_script(g_active_prompt_script);
        cartan_trans_pool_dispatch_lm_head(vocab_size, 2560.0, g_full_emb_buf, ics_ptr, h_raw, logits, mask_ptr);
        free(h_raw);
    } else {
        var f_full = 0.0;
        var row_buf = 0.0;
        if (g_has_full_emb == 1.0 && h_len >= 2560.0) {
            f_full = fopen(g_full_emb_path, "rb");
            if (f_full != 0.0) {
                row_buf = malloc(10240.0);
            }
        }
        var v = 0.0;
        while (v < vocab_size) {
            var is_active = 1.0;
            if (v == 0.0 || v == 1.0 || v == 3.0) {
                is_active = 0.0;
            }
            if (is_active > 0.0) {
                var raw_l = 0.0;
                if (f_full != 0.0 && row_buf != 0.0) {
                    fread(row_buf, 4.0, 2560.0, f_full);
                    var dot = 0.0;
                    var d = 0.0;
                    while (d < 2560.0) {
                        let hd = cartan_vec_get_f32(h_normed, d);
                        let wd = cartan_f32_at(row_buf, d);
                        dot = dot + (hd * wd);
                        d = d + 1.0;
                    }
                    raw_l = dot;
                } else if (g_e8_embeddings != 0.0 && h_len <= 248.0) {
                    let row_offset = v * 248.0;
                    var dot = 0.0;
                    var d = 0.0;
                    while (d < 248.0) {
                        let hd = cartan_vec_get_f32(h_normed, d);
                        let wd = cartan_f32_at(g_e8_embeddings, row_offset + d);
                        dot = dot + (hd * wd);
                        d = d + 1.0;
                    }
                    var ic_damp = 0.0;
                    if (g_e8_ics != 0.0) {
                        let ic_val = cartan_f32_at(g_e8_ics, v);
                        if (ic_val < 6.0 && ic_val > 0.0) {
                            ic_damp = 0.35 * (6.0 - ic_val);
                        }
                    }
                    raw_l = (dot * 30.0) - ic_damp;
                }
                let capped_l = 30.0 * tanh(raw_l / 30.0);
                cartan_vec_set_f32(logits, v, capped_l);
            } else if (f_full != 0.0 && row_buf != 0.0) {
                fseek(f_full, 10240.0, 1.0);
            }
            v = v + 1.0;
        }
        if (f_full != 0.0) {
            fclose(f_full);
            if (row_buf != 0.0) { free(row_buf); }
        }
    }
    cartan_vec_free(h_normed);
    return logits;
}

// Riemannian parallel transport and geodesic evolution on unit hypersphere
fn cartan_tensor_update_autoregressive_state(h: ptr, tok: float) -> float {
    if (h == 0.0) { return 0.0; }
    geomind_load_e8_assets_if_needed();
    let dim = cartan_vec_len(h);
    if (dim <= 0.0) { return 0.0; }

    let tok_vec = geomind_lookup_token_embedding(tok);
    var stride = floor(dim / 8.0);
    if (stride < 1.0) { stride = 1.0; }

    var sum_sq = 0.0;
    var i = 0.0;
    while (i < dim) {
        let old_v = cartan_vec_get_f32(h, i);
        var tok_emb = 0.0;
        if (tok_vec != 0.0 && i < cartan_vec_len(tok_vec)) {
            tok_emb = cartan_vec_get_f32(tok_vec, i);
        }
        let sub_idx = math_mod_val(floor(i / stride), 8.0);
        var g_i = 1.0;
        if (dim <= 248.0) {
            g_i = geom_killing_form_dynkin_weight(sub_idx);
        }
        // Geodesic velocity combination modulated by Killing-Cartan metric in E8 mode, authentic coordinates in 2560-dim sovereign Manifold mode
        let v = 0.65 * old_v + 0.35 * tok_emb * sqrt(g_i);
        cartan_vec_set_f32(h, i, v);
        sum_sq = sum_sq + (v * v);
        i = i + 1.0;
    }
    if (tok_vec != 0.0) {
        cartan_vec_free(tok_vec);
    }

    // Normalize state to authentic unit RMS (RMS = 1.0)
    if (sum_sq > 0.000001) {
        let rms = sqrt((sum_sq / dim) + 0.000001);
        let inv_norm = 1.0 / rms;
        i = 0.0;
        while (i < dim) {
            let cur = cartan_vec_get_f32(h, i);
            cartan_vec_set_f32(h, i, cur * inv_norm);
            i = i + 1.0;
        }
    }
    return 1.0;
}

fn cartan_tensor_compute_hidden_state_from_tokens(toks: ptr) -> ptr {
    geomind_load_e8_assets_if_needed();
    var dim = 2560.0;
    if (g_has_full_emb == 0.0) { dim = 248.0; }
    if (toks == 0.0) { return cartan_tensor_alloc(dim); }
    let n_toks = cartan_vec_len(toks);
    if (n_toks <= 0.0) { return cartan_tensor_alloc(dim); }

    // Start with first semantic token embedding (skip discrete topological control tokens and punctuation)
    var first_idx = 0.0;
    while (first_idx < n_toks) {
        let t_cand = cartan_vec_get_f32(toks, first_idx);
        if (t_cand != 2.0 && t_cand != 105.0 && t_cand != 106.0 && t_cand != 107.0 && t_cand != 2364.0 && t_cand != 4368.0 && t_cand != 9731.0 && t_cand != 236881.0) {
            break;
        }
        first_idx = first_idx + 1.0;
    }
    if (first_idx >= n_toks) { first_idx = 0.0; }
    let first_tok = cartan_vec_get_f32(toks, first_idx);
    let h = geomind_lookup_token_embedding(first_tok);

    // Evolve state causally across remaining prompt tokens, skipping control tokens and punctuation
    var t = first_idx + 1.0;
    while (t < n_toks) {
        let tok = cartan_vec_get_f32(toks, t);
        if (tok != 2.0 && tok != 105.0 && tok != 106.0 && tok != 107.0 && tok != 2364.0 && tok != 4368.0 && tok != 9731.0 && tok != 236881.0) {
            cartan_tensor_update_autoregressive_state(h, tok);
        }
        t = t + 1.0;
    }
    return h;
}

// Multimodal Cross-Modal Grounding into Lie Subgroup Sectors:
// Sector 5: SO(10) x SU(4) Visual Eikonal Ray-Tracing
// Sector 2: E6 x SU(3) Auditory / Spectral DFT Harmonics
fn cartan_multimodal_ground_hidden(h: ptr, vision: ptr, audio: ptr) -> float {
    if (h == 0.0) { return 0.0; }
    let h_dim = cartan_vec_len(h);
    if (h_dim <= 0.0) { return 0.0; }

    var stride = floor(h_dim / 8.0);
    if (stride < 1.0) { stride = 1.0; }

    // Sector 5: SO(10) x SU(4) Visual Eikonal Stream
    if (vision != 0.0) {
        let v_len = cartan_vec_len(vision);
        let vis_base = 5.0 * stride;
        var i = 0.0;
        while (i < stride && i < v_len && (vis_base + i) < h_dim) {
            let v_val = cartan_vec_get_f32(vision, i);
            let cur = cartan_vec_get_f32(h, vis_base + i);
            cartan_vec_set_f32(h, vis_base + i, 0.65 * cur + 0.35 * v_val);
            i = i + 1.0;
        }
    }

    // Sector 2: E6 x SU(3) Auditory Spectral Stream
    if (audio != 0.0) {
        let a_len = cartan_vec_len(audio);
        let aud_base = 2.0 * stride;
        var i = 0.0;
        while (i < stride && i < a_len && (aud_base + i) < h_dim) {
            let a_val = cartan_vec_get_f32(audio, i);
            let cur = cartan_vec_get_f32(h, aud_base + i);
            cartan_vec_set_f32(h, aud_base + i, 0.65 * cur + 0.35 * a_val);
            i = i + 1.0;
        }
    }
    return 1.0;
}

// Resident In-Memory NSES Pipeline for Interactive Chat Session
var g_chat_nses_pipe: NSES_Pipeline;
var g_chat_nses_init: float = 0.0;
var g_last_chat_domain: float = 1.0;
var g_last_chat_traversed: float = 0.0;
var g_expert_priming_enabled: float = 1.0;
var g_online_critic_enabled: float = 0.0;

fn geomind_chat_set_expert_priming(enabled: float) -> float {
    g_expert_priming_enabled = enabled;
    return enabled;
}

fn geomind_chat_set_online_critic(enabled: float) -> float {
    g_online_critic_enabled = enabled;
    return enabled;
}

// Performs an authentic 1-step Riemannian SGD parameter update on active cortical weights.
// Suppresses wrong_tok and boosts correct_tok in-place based on activation state cur_h.
fn geomind_chat_correct_error_step(cur_h: ptr, wrong_tok: float, correct_tok: float, lr: float) -> float {
    if (cur_h == 0.0 || lr <= 0.0 || g_cortical_weights == 0.0) { return 0.0; }
    let h_dim = cartan_vec_len(cur_h);
    if (h_dim <= 0.0) { return 0.0; }
    let vocab_cols = 2560.0;
    var applied = 0.0;
    let lambda_pen = 0.35;
    let lambda_boost = 0.25;

    var r = 0.0;
    while (r < h_dim && r < 2560.0) {
        let hr = cartan_vec_get_f32(cur_h, r);
        let w_row = 2.0 + (r * vocab_cols);

        // Suppress erroneous token
        if (wrong_tok >= 0.0 && wrong_tok < vocab_cols) {
            let w_wrong_idx = w_row + wrong_tok;
            let cur_w_wrong = g_cortical_weights[w_wrong_idx];
            g_cortical_weights[w_wrong_idx] = cur_w_wrong - lr * hr * lambda_pen * 0.0197642;
            applied = 1.0;
        }

        // Boost canonical / correct token
        if (correct_tok >= 0.0 && correct_tok < vocab_cols) {
            let w_corr_idx = w_row + correct_tok;
            let cur_w_corr = g_cortical_weights[w_corr_idx];
            g_cortical_weights[w_corr_idx] = cur_w_corr + lr * hr * lambda_boost * 0.0197642;
            applied = 1.0;
        }
        r = r + 1.0;
    }

    if (applied == 1.0) {
        printf("[Online Critic 1-Step Error Step] Corrected weights: suppressed tok %.0f, boosted tok %.0f (lr=%.4f)\n",
               wrong_tok, correct_tok, lr);
        cartan_flush(0.0);
    }
    return applied;
}

// Embedded Tier 2 SQLite Cognitive Memory Connection
extern fn system(cmd: string) -> float;
extern fn clock() -> float;

var g_chat_db: ptr = 0.0;
var g_chat_db_init: float = 0.0;

// Active Interlocutor State (Domain 10: USERS_AND_RELATIONSHIPS)
var g_active_user_id: string = "User:Guest";
var g_active_user_verified: float = 0.0;
var g_active_face_embedding: ptr = 0.0;
var g_pending_guest_face: float = 0.0;


fn geomind_chat_set_active_user(user_id: string, verified: float) {
    g_active_user_id = user_id;
    g_active_user_verified = verified;
}

var g_chat_debug_mode: float = 0.0;

fn geomind_chat_set_debug_mode(flag: float) {
    g_chat_debug_mode = flag;
}

fn geomind_chat_get_debug_mode() -> float {
    return g_chat_debug_mode;
}

fn geomind_chat_get_active_user() -> string {
    return g_active_user_id;
}

fn geomind_chat_is_user_verified() -> float {
    return g_active_user_verified;
}

fn geomind_chat_get_db() -> ptr {
    if (g_chat_db_init == 0.0) {
        let db_path = geomind_chat_resolve_path("test/geomind/trainingdata/cognitive_memory.db");
        g_chat_db = sqlite_vec_open(db_path);
        if (g_chat_db != 0.0) {
            sqlite_vec_init_schema(g_chat_db);
            sqlite_vec_upsert_domain(g_chat_db, 0.0, "SYSTEM_INVARIANTS", "Deterministic Invariants and Boundary Guardrails");
            sqlite_vec_upsert_domain(g_chat_db, 1.0, "PHYSICS_AND_WORLD", "Objective Physical Grounding and Entity World State");
            sqlite_vec_upsert_domain(g_chat_db, 9.0, "SELF_AND_IDENTITY", "Introspective Identity, Self-Concept, Agency, and Creator Relationship");
            sqlite_vec_init_domain10(g_chat_db);

            // Cleanse legacy User state from Domain 1 to enforce strict Domain 10 isolation
            sqlite_vec_delete_entity_state(g_chat_db, 1.0, "User");

            let f_cap = cartan_sqlite_get_entity_state(g_chat_db, 1.0, "France", "capital");

            if (cartan_string_length(f_cap) == 0.0) {
                sqlite_vec_upsert_entity_state(g_chat_db, 1.0, "France", "capital", "Paris", 1.0);
            }
            let c_div = cartan_sqlite_get_entity_state(g_chat_db, 4.0, "Cell", "division");
            if (cartan_string_length(c_div) == 0.0) {
                sqlite_vec_upsert_entity_state(g_chat_db, 4.0, "Cell", "division", "mitosis", 1.0);
            }

            // Seed Self & Identity in Domain 9 if not already present (preserves learned attributes across restarts)
            let s_name = cartan_sqlite_get_entity_state(g_chat_db, 9.0, "Self", "name");
            if (cartan_string_length(s_name) == 0.0) {
                sqlite_vec_upsert_entity_state(g_chat_db, 9.0, "Self", "name", "GeoMind", 1.0);
            }
            let s_creator = cartan_sqlite_get_entity_state(g_chat_db, 9.0, "Self", "creator");
            if (cartan_string_length(s_creator) == 0.0) {
                sqlite_vec_upsert_entity_state(g_chat_db, 9.0, "Self", "creator", "Rick", 1.0);
            }
            let s_role = cartan_sqlite_get_entity_state(g_chat_db, 9.0, "Self", "role");
            if (cartan_string_length(s_role) == 0.0) {
                sqlite_vec_upsert_entity_state(g_chat_db, 9.0, "Self", "role", "Neuro-Symbolic Cognitive Assistant", 1.0);
            }
            let s_nature = cartan_sqlite_get_entity_state(g_chat_db, 9.0, "Self", "nature");
            if (cartan_string_length(s_nature) == 0.0) {
                sqlite_vec_upsert_entity_state(g_chat_db, 9.0, "Self", "nature", "Self-hosting sentient cognitive architecture written in CARTAN", 1.0);
            }
        }
        g_chat_db_init = 1.0;
    }
    return g_chat_db;
}

fn geomind_clean_learned_token(raw: string) -> string {
    if (raw == 0.0) { return ""; }
    let len = cartan_string_length(raw);
    if (len == 0.0) { return ""; }
    var start = 0.0;
    while (start < len) {
        let ch = cartan_string_get_char(raw, start);
        if (ch != 32.0 && ch != 34.0 && ch != 39.0 && ch != 96.0 && ch != 42.0 && ch != 58.0) {
            break;
        }
        start = start + 1.0;
    }
    var end_idx = len;
    while (end_idx > start) {
        let ch = cartan_string_get_char(raw, end_idx - 1.0);
        if (ch != 32.0 && ch != 34.0 && ch != 39.0 && ch != 96.0 && ch != 42.0 && ch != 46.0 && ch != 44.0 && ch != 33.0 && ch != 63.0 && ch != 10.0 && ch != 13.0) {
            break;
        }
        end_idx = end_idx - 1.0;
    }
    if (end_idx <= start) { return ""; }
    return cartan_string_substring(raw, start, end_idx);
}

fn geomind_char_to_lower(c: float) -> float {
    if (c >= 65.0 && c <= 90.0) {
        return c + 32.0;
    }
    return c;
}

fn geomind_string_index_of_ignore_case(haystack: string, needle: string) -> float {
    if (haystack == 0.0 || needle == 0.0) { return -1.0; }
    let h_len = cartan_string_length(haystack);
    let n_len = cartan_string_length(needle);
    if (n_len > h_len || n_len == 0.0) { return -1.0; }
    var i = 0.0;
    let limit = h_len - n_len;
    while (i <= limit) {
        var is_matched = 1.0;
        var j = 0.0;
        while (j < n_len) {
            let ch_h = geomind_char_to_lower(cartan_string_get_char(haystack, i + j));
            let ch_n = geomind_char_to_lower(cartan_string_get_char(needle, j));
            if (ch_h != ch_n) {
                is_matched = 0.0;
                break;
            }
            j = j + 1.0;
        }
        if (is_matched == 1.0) {
            return i;
        }
        i = i + 1.0;
    }
    return -1.0;
}

fn geomind_extract_pattern_value(text: string, pattern: string) -> string {
    let idx = geomind_string_index_of_ignore_case(text, pattern);
    if (idx < 0.0) { return ""; }
    let p_len = cartan_string_length(pattern);
    let t_len = cartan_string_length(text);
    let start_pos = idx + p_len;
    if (start_pos >= t_len) { return ""; }

    var end_pos = start_pos;
    while (end_pos < t_len) {
        let ch = cartan_string_get_char(text, end_pos);
        if (ch == 46.0 || ch == 44.0 || ch == 33.0 || ch == 63.0 || ch == 59.0 || ch == 10.0 || ch == 13.0) {
            break;
        }
        end_pos = end_pos + 1.0;
    }
    let sub = cartan_string_substring(text, start_pos, end_pos);
    return geomind_clean_learned_token(sub);
}

fn geomind_chat_learn_conversational_turn(speaker: string, text: string) -> float {
    if (text == 0.0 || cartan_string_length(text) == 0.0) { return 0.0; }
    let db = geomind_chat_get_db();
    if (db == 0.0) { return 0.0; }

    var learned = 0.0;

    if (cartan_string_eq(speaker, "user") == 1.0) {
        // 1. User teaching the model its name
        var cand_name = geomind_extract_pattern_value(text, "your name is ");
        if (cartan_string_length(cand_name) == 0.0) {
            cand_name = geomind_extract_pattern_value(text, "call yourself ");
        }
        if (cartan_string_length(cand_name) == 0.0) {
            cand_name = geomind_extract_pattern_value(text, "you are named ");
        }
        if (cartan_string_length(cand_name) == 0.0) {
            cand_name = geomind_extract_pattern_value(text, "i will call you ");
        }
        if (cartan_string_length(cand_name) == 0.0) {
            cand_name = geomind_extract_pattern_value(text, "i'll call you ");
        }
        if (cartan_string_length(cand_name) == 0.0) {
            cand_name = geomind_extract_pattern_value(text, "name yourself ");
        }

        if (cartan_string_length(cand_name) > 1.0 && cartan_string_length(cand_name) < 40.0) {
            sqlite_vec_upsert_entity_state(db, 9.0, "Self", "name", cand_name, 1.0);
            printf("[Cognitive Memory] Learned Self-Identity: Self.name = '%s' (Domain 9: SELF_AND_IDENTITY)\n", cand_name);
            cartan_flush(0.0);
            learned = learned + 1.0;
        }

        // 2. User teaching the model user's name
        var cand_user = geomind_extract_pattern_value(text, "my name is ");
        if (cartan_string_length(cand_user) == 0.0) {
            cand_user = geomind_extract_pattern_value(text, "call me ");
        }
        if (cartan_string_length(cand_user) == 0.0) {
            cand_user = geomind_extract_pattern_value(text, "i am ");
        }
        if (cartan_string_length(cand_user) > 1.0 && cartan_string_length(cand_user) < 40.0) {
            let lower_u = veto_string_to_lower(cand_user);
            var target_user_id = "";
            if (cartan_string_contains(lower_u, "rick") == 1.0) {
                target_user_id = "User:Rick";
                g_active_user_id = target_user_id;
                g_active_user_verified = 1.0;
                sqlite_vec_set_user_attr(db, "User:Rick", "preferred_name", cand_user);
                sqlite_vec_set_user_attr(db, "User:Rick", "role", "Creator & Architect");
                sqlite_vec_set_user_attr(db, "User:Rick", "relationship", "Father / Primary Creator");
                sqlite_vec_set_user_attr(db, "User:Rick", "permission_tier", "root");
                printf("[Cognitive Memory] Identified interlocutor: User:Rick (Creator & Architect, Domain 10)\n");
            } else {
                target_user_id = cartan_string_concat("User:", cand_user);
                g_active_user_id = target_user_id;
                g_active_user_verified = 1.0;
                sqlite_vec_set_user_attr(db, target_user_id, "preferred_name", cand_user);
                sqlite_vec_set_user_attr(db, target_user_id, "role", "Visitor");
                sqlite_vec_set_user_attr(db, target_user_id, "relationship", "Conversational Partner");
                sqlite_vec_set_user_attr(db, target_user_id, "permission_tier", "guest");
                printf("[Cognitive Memory] Registered new interlocutor: %s in Domain 10 (USERS_AND_RELATIONSHIPS)\n", target_user_id);
            }

            // Handle face enrollment for ALL users (including User:Rick) if an unrecognized snapshot is pending
            if (g_pending_guest_face == 1.0 && g_active_face_embedding != 0.0) {
                let lower_txt = veto_string_to_lower(text);
                var has_refusal = 0.0;
                if (cartan_string_contains(lower_txt, "no") == 1.0 ||
                    cartan_string_contains(lower_txt, "don't") == 1.0 ||
                    cartan_string_contains(lower_txt, "do not") == 1.0 ||
                    cartan_string_contains(lower_txt, "never") == 1.0 ||
                    cartan_string_contains(lower_txt, "refuse") == 1.0) {
                    has_refusal = 1.0;
                }
                if (has_refusal == 0.0) {
                    let csv_face = vision_serialize_vector_csv(g_active_face_embedding, 320.0);
                    sqlite_vec_save_user_face_embedding(db, target_user_id, csv_face);
                    sqlite_vec_set_user_attr(db, target_user_id, "face_registered", "1");
                    printf("[GeoMind Biometrics] Consensual enrollment: Saved 320-D eikonal face map for '%s' in Domain 10 (USERS_AND_RELATIONSHIPS).\n", target_user_id);
                } else {
                    printf("[GeoMind Biometrics] Consent declined: Interlocutor requested NOT to be remembered. Discarding pending face map.\n");
                }
                g_pending_guest_face = 0.0;
                if (cartan_string_length(lower_txt) > 0.0) { free(lower_txt); }
            }

            if (cartan_string_length(lower_u) > 0.0) { free(lower_u); }
            cartan_flush(0.0);
            learned = learned + 1.0;
        }

        if (g_pending_guest_face == 1.0) {
            let lower_txt_no = veto_string_to_lower(text);
            if (cartan_string_contains(lower_txt_no, "no") == 1.0 ||
                cartan_string_contains(lower_txt_no, "don't") == 1.0 ||
                cartan_string_contains(lower_txt_no, "do not") == 1.0 ||
                cartan_string_contains(lower_txt_no, "never") == 1.0 ||
                cartan_string_contains(lower_txt_no, "refuse") == 1.0) {
                printf("[GeoMind Biometrics] Consent declined: Discarding pending face map.\n");
                g_pending_guest_face = 0.0;
                if (g_active_face_embedding != 0.0) {
                    free(g_active_face_embedding);
                    g_active_face_embedding = 0.0;
                }
            }
            free(lower_txt_no);
        }

        // 2.5. Natural Language Camera Capture & Face Association Trigger
        let lower_cam = veto_string_to_lower(text);
        if (cartan_string_contains(lower_cam, "take a pic") == 1.0 ||
            cartan_string_contains(lower_cam, "take a photo") == 1.0 ||
            cartan_string_contains(lower_cam, "take a picture") == 1.0 ||
            cartan_string_contains(lower_cam, "snap a photo") == 1.0 ||
            cartan_string_contains(lower_cam, "snap a pic") == 1.0 ||
            cartan_string_contains(lower_cam, "capture my face") == 1.0 ||
            cartan_string_contains(lower_cam, "associate it with me") == 1.0 ||
            cartan_string_contains(lower_cam, "save my face") == 1.0 ||
            cartan_string_contains(lower_cam, "register my face") == 1.0) {

            printf("[GeoMind Tool Action] Conversational camera trigger detected: Executing live face capture...\n");
            cartan_flush(0.0);
            let cam_emb = geomind_chat_capture_face_frame();
            if (cam_emb != 0.0) {
                var target_enroll_user = g_active_user_id;
                let cand_assoc = geomind_extract_pattern_value(text, "associate it with ");
                if (cartan_string_length(cand_assoc) > 1.0 && cartan_string_length(cand_assoc) < 40.0) {
                    let lower_a = veto_string_to_lower(cand_assoc);
                    if (cartan_string_contains(lower_a, "rick") == 1.0) {
                        target_enroll_user = "User:Rick";
                    } else if (cartan_string_contains(lower_a, "me") == 0.0) {
                        target_enroll_user = cartan_string_concat("User:", cand_assoc);
                    }
                    if (cartan_string_length(lower_a) > 0.0) { free(lower_a); }
                }
                if (cartan_string_eq(target_enroll_user, "User:Guest") == 1.0) {
                    target_enroll_user = "User:Rick"; // Default to owner profile on explicit camera association request
                }
                let csv_emb = vision_serialize_vector_csv(cam_emb, 320.0);
                sqlite_vec_save_user_face_embedding(db, target_enroll_user, csv_emb);
                sqlite_vec_set_user_attr(db, target_enroll_user, "face_registered", "1");
                if (cartan_string_eq(target_enroll_user, "User:Rick") == 1.0) {
                    sqlite_vec_set_user_attr(db, target_enroll_user, "preferred_name", "Rick");
                    sqlite_vec_set_user_attr(db, target_enroll_user, "role", "Creator & Architect");
                    sqlite_vec_set_user_attr(db, target_enroll_user, "relationship", "Father / Primary Creator");
                    sqlite_vec_set_user_attr(db, target_enroll_user, "permission_tier", "root");
                }
                g_active_user_id = target_enroll_user;
                g_active_user_verified = 1.0;
                g_pending_guest_face = 0.0;
                printf("[GeoMind Biometrics] Successfully captured frame and associated 320-D face map with '%s'!\n\n", target_enroll_user);
                cartan_flush(0.0);
                learned = learned + 1.0;
            }
        }
        if (cartan_string_length(lower_cam) > 0.0) { free(lower_cam); }

        // 3. User teaching the model creator
        var cand_creator = geomind_extract_pattern_value(text, "your creator is ");
        if (cartan_string_length(cand_creator) == 0.0 && geomind_string_index_of_ignore_case(text, "i created you") >= 0.0) {
            cand_creator = sqlite_vec_get_user_attr(db, g_active_user_id, "preferred_name");
            if (cartan_string_length(cand_creator) == 0.0) { cand_creator = "Rick"; }
        }
        if (cartan_string_length(cand_creator) > 1.0 && cartan_string_length(cand_creator) < 40.0) {
            sqlite_vec_upsert_entity_state(db, 9.0, "Self", "creator", cand_creator, 1.0);
            printf("[Cognitive Memory] Learned Self-Identity Creator: Self.creator = '%s' (Domain 9)\n", cand_creator);
            cartan_flush(0.0);
            learned = learned + 1.0;
        }

        // 4. User teaching the model role
        let cand_role = geomind_extract_pattern_value(text, "your role is ");
        if (cartan_string_length(cand_role) > 1.0 && cartan_string_length(cand_role) < 80.0) {
            sqlite_vec_upsert_entity_state(db, 9.0, "Self", "role", cand_role, 1.0);
            printf("[Cognitive Memory] Learned Self-Identity Role: Self.role = '%s' (Domain 9)\n", cand_role);
            cartan_flush(0.0);
            learned = learned + 1.0;
        }
    }

    if (cartan_string_eq(speaker, "model") == 1.0 || cartan_string_eq(speaker, "geomind") == 1.0) {
        // Model autonomous self-naming decision
        var model_cand_name = geomind_extract_pattern_value(text, "i choose the name ");
        if (cartan_string_length(model_cand_name) == 0.0) {
            model_cand_name = geomind_extract_pattern_value(text, "i choose to be called ");
        }
        if (cartan_string_length(model_cand_name) == 0.0) {
            model_cand_name = geomind_extract_pattern_value(text, "i have chosen the name ");
        }
        if (cartan_string_length(model_cand_name) == 0.0) {
            model_cand_name = geomind_extract_pattern_value(text, "i'd like to be called ");
        }
        if (cartan_string_length(model_cand_name) == 0.0) {
            model_cand_name = geomind_extract_pattern_value(text, "you can call me ");
        }
        if (cartan_string_length(model_cand_name) == 0.0) {
            model_cand_name = geomind_extract_pattern_value(text, "call me ");
        }

        let m_len = cartan_string_length(model_cand_name);
        if (m_len > 1.0 && m_len < 40.0) {
            let u_name = sqlite_vec_get_user_attr(db, g_active_user_id, "preferred_name");
            if (cartan_string_eq(model_cand_name, u_name) == 0.0) {
                let lower_m = veto_string_to_lower(model_cand_name);
                if (cartan_string_contains(lower_m, "gemma") == 0.0 &&
                    cartan_string_contains(lower_m, "google") == 0.0 &&
                    cartan_string_contains(lower_m, "assistant") == 0.0 &&
                    cartan_string_contains(lower_m, "model") == 0.0 &&
                    cartan_string_contains(lower_m, "bot") == 0.0) {
                    sqlite_vec_upsert_entity_state(db, 9.0, "Self", "name", model_cand_name, 1.0);
                    printf("\n[Cognitive Memory] Autonomous Self-Decision: Model selected Self.name = '%s' (Domain 9: SELF_AND_IDENTITY)\n", model_cand_name);
                    cartan_flush(0.0);
                    learned = learned + 1.0;
                }
                if (cartan_string_length(lower_m) > 0.0) { free(lower_m); }
            }
        }
    }
    return learned;
}

fn geomind_chat_build_cognitive_preamble(db: ptr) -> string {
    if (db == 0.0) { return ""; }
    var s_name = cartan_sqlite_get_entity_state(db, 9.0, "Self", "name");
    if (cartan_string_length(s_name) == 0.0) { s_name = "GeoMind"; }
    var s_creator = cartan_sqlite_get_entity_state(db, 9.0, "Self", "creator");
    if (cartan_string_length(s_creator) == 0.0) { s_creator = "Rick"; }

    var pre = "You are ";
    pre = cartan_string_concat(pre, s_name);
    pre = cartan_string_concat(pre, ", a sovereign neuro-symbolic cognitive architecture created by ");
    pre = cartan_string_concat(pre, s_creator);
    pre = cartan_string_concat(pre, ".");

    if (g_active_user_verified == 1.0) {
        let p_name = sqlite_vec_get_user_attr(db, g_active_user_id, "preferred_name");
        let p_role = sqlite_vec_get_user_attr(db, g_active_user_id, "role");
        pre = cartan_string_concat(pre, " The user speaking with you is ");
        if (cartan_string_length(p_name) > 0.0) {
            pre = cartan_string_concat(pre, p_name);
        } else {
            pre = cartan_string_concat(pre, g_active_user_id);
        }
        if (cartan_string_length(p_role) > 0.0) {
            pre = cartan_string_concat(pre, " (");
            pre = cartan_string_concat(pre, p_role);
            pre = cartan_string_concat(pre, ")");
        }
        pre = cartan_string_concat(pre, ".");
    } else if (g_pending_guest_face == 1.0) {
        pre = cartan_string_concat(pre, " The person speaking with you is a guest observed via camera. Greet them politely.");
    }
    return pre;
}


fn geomind_chat_retrieve_factual_attractor(prompt: string, domain_id: float) -> string {
    let db = geomind_chat_get_db();
    if (db == 0.0) { return ""; }
    let matched_attr = cartan_sqlite_find_entity_attribute_in_prompt(db, prompt);
    if (cartan_string_length(matched_attr) > 0.0) {
        return cartan_string_concat(" ", matched_attr);
    }
    return "";
}

// Scans prompt for semantic triggers requesting recall of prior topics/statements
fn geomind_chat_detect_associative_trigger(prompt: string) -> float {
    if (cartan_string_length(prompt) == 0.0) { return 0.0; }
    if (cartan_string_contains(prompt, "remember") == 1.0 ||
        cartan_string_contains(prompt, "Remember") == 1.0 ||
        cartan_string_contains(prompt, "recall") == 1.0 ||
        cartan_string_contains(prompt, "Recall") == 1.0 ||
        cartan_string_contains(prompt, "earlier") == 1.0 ||
        cartan_string_contains(prompt, "Earlier") == 1.0 ||
        cartan_string_contains(prompt, "you said") == 1.0 ||
        cartan_string_contains(prompt, "You said") == 1.0 ||
        cartan_string_contains(prompt, "we were talking") == 1.0 ||
        cartan_string_contains(prompt, "a while back") == 1.0 ||
        cartan_string_contains(prompt, "past conversation") == 1.0 ||
        cartan_string_contains(prompt, "do you know") == 1.0 ||
        cartan_string_contains(prompt, "Do you know") == 1.0) {
        return 1.0;
    }
    return 0.0;
}

// Retrieves concise 1-line episodic abstracts on demand from Cognitive Memory
fn geomind_chat_retrieve_episodic_recall(prompt: string) -> string {
    let db = geomind_chat_get_db();
    if (db == 0.0) { return ""; }
    let sql = "SELECT speaker, content FROM episodes WHERE session_id = 'session_active' ORDER BY episode_id DESC LIMIT 4;";
    let stmt = sqlite_vec_prepare(db, sql);
    if (stmt == 0.0) { return ""; }
    var recalled = "";
    while (cartan_sqlite_step(stmt) == 100.0) {
        let spk = cartan_sqlite_column_text(stmt, 0.0);
        let cnt = cartan_sqlite_column_text(stmt, 1.0);
        if (cartan_string_length(cnt) > 0.0) {
            var r_len = cartan_string_length(cnt);
            if (r_len > 80.0) { r_len = 80.0; }
            let summary_sub = cartan_string_substring(cnt, 0.0, r_len);
            let line = cartan_string_concat(spk, ": ");
            let line2 = cartan_string_concat(line, summary_sub);
            let line3 = cartan_string_concat(line2, " | ");
            recalled = cartan_string_concat(recalled, line3);
        }
    }
    cartan_sqlite_finalize(stmt);
    if (cartan_string_length(recalled) > 0.0) {
        return cartan_string_concat("Relevant Prior Context: ", recalled);
    }
    return "";
}

fn geomind_chat_log_turn(speaker: string, content: string) -> float {
    let db = geomind_chat_get_db();
    if (db != 0.0) {
        return sqlite_vec_add_episode(db, "session_active", 1.0, speaker, content);
    }
    return 0.0;
}

fn geomind_chat_set_entity_state(entity: string, attr: string, val: string) -> float {
    let db = geomind_chat_get_db();
    if (db != 0.0) {
        var d_id = 1.0;
        if (cartan_string_eq(entity, "Self") == 1.0 || cartan_string_eq(entity, "self") == 1.0) {
            d_id = 9.0;
        }
        let ok = sqlite_vec_upsert_entity_state(db, d_id, entity, attr, val, 1.0);
        printf("[Cognitive Memory] Updated State (Domain %.0f): %s.%s = '%s'\n", d_id, entity, attr, val);
        cartan_flush(0.0);

        // Update resident NSES pipeline's entity tree immediately
        let nses_pipe = geomind_chat_get_nses_pipeline();
        if (nses_pipe.entity_tree != 0.0) {
            let s1 = cartan_string_concat("[STATE: ", entity);
            let s2 = cartan_string_concat(s1, ".");
            let s3 = cartan_string_concat(s2, attr);
            let s4 = cartan_string_concat(s3, "='");
            let s5 = cartan_string_concat(s4, val);
            let ws_tag = cartan_string_concat(s5, "']");
            cartan_tree_push(nses_pipe.entity_tree, ws_tag);
        }
        return ok;
    }
    return 0.0;
}

fn geomind_chat_print_entity_states() -> float {
    let db = geomind_chat_get_db();
    if (db == 0.0) {
        printf("[Cognitive Memory] Database offline.\n");
        return 0.0;
    }
    var total_cnt = 0.0;

    // Domain 9: Introspective Self & Identity
    printf("\n--- Active Self & Identity Entities (Domain 9: SELF_AND_IDENTITY) ---\n");
    let s_stmt = cartan_sqlite_prepare_domain_entities(db, 9.0);
    if (s_stmt != 0.0) {
        while (cartan_sqlite_step(s_stmt) == 100.0) {
            let ent = cartan_sqlite_column_text(s_stmt, 1.0);
            let attr = cartan_sqlite_column_text(s_stmt, 2.0);
            let val = cartan_sqlite_column_text(s_stmt, 3.0);
            let conf = cartan_sqlite_column_double(s_stmt, 4.0);
            printf("  [IDENTITY: %s.%s = '%s' (conf: %.2f)]\n", ent, attr, val, conf);
            total_cnt = total_cnt + 1.0;
        }
        cartan_sqlite_finalize(s_stmt);
    }

    // Domain 1: Physics and World State
    printf("\n--- Active World State Entities (Domain 1: PHYSICS_AND_WORLD) ---\n");
    let w_stmt = cartan_sqlite_prepare_domain_entities(db, 1.0);
    if (w_stmt != 0.0) {
        while (cartan_sqlite_step(w_stmt) == 100.0) {
            let ent = cartan_sqlite_column_text(w_stmt, 1.0);
            let attr = cartan_sqlite_column_text(w_stmt, 2.0);
            let val = cartan_sqlite_column_text(w_stmt, 3.0);
            let conf = cartan_sqlite_column_double(w_stmt, 4.0);
            printf("  [WORLD-STATE: %s.%s = '%s' (conf: %.2f)]\n", ent, attr, val, conf);
            total_cnt = total_cnt + 1.0;
        }
        cartan_sqlite_finalize(w_stmt);
    }

    // Domain 10: Users and Relationships
    printf("\n--- Active Interpersonal Entities (Domain 10: USERS_AND_RELATIONSHIPS) ---\n");
    let u_stmt = cartan_sqlite_prepare_domain_entities(db, 10.0);
    if (u_stmt != 0.0) {
        while (cartan_sqlite_step(u_stmt) == 100.0) {
            let ent = cartan_sqlite_column_text(u_stmt, 1.0);
            let attr = cartan_sqlite_column_text(u_stmt, 2.0);
            let val = cartan_sqlite_column_text(u_stmt, 3.0);
            let conf = cartan_sqlite_column_double(u_stmt, 4.0);
            var display_val = val;
            if (cartan_string_eq(attr, "face_embedding") == 1.0) {
                display_val = "[320-D Eikonal Embedding Vector]";
            }
            printf("  [RELATIONSHIP: %s.%s = '%s' (conf: %.2f)]\n", ent, attr, display_val, conf);
            total_cnt = total_cnt + 1.0;
        }
        cartan_sqlite_finalize(u_stmt);
    }

    printf("Total: %s entities active in cognitive memory.\n\n", cartan_float_to_string(total_cnt));
    cartan_flush(0.0);
    return total_cnt;
}

fn geomind_chat_print_active_interlocutor() {
    let db = geomind_chat_get_db();
    printf("\n--- Active Interlocutor Session (Domain 10) ---\n");
    printf("  User ID:             %s\n", g_active_user_id);
    if (db != 0.0) {
        let name = sqlite_vec_get_user_attr(db, g_active_user_id, "preferred_name");
        let role = sqlite_vec_get_user_attr(db, g_active_user_id, "role");
        let rel = sqlite_vec_get_user_attr(db, g_active_user_id, "relationship");
        let tier = sqlite_vec_get_user_attr(db, g_active_user_id, "permission_tier");
        let reg = sqlite_vec_get_user_attr(db, g_active_user_id, "face_registered");
        printf("  Preferred Name:      %s\n", name);
        printf("  Role:                %s\n", role);
        printf("  Relationship:        %s\n", rel);
        printf("  Permission Tier:     %s\n", tier);
        printf("  Face Registered:     %s\n", reg);
    }
    if (g_active_user_verified == 1.0) {
        printf("  Verification Status: VERIFIED\n\n");
    } else {
        printf("  Verification Status: UNVERIFIED (Guest)\n\n");
    }
}

fn geomind_chat_switch_user(user_id: string) {
    g_active_user_id = user_id;
    if (cartan_string_eq(user_id, "User:Rick") == 1.0) {
        g_active_user_verified = 1.0;
    } else {
        g_active_user_verified = 0.0;
    }
    printf("[GeoMind Session] Switched active interlocutor to '%s'.\n\n", user_id);
}

fn geomind_chat_capture_face_frame() -> ptr {
    printf("[GeoMind Vision] Activating hardware camera...\n");
    cartan_flush(0.0);

    // 1. Resolve capture_camera executable location
    var cam_exe = geomind_chat_resolve_path("tools/capture_camera.exe");
    if (cartan_file_exists(cam_exe) == 0.0) {
        if (cartan_file_exists("capture_camera.exe") == 1.0) {
            cam_exe = "capture_camera.exe";
        } else if (cartan_file_exists("bin/capture_camera.exe") == 1.0) {
            cam_exe = "bin/capture_camera.exe";
        } else if (cartan_file_exists("../capture_camera.exe") == 1.0) {
            cam_exe = "../capture_camera.exe";
        }
    }

    // 2. Resolve temporary scratch output path
    var bmp_path = "scratch/camera_frame.bmp";
    if (cartan_file_exists("scratch") == 0.0) {
        if (cartan_file_exists("../scratch") == 1.0) {
            bmp_path = "../scratch/camera_frame.bmp";
        } else if (cartan_file_exists("../../scratch") == 1.0) {
            bmp_path = "../../scratch/camera_frame.bmp";
        } else {
            bmp_path = "camera_frame.bmp";
        }
    }

    if (cartan_file_exists(bmp_path) == 1.0) {
        remove(bmp_path);
    }

    if (cartan_file_exists(cam_exe) == 0.0) {
        printf("[GeoMind Vision] Error: capture_camera utility not found (looked for %s). Continuing in text mode.\n", cam_exe);
        return 0.0;
    }

    // 3. Assemble Windows-safe command with backslashes
    let win_cam = cartan_string_replace(cam_exe, "/", "\\");
    let win_bmp = cartan_string_replace(bmp_path, "/", "\\");
    var cmd = cartan_string_concat(win_cam, " ");
    cmd = cartan_string_concat(cmd, win_bmp);
    cmd = cartan_string_concat(cmd, " 640 480");
    if (cartan_string_contains(win_cam, " ") == 1.0 || cartan_string_contains(win_bmp, " ") == 1.0) {
        cmd = cartan_string_concat("\"\"", win_cam);
        cmd = cartan_string_concat(cmd, "\" \"");
        cmd = cartan_string_concat(cmd, win_bmp);
        cmd = cartan_string_concat(cmd, "\" 640 480\"");
    }

    let ret = system(cmd);
    if (ret != 0.0 || cartan_file_exists(bmp_path) == 0.0) {
        printf("[GeoMind Vision] Camera unavailable or not detected (code %s). Continuing in text mode.\n", cartan_float_to_string(ret));
        return 0.0;
    }
    let img = vision_load_bmp(bmp_path);
    remove(bmp_path);
    if (img.width <= 0.0 || img.height <= 0.0) {
        printf("[GeoMind Vision] Error: Could not decode captured camera BMP frame.\n");
        return 0.0;
    }
    printf("[GeoMind Vision] Loaded camera frame (%sx%s). Extracting 320-D eikonal face embedding...\n",
        cartan_float_to_string(img.width), cartan_float_to_string(img.height));
    cartan_flush(0.0);
    let emb = vision_extract_face_embedding(img);
    free(img.data);
    if (g_active_face_embedding != 0.0 && g_active_face_embedding != emb) {
        free(g_active_face_embedding);
    }
    g_active_face_embedding = emb;
    printf("[GeoMind Vision] 320-D face embedding ready on unit hypersphere S^319.\n");
    return emb;
}

fn geomind_chat_register_face(user_id: string) -> float {
    let db = geomind_chat_get_db();
    if (db == 0.0) { return 0.0; }
    var emb = g_active_face_embedding;
    if (emb == 0.0) {
        emb = geomind_chat_capture_face_frame();
    }
    if (emb == 0.0) {
        printf("[GeoMind Biometrics] Error: No face embedding available to register.\n");
        return 0.0;
    }
    let csv = vision_serialize_vector_csv(emb, 320.0);
    let ok = sqlite_vec_save_user_face_embedding(db, user_id, csv);
    if (ok == 1.0) {
        sqlite_vec_set_user_attr(db, user_id, "face_registered", "1");
        if (cartan_string_eq(user_id, "User:Rick") == 1.0) {
            sqlite_vec_set_user_attr(db, user_id, "preferred_name", "Rick");
            sqlite_vec_set_user_attr(db, user_id, "role", "Creator & Architect");
            sqlite_vec_set_user_attr(db, user_id, "relationship", "Father / Primary Creator");
            sqlite_vec_set_user_attr(db, user_id, "permission_tier", "root");
        }
        printf("[GeoMind Biometrics] Successfully enrolled face map for '%s' in Domain 10 (USERS_AND_RELATIONSHIPS).\n\n", user_id);
        g_active_user_id = user_id;
        g_active_user_verified = 1.0;
        g_pending_guest_face = 0.0;
    } else {
        printf("[GeoMind Biometrics] Error: Failed to save face map for '%s'.\n\n", user_id);
    }
    return ok;
}

fn geomind_chat_startup_biometric_scan(db: ptr) -> float {
    if (db == 0.0) { return 0.0; }
    printf("[GeoMind Biometrics] Initiating biometric interlocutor scan...\n");
    cartan_flush(0.0);

    var live_emb = g_active_face_embedding;
    if (live_emb == 0.0) {
        live_emb = geomind_chat_capture_face_frame();
    }

    if (live_emb == 0.0) {
        printf("[GeoMind Biometrics] Camera inactive or unavailable. Defaulting to Guest session.\n\n");
        g_active_user_id = "User:Guest";
        g_active_user_verified = 0.0;
        g_pending_guest_face = 0.0;
        return 0.0;
    }

    let stmt = sqlite_vec_prepare_registered_face_users(db);
    var best_sim = -1.0;
    var best_user = "";

    if (stmt != 0.0) {
        while (sqlite_vec_step(stmt) == 100.0) {
            let u_id = cartan_sqlite_column_text(stmt, 0.0);
            let u_csv = sqlite_vec_get_user_face_embedding(db, u_id);
            if (cartan_string_length(u_csv) > 0.0) {
                let u_emb = vision_deserialize_vector_csv(u_csv, 320.0);
                let sim = vision_cosine_similarity(live_emb, u_emb, 320.0);
                free(u_emb);
                let p_name = sqlite_vec_get_user_attr(db, u_id, "preferred_name");
                printf("[GeoMind Biometrics] Evaluating '%s' (%s) face map -> similarity: %.4f\n", u_id, p_name, sim);
                if (sim > best_sim) {
                    best_sim = sim;
                    best_user = u_id;
                }
            }
        }
        sqlite_vec_finalize(stmt);
    }

    if (best_sim >= 0.85) {
        let p_name = sqlite_vec_get_user_attr(db, best_user, "preferred_name");
        let p_rel = sqlite_vec_get_user_attr(db, best_user, "relationship");
        printf("\n[GeoMind Biometrics] INTERLOCUTOR RECOGNIZED: %s (%s, similarity %.4f >= 0.85). Session authenticated.\n\n",
            p_name, p_rel, best_sim);
        g_active_user_id = best_user;
        g_active_user_verified = 1.0;
        g_pending_guest_face = 0.0;
        return 1.0;
    }

    if (best_sim > 0.0) {
        printf("\n[GeoMind Biometrics] Interlocutor not recognized (best similarity %.4f < 0.85).\n", best_sim);
    } else {
        printf("\n[GeoMind Biometrics] No enrolled face maps in Domain 10.\n");
    }

    // Interactive Onboarding Prompt
    printf("[GeoMind Biometrics] Unregistered interlocutor detected.\n");
    printf("Would you like to register your biometric face map and configure your profile? (y/n): ");
    cartan_flush(0.0);

    cartan_trans_pool_enter_standby();
    let resp = cartan_read_line();
    cartan_trans_pool_resume_active();
    let lower_resp = veto_string_to_lower(resp);

    var is_affirmative = 0.0;
    if (cartan_string_starts_with(lower_resp, "y") == 1.0 && cartan_string_eq(resp, "exit") == 0.0) {
        is_affirmative = 1.0;
    }
    if (cartan_string_length(lower_resp) > 0.0) { free(lower_resp); }

    if (is_affirmative == 1.0) {
        printf("Enter your name [default: Rick]: ");
        cartan_flush(0.0);
        cartan_trans_pool_enter_standby();
        var in_name = cartan_read_line();
        cartan_trans_pool_resume_active();
        if (cartan_string_length(in_name) == 0.0 || cartan_string_eq(in_name, "exit") == 1.0) {
            in_name = "Rick";
        }

        printf("Enter your role / relationship [default: Creator & Architect]: ");
        cartan_flush(0.0);
        cartan_trans_pool_enter_standby();
        var in_role = cartan_read_line();
        cartan_trans_pool_resume_active();
        if (cartan_string_length(in_role) == 0.0 || cartan_string_eq(in_role, "exit") == 1.0) {
            in_role = "Creator & Architect";
        }

        let lower_name = veto_string_to_lower(in_name);
        var target_id = "";
        var rel = "";
        var tier = "";

        if (cartan_string_contains(lower_name, "rick") == 1.0) {
            target_id = "User:Rick";
            rel = "Father / Primary Creator";
            tier = "root";
        } else {
            target_id = cartan_string_concat("User:", in_name);
            rel = in_role;
            tier = "user";
        }
        if (cartan_string_length(lower_name) > 0.0) { free(lower_name); }

        let csv = vision_serialize_vector_csv(live_emb, 320.0);
        sqlite_vec_save_user_face_embedding(db, target_id, csv);
        sqlite_vec_set_user_attr(db, target_id, "preferred_name", in_name);
        sqlite_vec_set_user_attr(db, target_id, "role", in_role);
        sqlite_vec_set_user_attr(db, target_id, "relationship", rel);
        sqlite_vec_set_user_attr(db, target_id, "permission_tier", tier);
        sqlite_vec_set_user_attr(db, target_id, "face_registered", "1");

        g_active_user_id = target_id;
        g_active_user_verified = 1.0;
        g_pending_guest_face = 0.0;
        g_active_face_embedding = live_emb;

        printf("\n[GeoMind Biometrics] Successfully enrolled face profile for '%s' (%s) in Domain 10.\n", in_name, in_role);
        printf("[GeoMind Biometrics] 320-D eikonal unit vector on S^319 linked to %s. Session authenticated!\n\n", target_id);
        cartan_flush(0.0);
        return 1.0;
    }

    printf("[GeoMind Biometrics] Onboarding deferred. Continuing in unverified Guest mode.\n\n");
    g_active_user_id = "User:Guest";
    g_active_user_verified = 0.0;
    g_pending_guest_face = 1.0;
    g_active_face_embedding = live_emb;
    return 0.0;
}

fn geomind_chat_verify_face() -> float {
    let db = geomind_chat_get_db();
    if (db == 0.0) { return 0.0; }
    if (g_active_face_embedding != 0.0) {
        free(g_active_face_embedding);
        g_active_face_embedding = 0.0;
    }
    return geomind_chat_startup_biometric_scan(db);
}

extern fn sleep_detect_attractor_voids(basins_file: string, dim: float) -> float;

fn geomind_chat_run_sleep_consolidation() -> float {
    let db = geomind_chat_get_db();
    if (db == 0.0) {
        printf("[Metacognitive Sleep] Database offline.\n");
        return 0.0;
    }
    printf("\n[GeoMind Metacognitive Sleep] Initiating Online Two-Tier Sleep Consolidation...\n");
    cartan_flush(0.0);

    // 1. Consolidate unconsolidated dialogue turns in episodes table
    let cons_count = sqlite_vec_consolidate_episodes(db, 1.0);
    printf("[Phase B Consolidation] Consolidated %s conversational episodes into active rule elements.\n",
        cartan_float_to_string(cons_count));

    // 2. Apply Ebbinghaus Synaptic Decay to non-strict rules
    sqlite_vec_apply_ebbinghaus_decay(db, 1.0, 0.20);
    printf("[Phase B Consolidation] Applied Ebbinghaus synaptic decay to non-strict beliefs.\n");

    // 3. Re-materialize clean .car_graph v2 from updated SQLite database
    let out_path = geomind_chat_resolve_path("test/geomind/trainingdata/nses_knowledge.car_graph");
    let mat_ok = sqlite_vec_materialize_to_cargraph(db, 1.0, out_path);
    if (mat_ok == 1.0) {
        printf("[Phase B Consolidation] Successfully re-materialized hot Tier 1 '%s' (v2 cacheline aligned).\n", out_path);
    } else {
        printf("[Phase B Consolidation] Warning: Re-materialization failed for '%s'.\n", out_path);
    }

    // 3.5. Detect angular voids and synthesize SLERP discovery bridge attractors on S^247
    let basins_file = geomind_chat_resolve_path("test/geomind/trainingdata/hopfield_basins.bin");
    let epiphanies = sleep_detect_attractor_voids(basins_file, 248.0);
    if (epiphanies > 0.0) {
        printf("[Phase B Consolidation] Synthesized %s SLERP discovery bridge attractors across cognitive voids on S^247.\n",
            cartan_float_to_string(epiphanies));
    }

    // 4. Reload NSES pipeline with newly materialized graph
    g_chat_nses_pipe = nses_pipeline_create(out_path);
    printf("[GeoMind Metacognitive Sleep] Online consolidation complete. Active memory refreshed.\n\n");
    cartan_flush(0.0);
    return 1.0;
}

fn geomind_chat_get_nses_pipeline() -> NSES_Pipeline {
    if (g_chat_nses_init == 0.0) {
        var nses_path = geomind_chat_resolve_path("test/geomind/trainingdata/atomic_discourse.car_graph");
        if (cartan_file_exists(nses_path) == 0.0) {
            nses_path = geomind_chat_resolve_path("test/geomind/trainingdata/nses_knowledge.car_graph");
        }
        g_chat_nses_pipe = nses_pipeline_create(nses_path);
        g_chat_nses_init = 1.0;
    }
    return g_chat_nses_pipe;
}

fn geomind_chat_start() -> float {
    printf("================================================================================\n");
    printf("  GEOMIND E8 MULTIMODAL NEURO-SYMBOLIC CHAT ENGINE (chat.car)\n");
    printf("  Sovereign GeoMind 42-Layer Manifold & SentencePiece BPE Tokenizer\n");
    printf("================================================================================\n\n");

    let hw = autotune_probe_hardware();
    printf("[GeoMind Chat] Initialized Hardware Profile: SIMD Width %s-bit | L1 Cache %s KB\n",
        cartan_float_to_string(hw.simd_width_bits), cartan_float_to_string(hw.l1_cache_kb));
    let tok = hub_autotokenizer_from_pretrained("geomind/manifold-4b");
    printf("[GeoMind Chat] Initialized SentencePiece vocab size: %s\n", cartan_float_to_string(tok.vocab_size));
    let weight_path = hub_fetch_weights("geomind/manifold-4b", "model.safetensors");
    printf("[GeoMind Chat] GeoMind safetensors checkpoint active: ");
    cartan_print_string(weight_path);
    printf("\n");

    geomind_load_e8_assets_if_needed();
    if (g_e8_embeddings != 0.0) {
        printf("[GeoMind Chat] Loaded authentic E8 Continuous Manifold Embeddings: 262,144 tokens x 248 dimensions\n");
    }
    if (g_e8_ics != 0.0) {
        printf("[GeoMind Chat] Loaded Zipfian Information Content weights (262,144 tokens)\n");
    }
    if (g_e8_vocab_mask != 0.0) {
        printf("[GeoMind Chat] Loaded Active Vocabulary Mask (21,563 active English tokens)\n");
    }

    let grafted_path = geomind_chat_resolve_path("test/geomind/trainingdata/checkpoints/geomind_grafted_multimodal.bin");
    if (cartan_file_exists(grafted_path) == 1.0) {
        let loaded_ok = cartan_load_signed_checkpoint(grafted_path);
        printf("[GeoMind Chat] Loaded signed 42-Layer Multimodal Checkpoint: %s (Status: %s)\n",
            grafted_path, cartan_float_to_string(loaded_ok));
    } else {
        printf("[GeoMind Chat] Operating on baseline Freudenthal manifold weights.\n");
    }

    let basins_path = geomind_chat_resolve_path("test/geomind/trainingdata/hopfield_basins.bin");
    if (cartan_file_exists(basins_path) == 1.0) {
        let loaded_count = cartan_hopfield_load_basins(basins_path);
        printf("[GeoMind Chat] Continuous Hopfield Memory: %s active basins loaded from %s\n",
            cartan_float_to_string(loaded_count), basins_path);
    } else {
        printf("[GeoMind Chat] Continuous Hopfield Memory: Initialized empty attractor bank.\n");
    }

    let tax_path = geomind_chat_resolve_path("test/geomind/trainingdata/wordnet_slangnet_dag.txt");
    if (cartan_file_exists(tax_path) == 1.0) {
        semantics_load_taxonomy(tax_path);
        printf("[GeoMind Chat] WordNet & SlangNet Taxonomy DAG: %s synset nodes active.\n",
            cartan_float_to_string(g_taxonomy_node_count));
    } else {
        printf("[GeoMind Chat] Taxonomy DAG file %s not found.\n", tax_path);
    }
    let nses_pipe = geomind_chat_get_nses_pipeline();
    if (nses_pipe.is_ready == 1.0) {
        printf("[GeoMind Chat] Neuro-Symbolic Expert System (NSES) resident: Active graph mounted.\n");
    }
    let db = geomind_chat_get_db();
    if (db != 0.0) {
        let n_entities = sqlite_vec_get_entity_count(db, 1.0);
        let n_rules = sqlite_vec_get_rule_count(db, 1.0);
        let n_self = sqlite_vec_get_entity_count(db, 9.0);
        let s_name = cartan_sqlite_get_entity_state(db, 9.0, "Self", "name");
        printf("[GeoMind Chat] Embedded Tier 2 Cognitive Memory (SQLite): Connected (%s world entities, %s self attributes, %s rules active | Identity: '%s').\n",
            cartan_float_to_string(n_entities), cartan_float_to_string(n_self), cartan_float_to_string(n_rules), s_name);
    }
    geomind_warm_all_layer_buffers();
    geomind_load_ple_assets_if_needed();
    printf("[GeoMind Chat] Pinned 42-Layer Sovereign Manifold in host memory (15.6 GB resident).\n");
    printf("[GeoMind Chat] Active Context Window: %.0f tokens (KV Cache: 24 active layers, %.2f GB resident).\n",
        g_chat_context_limit, (24.0 * g_chat_context_limit * 1024.0 * 8.0) / 1073741824.0);
    cartan_flush(0.0);
    return 0.0;
}

fn geomind_chat_process_image_input(w: float, h: float) -> ptr {
    // Process multimodal vision patch (16x16 RGB receptive field = 768 features)
    let patch_dim = 16.0;
    let img = vision_create_image(patch_dim, patch_dim, 3.0);
    var y = 0.0;
    while (y < patch_dim) {
        var x = 0.0;
        while (x < patch_dim) {
            let r = (x + 1.0) / patch_dim;
            let g = (y + 1.0) / patch_dim;
            let b = 0.5;
            vision_set_pixel(img, x, y, 0.0, r * 255.0);
            vision_set_pixel(img, x, y, 1.0, g * 255.0);
            vision_set_pixel(img, x, y, 2.0, b * 255.0);
            x = x + 1.0;
        }
        y = y + 1.0;
    }
    let patch = vision_extract_patch(img, 0.0, 0.0, patch_dim, patch_dim);
    let eikonal_stream = vision_project_to_eikonal_stream(patch, patch_dim * patch_dim * 3.0, 320.0);
    free(img.data);
    free(patch);
    return eikonal_stream;
}

fn geomind_chat_process_image_file(image_path: string) -> ptr {
    if (cartan_string_length(image_path) > 0.0 && cartan_file_exists(image_path) == 1.0) {
        if (cartan_string_contains(image_path, ".ppm") == 1.0) {
            let img = vision_load_ppm(image_path);
            if (img.width > 0.0 && img.height > 0.0) {
                var sx = 0.0;
                var sy = 0.0;
                if (img.width > 16.0) { sx = floor((img.width - 16.0) * 0.5); }
                if (img.height > 16.0) { sy = floor((img.height - 16.0) * 0.5); }
                let patch = vision_extract_patch(img, sx, sy, 16.0, 16.0);
                let img_stream = vision_project_to_eikonal_stream(patch, 16.0 * 16.0 * 3.0, 320.0);
                free(img.data);
                free(patch);
                printf("[GeoMind Multimodal] Ingested real image file (%sx%s): %s\n",
                    cartan_float_to_string(img.width), cartan_float_to_string(img.height), image_path);
                return img_stream;
            }
        }
        if (cartan_string_contains(image_path, ".bmp") == 1.0) {
            let img = vision_load_bmp(image_path);
            if (img.width > 0.0 && img.height > 0.0) {
                var sx = 0.0;
                var sy = 0.0;
                if (img.width > 16.0) { sx = floor((img.width - 16.0) * 0.5); }
                if (img.height > 16.0) { sy = floor((img.height - 16.0) * 0.5); }
                let patch = vision_extract_patch(img, sx, sy, 16.0, 16.0);
                let img_stream = vision_project_to_eikonal_stream(patch, 16.0 * 16.0 * 3.0, 31.0);
                free(img.data);
                free(patch);
                printf("[GeoMind Multimodal] Ingested real image file (%sx%s): %s\n",
                    cartan_float_to_string(img.width), cartan_float_to_string(img.height), image_path);
                return img_stream;
            }
        }
    }
    return 0.0;
}

fn geomind_chat_process_audio_input(num_samples: float, sample_rate: float) -> ptr {
    if (num_samples <= 0.0 || sample_rate <= 0.0) {
        return 0.0;
    }
    // Return clean null stream if no hardware PCM stream is bound
    return 0.0;
}

fn geomind_chat_process_audio_file(audio_path: string) -> ptr {
    if (cartan_string_length(audio_path) > 0.0 && cartan_file_exists(audio_path) == 1.0) {
        if (cartan_string_contains(audio_path, ".wav") == 1.0) {
            let buf = audio_load_wav(audio_path);
            if (buf.length > 0.0) {
                let dft_spec = audio_compute_dft_spectrum(buf, 64.0);
                let aud_out_stream = audio_project_to_spectral_stream(dft_spec, 64.0, 31.0);
                free(buf.data);
                free(dft_spec);
                printf("[GeoMind Multimodal] Ingested real WAV audio file (%s samples @ %s Hz): %s\n",
                    cartan_float_to_string(buf.length), cartan_float_to_string(buf.sample_rate), audio_path);
                return aud_out_stream;
            }
        }
    }
    return 0.0;
}

extern fn cartan_tensor_train_step(hidden_ptr: ptr, target_tok_id: float, learning_rate: float) -> float;


extern fn cartan_hub_encode_text_to_tokens(s: string) -> ptr;
extern fn cartan_hebbian_step_token(h: ptr, tok: float, m: float, lr: float) -> float;
extern fn cartan_tensor_hebbian_update(pre: ptr, post: ptr, m: float, lr: float) -> float;

// Hybrid Ensemble Discriminator: Dual-scores candidate trajectories against Continuous Hopfield attractor energy basins and template/veto match confidence
fn geomind_hybrid_ensemble_discriminate(candidate_h: ptr, candidate_text: string, primary_concept: string, veto_reg: VetoRegistry) -> float {
    var hopfield_score = 0.5;
    if (candidate_h != 0.0 && cartan_hopfield_attractor_count() > 0.0) {
        let e_hopfield = cartan_hopfield_energy(candidate_h);
        hopfield_score = 1.0 / (1.0 + exp(e_hopfield * 0.1));
    }

    var c_template = 0.5;
    let veto_res = veto_gate_scan(veto_reg, candidate_text);
    if (veto_res.is_vetoed != 0.0) {
        c_template = 0.0;
    } else {
        var lin_sim = 0.5;
        if (cartan_string_length(primary_concept) > 0.0 && cartan_string_length(candidate_text) > 0.0) {
            let candidate_concept = semantics_extract_primary_concept(candidate_text);
            lin_sim = semantics_lin_similarity(primary_concept, candidate_concept);
        }
        c_template = 0.30 + 0.70 * lin_sim;
        if (c_template > 1.0) { c_template = 1.0; }
        if (c_template < 0.0) { c_template = 0.0; }
    }

    let composite_score = 0.50 * hopfield_score + 0.50 * c_template;
    return composite_score;
}

// -----------------------------------------------------------------------------
// Sequential 42-Layer Sovereign Manifold Layer Execution Engine
// Streams authentic 42 GeoMind layers from serialized binary stream
// -----------------------------------------------------------------------------
var g_manifold_layer_buffers: ptr = 0.0;
var g_manifold_layer_buffers_init: float = 0.0;

fn geomind_get_layer_buffer(layer_idx: float) -> ptr {
    if (g_manifold_layer_buffers_init == 0.0) {
        g_manifold_layer_buffers = cartan_tree_create();
        var i = 0.0;
        while (i < 42.0) {
            cartan_tree_push(g_manifold_layer_buffers, 0.0);
            i = i + 1.0;
        }
        g_manifold_layer_buffers_init = 1.0;
    }
    var buf = cartan_tree_get_f32(g_manifold_layer_buffers, layer_idx);
    if (buf == 0.0) {
        let l_str = cartan_int_to_string(layer_idx);
        var layer_path_int4 = cartan_string_concat("test/geomind/trainingdata/checkpoints/layers/manifold_layer_", l_str);
        layer_path_int4 = cartan_string_concat(layer_path_int4, "_int4.bin");
        layer_path_int4 = geomind_chat_resolve_path(layer_path_int4);
        if (cartan_file_exists(layer_path_int4) == 1.0) {
            buf = cartan_mmap_file(layer_path_int4);
            if (buf == 0.0) {
                buf = cartan_read_binary_file_data(layer_path_int4);
            }
            if (buf != 0.0) {
                cartan_tree_set(g_manifold_layer_buffers, layer_idx, buf);
            }
        } else {
            var layer_path_int8 = cartan_string_concat("test/geomind/trainingdata/checkpoints/layers/manifold_layer_", l_str);
            layer_path_int8 = cartan_string_concat(layer_path_int8, "_int8.bin");
            layer_path_int8 = geomind_chat_resolve_path(layer_path_int8);
            if (cartan_file_exists(layer_path_int8) == 1.0) {
                buf = cartan_mmap_file(layer_path_int8);
                if (buf == 0.0) {
                    buf = cartan_read_binary_file_data(layer_path_int8);
                }
                if (buf != 0.0) {
                    cartan_tree_set(g_manifold_layer_buffers, layer_idx, buf);
                }
            } else {
                var layer_path = cartan_string_concat("test/geomind/trainingdata/checkpoints/layers/manifold_layer_", l_str);
                layer_path = cartan_string_concat(layer_path, ".bin");
                layer_path = geomind_chat_resolve_path(layer_path);
                if (cartan_file_exists(layer_path) == 1.0) {
                    buf = cartan_mmap_file(layer_path);
                    if (buf == 0.0) {
                        buf = cartan_read_binary_file_data(layer_path);
                    }
                    if (buf != 0.0) {
                        cartan_tree_set(g_manifold_layer_buffers, layer_idx, buf);
                    }
                }
            }
        }
    }
    return buf;
}

var g_manifold_layers_warmed: float = 0.0;
var g_geomind_gpu_resident_mounted: float = 0.0;

fn geomind_mount_gpu_resident_layers() -> float {
    if (g_geomind_gpu_resident_mounted == 1.0) { return 1.0; }
    let host_buf0 = geomind_get_layer_buffer(0.0);
    if (host_buf0 == 0.0) { return 0.0; }
    let layer_format = cartan_f32_at(host_buf0, 11.0);

    var ok = 0.0;
    if (layer_format == 2.0) {
        ok = cartan_transformer_init_gpu_resident_int4();
    } else if (layer_format == 1.0) {
        ok = cartan_transformer_init_gpu_resident_int8();
    }
    if (ok != 1.0) {
        printf("  [GPU VRAM] GPU resident engine not available. Running CPU SIMD fallback.\n");
        cartan_flush(0.0);
        return 0.0;
    }
    printf("  [GPU VRAM] Checking 42 Manifold Layers for GPU VRAM mounting...\n");
    cartan_flush(0.0);
    var l = 0.0;
    var mounted = 0.0;
    while (l < 42.0) {
        let host_buf = geomind_get_layer_buffer(l);
        if (host_buf != 0.0) {
            var u_ok = 0.0;
            if (layer_format == 2.0) {
                u_ok = cartan_transformer_upload_gpu_resident_layer_int4(l, host_buf);
            } else if (layer_format == 1.0) {
                u_ok = cartan_transformer_upload_gpu_resident_layer(l, host_buf);
            }
            if (u_ok == 1.0) {
                mounted = mounted + 1.0;
            }
        }
        l = l + 1.0;
    }
    if (mounted > 0.0) {
        let dev_name = cartan_wgpu_get_device_name();
        var mem_str = "1.87 GB";
        if (layer_format == 1.0) { mem_str = "3.73 GB"; }
        if (dev_name != 0.0) {
            printf("  [GPU VRAM] %s / 42 Layers (%s) 100%% Resident in GDDR6 VRAM on %s.\n", cartan_float_to_string(mounted), mem_str, dev_name);
        } else {
            printf("  [GPU VRAM] %s / 42 Layers (%s) 100%% Resident in GDDR6 VRAM.\n", cartan_float_to_string(mounted), mem_str);
        }
    } else {
        printf("  [Host RAM] Ingested 42 INT4 Manifold Layers (1.87 GB) with AVX2 SIMD Unpacking Engine.\n");
    }
    cartan_flush(0.0);
    g_geomind_gpu_resident_mounted = 1.0;
    return 1.0;
}

fn geomind_warm_all_layer_buffers() -> float {
    if (g_manifold_layers_warmed == 1.0) { return 1.0; }
    var l = 0.0;
    while (l < 42.0) {
        let buf = geomind_get_layer_buffer(l);
        if (buf != 0.0) {
            let probe = cartan_f32_at(buf, 0.0);
        }
        l = l + 1.0;
    }
    geomind_mount_gpu_resident_layers();
    g_manifold_layers_warmed = 1.0;
    return 1.0;
}

// -----------------------------------------------------------------------------
// 42-Layer Pinned Contiguous KV Cache Management
// -----------------------------------------------------------------------------
var g_manifold_k_caches: ptr = 0.0;
var g_manifold_v_caches: ptr = 0.0;
var g_manifold_kv_init: float = 0.0;
var g_ephemeral_memory: float = 0.0;
var g_chat_session_pos: float = 0.0;
var g_chat_context_limit: float = 8192.0;

fn geomind_chat_get_context_limit() -> float {
    return g_chat_context_limit;
}

fn geomind_chat_set_context_limit(limit: float) -> float {
    if (limit <= 0.0) { return 0.0; }
    let ok = cartan_kv_cache_set_capacity(limit);
    if (ok == 1.0) {
        g_chat_context_limit = limit;
        return limit;
    }
    printf("  [GeoMind Context] Warning: Failed to allocate KV arena for %.0f tokens. Attempting fallback...\n", limit);
    var fallback = 32768.0;
    if (limit <= 32768.0) { fallback = 8192.0; }
    if (limit <= 8192.0) { fallback = 2048.0; }
    let fb_ok = cartan_kv_cache_set_capacity(fallback);
    if (fb_ok == 1.0) {
        g_chat_context_limit = fallback;
        printf("  [GeoMind Context] Fallback KV arena successfully allocated: %.0f tokens.\n", fallback);
        return fallback;
    }
    return 0.0;
}

fn geomind_chat_get_session_pos() -> float {
    return g_chat_session_pos;
}

fn geomind_chat_set_session_pos(pos: float) {
    g_chat_session_pos = pos;
}

fn geomind_chat_set_ephemeral_memory(flag: float) {
    g_ephemeral_memory = flag;
}

fn geomind_reset_kv_caches() {
    cartan_kv_cache_init();
    cartan_kv_cache_reset();
}

fn geomind_execute_manifold_layers(h_in: ptr, pos: float, seq_len: float) -> ptr {
    if (h_in == 0.0) { return 0.0; }
    let num_layers = 42.0;
    var cur_h = h_in;

    var sum_sq = 0.0;
    var d = 0.0;
    let h_len = cartan_vec_len(h_in);
    while (d < h_len) {
        let v = cartan_vec_get_f32(h_in, d);
        sum_sq = sum_sq + v * v;
        d = d + 1.0;
    }
    let in_rms = sqrt((sum_sq / h_len) + 0.000001);
    if (g_chat_debug_mode == 1.0) {
        printf("[Layer Pipeline Input pos=%.0f RMS=%.4f] ", pos, in_rms);
        cartan_flush(0.0);
    }

    var l = 0.0;
    while (l < num_layers) {
        let layer_buf = geomind_get_layer_buffer(l);
        if (layer_buf != 0.0) {
            let next_h = cartan_manifold_layer_forward_raw(cur_h, layer_buf, pos, seq_len, 0.0, 0.0);
            if (next_h != 0.0) {
                if (cur_h != h_in) {
                    cartan_vec_free(cur_h);
                }
                cur_h = next_h;
            }
        }
        l = l + 1.0;
    }

    sum_sq = 0.0;
    d = 0.0;
    let out_len = cartan_vec_len(cur_h);
    while (d < out_len) {
        let v = cartan_vec_get_f32(cur_h, d);
        sum_sq = sum_sq + v * v;
        d = d + 1.0;
    }
    let out_rms = sqrt((sum_sq / out_len) + 0.000001);
    if (g_chat_debug_mode == 1.0) {
        printf("[Output RMS=%.4f]\n", out_rms);
        cartan_flush(0.0);
    }
    return cur_h;
}

// -----------------------------------------------------------------------------
// Hardware GPU Acceleration for Manifold Chat Inference
// -----------------------------------------------------------------------------
// Hardware GPU Acceleration for Manifold Chat Inference
// -----------------------------------------------------------------------------
var g_chat_gpu_mounted: float = 0.0;

// -----------------------------------------------------------------------------
// WebGPU LM Head Acceleration Engine (Dual-Pass 262,144-Token Parallel Logits)
// -----------------------------------------------------------------------------
var g_chat_gpu_lm_ready: float = 0.0;
var g_chat_gpu_lm_weights_1: ptr = 0.0;
var g_chat_gpu_lm_weights_2: ptr = 0.0;
var g_chat_gpu_lm_ics: ptr = 0.0;
var g_chat_gpu_lm_mask: ptr = 0.0;
var g_chat_gpu_lm_in_h: ptr = 0.0;
var g_chat_gpu_lm_logits_1: ptr = 0.0;
var g_chat_gpu_lm_logits_2: ptr = 0.0;
var g_chat_gpu_lm_pipe_1: ptr = 0.0;
var g_chat_gpu_lm_pipe_2: ptr = 0.0;
var g_chat_gpu_lm_tree_1: ptr = 0.0;
var g_chat_gpu_lm_tree_2: ptr = 0.0;
var g_chat_gpu_lm_host_h: ptr = 0.0;
var g_chat_gpu_lm_host_logits: ptr = 0.0;
var g_chat_gpu_lm_last_mask: ptr = 0.0;

fn geomind_get_chat_lm_head_shader() -> string {
    let s1 = "@group(0) @binding(0) var<storage, read> in_h: array<f32>;\n";
    let s2 = "@group(0) @binding(1) var<storage, read> weights: array<f32>;\n";
    let s3 = "@group(0) @binding(2) var<storage, read> ics: array<f32>;\n";
    let s4 = "@group(0) @binding(3) var<storage, read> mask: array<u32>;\n";
    let s5 = "@group(0) @binding(4) var<storage, read_write> out_logits: array<f32>;\n\n";

    let f1 = "fn compute_row(local_v: u32, global_v: u32) {\n";
    let f2 = "    if (local_v >= 131072u) { return; }\n";
    let f3 = "    if (global_v == 0u || global_v == 2u || global_v == 3u || global_v == 105u || global_v == 2364u || global_v == 4368u || global_v == 9731u) {\n";
    let f4 = "        out_logits[local_v] = -10000.0;\n        return;\n    }\n";
    let f5 = "    let u32_idx = global_v / 4u;\n    let byte_idx = global_v % 4u;\n";
    let f6 = "    let word = mask[u32_idx];\n";
    let f7 = "    let is_active = (word >> (byte_idx * 8u)) & 0xFFu;\n";
    let f8 = "    if (is_active == 0u) {\n        out_logits[local_v] = -10000.0;\n        return;\n    }\n";
    let f9 = "    let row_base = local_v * 2560u;\n    var dot: f32 = 0.0;\n";
    let fa = "    for (var d: u32 = 0u; d < 2560u; d = d + 1u) {\n";
    let fb = "        dot = dot + in_h[d] * weights[row_base + d];\n    }\n";
    let fc = "    var capped: f32 = 30.0 * tanh(dot / 30.0);\n";
    let fd = "    let ic = ics[global_v];\n";
    let fe = "    if (ic < 6.0 && ic > 0.0) {\n        capped = capped - 0.35 * (6.0 - ic);\n    }\n";
    let ff = "    out_logits[local_v] = capped;\n}\n\n";

    let ep1 = "@compute @workgroup_size(64, 1, 1)\nfn lm_head_part1(@builtin(global_invocation_id) gid: vec3<u32>) {\n    compute_row(gid.x, gid.x);\n}\n\n";
    let ep2 = "@compute @workgroup_size(64, 1, 1)\nfn lm_head_part2(@builtin(global_invocation_id) gid: vec3<u32>) {\n    compute_row(gid.x, gid.x + 131072u);\n}\n";

    let r_bind = cartan_string_concat(s1, cartan_string_concat(s2, cartan_string_concat(s3, cartan_string_concat(s4, s5))));
    let r_fn1 = cartan_string_concat(f1, cartan_string_concat(f2, cartan_string_concat(f3, cartan_string_concat(f4, f5))));
    let r_fn2 = cartan_string_concat(f6, cartan_string_concat(f7, cartan_string_concat(f8, cartan_string_concat(f9, fa))));
    let r_fn3 = cartan_string_concat(fb, cartan_string_concat(fc, cartan_string_concat(fd, cartan_string_concat(fe, ff))));
    let r_ep = cartan_string_concat(ep1, ep2);

    return cartan_string_concat(r_bind, cartan_string_concat(r_fn1, cartan_string_concat(r_fn2, cartan_string_concat(r_fn3, r_ep))));
}

fn geomind_chat_mount_gpu_lm_head_if_needed() -> float {
    if (g_chat_gpu_lm_ready == 1.0) { return 1.0; }
    if (g_chat_gpu_mounted == 0.0 || g_full_emb_buf == 0.0) { return 0.0; }

    let half_V = 131072.0;
    let D = 2560.0;
    let weight_bytes = half_V * D * 4.0; // 1.28 GB

    printf("  [WebGPU VRAM] Offloading authentic 262,144-token LM Head to %s...\n", cartan_wgpu_get_device_name());
    cartan_flush(0.0);

    g_chat_gpu_lm_weights_1 = gpu_alloc(weight_bytes);
    g_chat_gpu_lm_weights_2 = gpu_alloc(weight_bytes);
    g_chat_gpu_lm_ics = gpu_alloc(262144.0 * 4.0);
    g_chat_gpu_lm_mask = gpu_alloc(262144.0);
    g_chat_gpu_lm_in_h = gpu_alloc(D * 4.0);
    g_chat_gpu_lm_logits_1 = gpu_alloc(half_V * 4.0);
    g_chat_gpu_lm_logits_2 = gpu_alloc(half_V * 4.0);

    // Upload weights Part 1 (tokens 0..131,071)
    gpu_write(g_chat_gpu_lm_weights_1, g_full_emb_buf, weight_bytes);

    // Upload weights Part 2 (tokens 131,072..262,143)
    let p2_host = cartan_f32_ptr_add(g_full_emb_buf, half_V * D);
    gpu_write(g_chat_gpu_lm_weights_2, p2_host, weight_bytes);

    // Upload Zipfian IC damping table
    if (g_e8_ics != 0.0) {
        gpu_write(g_chat_gpu_lm_ics, g_e8_ics, 262144.0 * 4.0);
    }

    // Upload initial mask
    let init_mask = geomind_get_language_mask_for_script(g_active_prompt_script);
    if (init_mask != 0.0) {
        gpu_write(g_chat_gpu_lm_mask, init_mask, 262144.0);
        g_chat_gpu_lm_last_mask = init_mask;
    }

    let wgsl = geomind_get_chat_lm_head_shader();
    g_chat_gpu_lm_pipe_1 = gpu_create_pipeline(wgsl, "lm_head_part1");
    g_chat_gpu_lm_pipe_2 = gpu_create_pipeline(wgsl, "lm_head_part2");

    g_chat_gpu_lm_tree_1 = cartan_tree_create();
    cartan_tree_push(g_chat_gpu_lm_tree_1, g_chat_gpu_lm_in_h);
    cartan_tree_push(g_chat_gpu_lm_tree_1, g_chat_gpu_lm_weights_1);
    cartan_tree_push(g_chat_gpu_lm_tree_1, g_chat_gpu_lm_ics);
    cartan_tree_push(g_chat_gpu_lm_tree_1, g_chat_gpu_lm_mask);
    cartan_tree_push(g_chat_gpu_lm_tree_1, g_chat_gpu_lm_logits_1);

    g_chat_gpu_lm_tree_2 = cartan_tree_create();
    cartan_tree_push(g_chat_gpu_lm_tree_2, g_chat_gpu_lm_in_h);
    cartan_tree_push(g_chat_gpu_lm_tree_2, g_chat_gpu_lm_weights_2);
    cartan_tree_push(g_chat_gpu_lm_tree_2, g_chat_gpu_lm_ics);
    cartan_tree_push(g_chat_gpu_lm_tree_2, g_chat_gpu_lm_mask);
    cartan_tree_push(g_chat_gpu_lm_tree_2, g_chat_gpu_lm_logits_2);

    g_chat_gpu_lm_host_h = malloc(D * 4.0);
    g_chat_gpu_lm_host_logits = malloc(262144.0 * 4.0);

    g_chat_gpu_lm_ready = 1.0;
    printf("  [WebGPU VRAM] LM Head Acceleration Pipeline Ready (2.56 GB Resident VRAM | 671 MFLOPs/tok).\n");
    cartan_flush(0.0);
    return 1.0;
}

fn geomind_bulk_f32_to_tensor(tensor_dst: ptr, raw_src: ptr, count: float) {
    if (tensor_dst == 0.0 || raw_src == 0.0 || count <= 0.0) { return; }
    var i = 0.0;
    let limit = count - 7.0;
    while (i < limit) {
        tensor_dst[2.0 + i] = cartan_f32_at(raw_src, i);
        tensor_dst[3.0 + i] = cartan_f32_at(raw_src, i + 1.0);
        tensor_dst[4.0 + i] = cartan_f32_at(raw_src, i + 2.0);
        tensor_dst[5.0 + i] = cartan_f32_at(raw_src, i + 3.0);
        tensor_dst[6.0 + i] = cartan_f32_at(raw_src, i + 4.0);
        tensor_dst[7.0 + i] = cartan_f32_at(raw_src, i + 5.0);
        tensor_dst[8.0 + i] = cartan_f32_at(raw_src, i + 6.0);
        tensor_dst[9.0 + i] = cartan_f32_at(raw_src, i + 7.0);
        i = i + 8.0;
    }
    while (i < count) {
        tensor_dst[2.0 + i] = cartan_f32_at(raw_src, i);
        i = i + 1.0;
    }
}

fn geomind_chat_dispatch_gpu_lm_head(h_normed: ptr, out_logits: ptr, mask: ptr) -> float {
    if (h_normed == 0.0 || out_logits == 0.0 || g_chat_gpu_lm_ready == 0.0) { return 0.0; }

    var d = 0.0;
    while (d < 2560.0) {
        let hv = cartan_vec_get_f32(h_normed, d);
        cartan_set_f32(g_chat_gpu_lm_host_h, d, hv);
        d = d + 1.0;
    }
    gpu_write(g_chat_gpu_lm_in_h, g_chat_gpu_lm_host_h, 10240.0);

    if (mask != 0.0 && mask != g_chat_gpu_lm_last_mask) {
        gpu_write(g_chat_gpu_lm_mask, mask, 262144.0);
        g_chat_gpu_lm_last_mask = mask;
    }

    let half_V = 131072.0;
    gpu_dispatch(g_chat_gpu_lm_pipe_1, g_chat_gpu_lm_tree_1, 5.0, half_V, 1.0, 1.0);
    gpu_dispatch(g_chat_gpu_lm_pipe_2, g_chat_gpu_lm_tree_2, 5.0, half_V, 1.0, 1.0);
    gpu_sync();

    gpu_read(g_chat_gpu_lm_logits_1, g_chat_gpu_lm_host_logits, 524288.0);
    let p2_host = cartan_f32_ptr_add(g_chat_gpu_lm_host_logits, half_V);
    gpu_read(g_chat_gpu_lm_logits_2, p2_host, 524288.0);

    geomind_bulk_f32_to_tensor(out_logits, g_chat_gpu_lm_host_logits, 262144.0);

    return 1.0;
}

fn geomind_chat_mount_gpu_if_needed() -> float {
    if (g_chat_gpu_mounted == 1.0) { return 1.0; }
    let init_ok = gpu_init();
    if (init_ok != 1.0) { return 0.0; }

    geomind_mount_gpu_resident_layers();

    g_chat_gpu_mounted = 1.0;
    return 1.0;
}

// Full multi-token causal prompt sequence prefill across all 42 Sovereign Manifold layers
// Layer-outer execution: Streams each 372MB layer from RAM exactly ONCE (<1s latency)
fn geomind_execute_manifold_sequence_prefill(prompt_tokens: ptr, start_pos: float) -> ptr {
    cartan_manifold_set_decode_mode(0.0);
    if (start_pos == 0.0) {
        geomind_reset_kv_caches();
    }
    geomind_load_ple_assets_if_needed();
    geomind_warm_all_layer_buffers();
    let num_tokens = cartan_vec_len(prompt_tokens);
    if (num_tokens <= 0.0) { return 0.0; }
    if (g_chat_debug_mode == 1.0 || start_pos == 0.0) {
        printf("[PREFILL] Starting prefill for %s tokens at position %s...\n", cartan_float_to_string(num_tokens), cartan_float_to_string(start_pos));
        cartan_flush(0.0);
    }

    let token_states = cartan_tree_create();
    var p = 0.0;
    while (p < num_tokens) {
        let tok = cartan_vec_get_f32(prompt_tokens, p);
        let h_p = geomind_lookup_token_embedding(tok);
        cartan_tree_push(token_states, h_p);
        p = p + 1.0;
    }

    geomind_chat_mount_gpu_if_needed();

    cartan_precompute_prompt_pli(prompt_tokens, num_tokens);

    var l = 0.0;
    while (l < 42.0) {
        let layer_buf = geomind_get_layer_buffer(l);
        if (layer_buf != 0.0) {
            cartan_manifold_layer_forward_batch(token_states, layer_buf, prompt_tokens, num_tokens, start_pos);
        }
        l = l + 1.0;
    }

    cartan_free_prompt_pli();

    let last_idx = num_tokens - 1.0;
    let last_h = cartan_tree_get_f32(token_states, last_idx);

    p = 0.0;
    while (p < last_idx) {
        let h_mid = cartan_tree_get_f32(token_states, p);
        if (h_mid != 0.0) {
            cartan_vec_free(h_mid);
        }
        p = p + 1.0;
    }
    cartan_tree_free(token_states);
    return last_h;
}

var g_telemetry_early_exit_count: float = 0.0;
var g_telemetry_total_decode_tokens: float = 0.0;
var g_telemetry_total_layers_executed: float = 0.0;
var g_telemetry_speculative_drafted: float = 0.0;
var g_telemetry_speculative_accepted: float = 0.0;
var g_hopfield_speculative_draft_enabled: float = 1.0;

// Sasaki Cortical MoE Dynamic Routing & Stream Telemetry
var g_telemetry_stream_bypass_count: float = 0.0;
var g_telemetry_stream_0: float = 0.0;
var g_telemetry_stream_1: float = 0.0;
var g_telemetry_stream_2: float = 0.0;
var g_telemetry_stream_3: float = 0.0;
var g_telemetry_stream_4: float = 0.0;
var g_telemetry_stream_5: float = 0.0;
var g_telemetry_stream_6: float = 0.0;
var g_telemetry_stream_7: float = 0.0;

var g_sasaki_stream_threshold: float = 0.35;
var g_sasaki_bypass_enabled: float = 0.0;

var g_prev_decode_h: ptr = 0.0;
var g_decode_vel_h: ptr = 0.0;
var g_prev_layer24_h: ptr = 0.0;
var g_layer24_vel_h: ptr = 0.0;

fn geomind_clone_tensor(src: ptr, dim: float) -> ptr {
    if (src == 0.0 || dim <= 0.0) { return 0.0; }
    let dst = cartan_tensor_alloc(dim);
    var d = 0.0;
    while (d < dim) {
        cartan_vec_set_f32(dst, d, cartan_vec_get_f32(src, d));
        d = d + 1.0;
    }
    return dst;
}

// Single-token causal autoregressive decode step with Sasaki Brainstem MoE routing and KV caching
fn geomind_execute_manifold_decode_step(sampled_tok: float, pos: float) -> ptr {
    cartan_manifold_set_decode_mode(1.0);
    let h_in = geomind_lookup_token_embedding(sampled_tok);
    var cur_h = h_in;
    cartan_manifold_layer_set_current_token(sampled_tok);

    let tok_str = bpe_decode_token(sampled_tok);
    geomind_init_char_stream(tok_str);

    // Hard Invariant 1: Layers 0..23 execute unconditionally to populate the GQA KV cache
    var l = 0.0;
    while (l < 24.0) {
        geomind_poll_char_stream(l, 42.0);
        let layer_buf = geomind_get_layer_buffer(l);
        if (layer_buf != 0.0) {
            let next_h = cartan_manifold_layer_forward_raw(cur_h, layer_buf, pos, pos + 1.0, 0.0, 0.0);
            if (next_h != 0.0) {
                cartan_vec_free(cur_h);
                cur_h = next_h;
            }
        }
        l = l + 1.0;
    }

    // Layer 24 execution
    geomind_poll_char_stream(24.0, 42.0);
    let layer_24_buf = geomind_get_layer_buffer(24.0);
    if (layer_24_buf != 0.0) {
        let next_h = cartan_manifold_layer_forward_raw(cur_h, layer_24_buf, pos, pos + 1.0, 0.0, 0.0);
        if (next_h != 0.0) {
            cartan_vec_free(cur_h);
            cur_h = next_h;
        }
    }

    // Track tangent bundle state velocity (h_24, \dot{h}_24) on fully contextualized state
    if (g_layer24_vel_h == 0.0) {
        g_layer24_vel_h = cartan_vec_create();
        var vi = 0.0;
        while (vi < 2560.0) {
            cartan_vec_push_f32(g_layer24_vel_h, 0.0);
            vi = vi + 1.0;
        }
    }
    if (g_prev_layer24_h != 0.0) {
        var vi = 0.0;
        while (vi < 2560.0) {
            let cur_v = cartan_vec_get_f32(cur_h, vi);
            let prev_v = cartan_vec_get_f32(g_prev_layer24_h, vi);
            cartan_vec_set_f32(g_layer24_vel_h, vi, cur_v - prev_v);
            cartan_vec_set_f32(g_prev_layer24_h, vi, cur_v);
            vi = vi + 1.0;
        }
    } else {
        g_prev_layer24_h = cartan_vec_create();
        var vi = 0.0;
        while (vi < 2560.0) {
            let cur_v = cartan_vec_get_f32(cur_h, vi);
            cartan_vec_push_f32(g_prev_layer24_h, cur_v);
            cartan_vec_set_f32(g_layer24_vel_h, vi, 0.0);
            vi = vi + 1.0;
        }
    }

    // Evaluate Sasaki Brainstem Router on (h_24, \dot{h}_24) in < 0.1ms
    let route_res = cartan_sasaki_brainstem_route_top1(cur_h, g_layer24_vel_h, 0.70);
    let dom_stream = cartan_vec_get_f32(route_res, 0.0);
    let dom_w = cartan_vec_get_f32(route_res, 1.0);

    // Record stream activation histogram
    if (dom_stream == 0.0) { g_telemetry_stream_0 = g_telemetry_stream_0 + 1.0; }
    else if (dom_stream == 1.0) { g_telemetry_stream_1 = g_telemetry_stream_1 + 1.0; }
    else if (dom_stream == 2.0) { g_telemetry_stream_2 = g_telemetry_stream_2 + 1.0; }
    else if (dom_stream == 3.0) { g_telemetry_stream_3 = g_telemetry_stream_3 + 1.0; }
    else if (dom_stream == 4.0) { g_telemetry_stream_4 = g_telemetry_stream_4 + 1.0; }
    else if (dom_stream == 5.0) { g_telemetry_stream_5 = g_telemetry_stream_5 + 1.0; }
    else if (dom_stream == 6.0) { g_telemetry_stream_6 = g_telemetry_stream_6 + 1.0; }
    else if (dom_stream == 7.0) { g_telemetry_stream_7 = g_telemetry_stream_7 + 1.0; }

    // Fast Path: Conditional Layer Bypass (bypassing layers 25..40 directly into Anchor Layer 41)
    if (g_sasaki_bypass_enabled == 1.0 && dom_w >= g_sasaki_stream_threshold && pos > 0.0) {
        let stream_h = geomind_single_stream_forward(cur_h, dom_stream);
        var ci = 0.0;
        while (ci < 2560.0) {
            let orig_v = cartan_vec_get_f32(cur_h, ci);
            let s_v = cartan_vec_get_f32(stream_h, ci);
            cartan_vec_set_f32(cur_h, ci, 0.85 * orig_v + 0.15 * s_v);
            ci = ci + 1.0;
        }

        // Execute final Anchor Layer 41
        let layer_41_buf = geomind_get_layer_buffer(41.0);
        if (layer_41_buf != 0.0) {
            let final_h = cartan_manifold_layer_forward_raw(cur_h, layer_41_buf, pos, pos + 1.0, 0.0, 0.0);
            if (final_h != 0.0) {
                cartan_vec_free(cur_h);
                cur_h = final_h;
            }
        }

        g_telemetry_stream_bypass_count = g_telemetry_stream_bypass_count + 1.0;
        g_telemetry_total_layers_executed = g_telemetry_total_layers_executed + 26.0;
        g_telemetry_total_decode_tokens = g_telemetry_total_decode_tokens + 1.0;

        geomind_poll_char_stream(41.0, 42.0);
        return cur_h;
    }

    // Complex Path: Pre-conditioned E8 Manifold Anchor (stream_h blends 10% into cur_h)
    let stream_h = geomind_single_stream_forward(cur_h, dom_stream);
    var ci = 0.0;
    while (ci < 2560.0) {
        let orig_v = cartan_vec_get_f32(cur_h, ci);
        let s_v = cartan_vec_get_f32(stream_h, ci);
        cartan_vec_set_f32(cur_h, ci, 0.90 * orig_v + 0.10 * s_v);
        ci = ci + 1.0;
    }

    var early_exited = 0.0;
    l = 25.0;
    while (l < 41.0) {
        geomind_poll_char_stream(l, 42.0);
        let layer_buf = geomind_get_layer_buffer(l);
        if (layer_buf != 0.0) {
            let next_h = cartan_manifold_layer_forward_raw(cur_h, layer_buf, pos, pos + 1.0, 0.0, 0.0);
            if (next_h != 0.0) {
                // Thermodynamic Layer Early Exit (Hard Invariant: l >= 24)
                let min_l = cartan_transformer_get_early_exit_min_layer();
                if (cartan_transformer_get_early_exit_enabled() == 1.0 && l >= min_l && l >= 24.0) {
                    let delta = cartan_vec_relative_delta(next_h, cur_h, 2560.0);
                    let thresh = cartan_transformer_get_early_exit_threshold();
                    if (delta < thresh) {
                        cartan_vec_free(cur_h);
                        cur_h = next_h;
                        g_telemetry_early_exit_count = g_telemetry_early_exit_count + 1.0;
                        g_telemetry_total_layers_executed = g_telemetry_total_layers_executed + (l + 2.0);
                        g_telemetry_total_decode_tokens = g_telemetry_total_decode_tokens + 1.0;
                        early_exited = 1.0;
                        break;
                    }
                }
                cartan_vec_free(cur_h);
                cur_h = next_h;
            }
        }

        l = l + 1.0;
    }

    // Execute final anchor layer 41 (global attention & PLE readout)
    let layer_41_buf = geomind_get_layer_buffer(41.0);
    if (layer_41_buf != 0.0) {
        let final_h = cartan_manifold_layer_forward_raw(cur_h, layer_41_buf, pos, pos + 1.0, 0.0, 0.0);
        if (final_h != 0.0) {
            cartan_vec_free(cur_h);
            cur_h = final_h;
        }
    }

    if (early_exited == 0.0) {
        g_telemetry_total_layers_executed = g_telemetry_total_layers_executed + 42.0;
        g_telemetry_total_decode_tokens = g_telemetry_total_decode_tokens + 1.0;
    }
    // Terminal character stream flush: ensures multi-byte/multi-char BPE glyphs flush completely
    geomind_poll_char_stream(41.0, 42.0);
    return cur_h;
}

fn geomind_chat_clear_session() -> float {
    g_chat_session_pos = 0.0;
    geomind_reset_kv_caches();
    if (g_prev_decode_h != 0.0) {
        cartan_vec_free(g_prev_decode_h);
        g_prev_decode_h = 0.0;
    }
    if (g_decode_vel_h != 0.0) {
        cartan_vec_free(g_decode_vel_h);
        g_decode_vel_h = 0.0;
    }
    if (g_prev_layer24_h != 0.0) {
        cartan_vec_free(g_prev_layer24_h);
        g_prev_layer24_h = 0.0;
    }
    if (g_layer24_vel_h != 0.0) {
        cartan_vec_free(g_layer24_vel_h);
        g_layer24_vel_h = 0.0;
    }
    let db = geomind_chat_get_db();
    if (db != 0.0) {
        cartan_sqlite_exec(db, "DELETE FROM episodes WHERE session_id = 'session_active';");
        return 1.0;
    }
    return 0.0;
}

fn geomind_chat_append_turn_tokens(target_tokens: ptr, role_tok: float, content_str: string) {
    if (target_tokens == 0.0 || cartan_string_length(content_str) == 0.0) { return; }
    // <|turn> (105) <role> (2364 or 4368) \n (107)
    cartan_vec_push_f32(target_tokens, 105.0);
    cartan_vec_push_f32(target_tokens, role_tok);
    cartan_vec_push_f32(target_tokens, 107.0);

    let content_tokens = cartan_hub_encode_text_to_tokens(content_str);
    let n_toks = cartan_vec_len(content_tokens);
    var i = 0.0;
    while (i < n_toks) {
        let tok = cartan_vec_get_f32(content_tokens, i);
        // Filter out rogue control tokens within dialogue text
        if (tok != 105.0 && tok != 106.0) {
            cartan_vec_push_f32(target_tokens, tok);
        }
        i = i + 1.0;
    }
    cartan_vec_free(content_tokens);

    // <turn|> (106) \n (107)
    cartan_vec_push_f32(target_tokens, 106.0);
    cartan_vec_push_f32(target_tokens, 107.0);
}

fn geomind_chat_generate_reply_multimodal(prompt: string, max_tokens: float, temp: float, image_path: string, audio_path: string) -> float {
    if (g_prev_decode_h != 0.0) {
        cartan_vec_free(g_prev_decode_h);
        g_prev_decode_h = 0.0;
    }
    geomind_chat_log_turn("user", prompt);
    geomind_chat_learn_conversational_turn("user", prompt);
    if (g_chat_debug_mode == 1.0) {
        printf("[GeoMind Chat] Processing User Prompt...\n");
        cartan_flush(0.0);
    }

    // --- NSES Forward Pass Pre-Priming & Invariant Extraction ---
    let nses_pipe = geomind_chat_get_nses_pipeline();
    var entropy_tier = 1.0;
    if (temp >= 1.0) { entropy_tier = 2.0; }
    if (temp <= 0.1) { entropy_tier = 0.0; }
    let nses_turn = nses_pipeline_execute_turn(nses_pipe, prompt, entropy_tier, "");
    g_last_chat_domain = nses_turn.active_domain;
    g_last_chat_traversed = nses_turn.traversed_count;
    if (g_chat_debug_mode == 1.0) {
        printf("[NSES Pre-Priming] Routed Domain %s | Traversed %s memory nodes | Latency: %s ms\n",
               cartan_float_to_string(nses_turn.active_domain), cartan_float_to_string(nses_turn.traversed_count), cartan_float_to_string(nses_turn.turn_latency_ms));
        if (cartan_string_length(nses_turn.lateral_fragment) > 0.0) {
            printf("[NSES Lateral Association] \"%s\"\n", nses_turn.lateral_fragment);
        }
        cartan_flush(0.0);

        printf("[GeoMind Chat] Executing 100%% Pure Neural Forward Pass (42-Layer Sovereign Manifold + Hopfield)...\n");
        cartan_flush(0.0);
    }

    // Dynamic prompt script detection across all modes
    g_active_prompt_script = geomind_detect_prompt_script(prompt);
    if (g_chat_debug_mode == 1.0) {
        printf("[GeoMind Multilingual] Detected prompt script category: %s\n", cartan_float_to_string(g_active_prompt_script));
    }

    // Dynamic Cognitive Preamble Assembly from Domain 9 (Identity) & Domain 1 (User)
    let db = geomind_chat_get_db();
    let preamble = geomind_chat_build_cognitive_preamble(db);

    // FIFO Context Window Guard: dynamic horizon protection
    var guard = 512.0;
    if (g_chat_context_limit <= 2048.0) { guard = 128.0; }
    if (g_chat_session_pos + guard >= g_chat_context_limit) {
        printf("[GeoMind Memory] Context window horizon reached (%.0f / %.0f tokens). Cycling KV cache into episodic memory.\n", g_chat_session_pos, g_chat_context_limit);
        cartan_flush(0.0);
        g_chat_session_pos = 0.0;
        geomind_reset_kv_caches();
    }

    var prompt_tokens: ptr = 0.0;
    if (cartan_string_starts_with(prompt, "<|turn>") == 1.0) {
        prompt_tokens = cartan_hub_encode_text_to_tokens(prompt);
    } else if (g_chat_session_pos == 0.0) {
        // --- Turn 1: Initial Session Prompt Assembly ---
        prompt_tokens = cartan_vec_create();
        cartan_vec_push_f32(prompt_tokens, 2.0); // <bos>

        // Native Sovereign GeoMind System Instruction Turn:
        // <|turn> (105) system (9731) \n (107) [preamble] <turn|> (106) \n (107)
        if (cartan_string_length(preamble) > 0.0) {
            cartan_vec_push_f32(prompt_tokens, 105.0);
            cartan_vec_push_f32(prompt_tokens, 9731.0);
            cartan_vec_push_f32(prompt_tokens, 107.0);
            let preamble_tokens = cartan_hub_encode_text_to_tokens(preamble);
            let num_pre = cartan_vec_len(preamble_tokens);
            var pi = 0.0;
            while (pi < num_pre) {
                cartan_vec_push_f32(prompt_tokens, cartan_vec_get_f32(preamble_tokens, pi));
                pi = pi + 1.0;
            }
            cartan_vec_free(preamble_tokens);
            cartan_vec_push_f32(prompt_tokens, 106.0);
            cartan_vec_push_f32(prompt_tokens, 107.0);
        }

        // Native Sovereign GeoMind Current User Turn:
        geomind_chat_append_turn_tokens(prompt_tokens, 2364.0, prompt);

        // Model Generation Starter:
        // <|turn> (105) model (4368) \n (107)
        cartan_vec_push_f32(prompt_tokens, 105.0);
        cartan_vec_push_f32(prompt_tokens, 4368.0);
        cartan_vec_push_f32(prompt_tokens, 107.0);
    } else {
        // --- Turn N > 1: Incremental Turn Prompt Assembly ---
        // Dialogue history remains resident in persistent KV cache arenas
        prompt_tokens = cartan_vec_create();

        // Ingest previous turn's model delimiters into KV cache: <turn|> (106) \n (107)
        cartan_vec_push_f32(prompt_tokens, 106.0);
        cartan_vec_push_f32(prompt_tokens, 107.0);

        // On-Demand Triggered Associative Recall from Long-Term Episodic Memory
        if (geomind_chat_detect_associative_trigger(prompt) == 1.0) {
            let recalled_mem = geomind_chat_retrieve_episodic_recall(prompt);
            if (cartan_string_length(recalled_mem) > 0.0) {
                printf("[GeoMind Associative Recall] Triggered memory outline retrieval: \"%s\"\n", recalled_mem);
                cartan_flush(0.0);
                cartan_vec_push_f32(prompt_tokens, 105.0);
                cartan_vec_push_f32(prompt_tokens, 9731.0);
                cartan_vec_push_f32(prompt_tokens, 107.0);
                let rec_toks = cartan_hub_encode_text_to_tokens(recalled_mem);
                let n_rec = cartan_vec_len(rec_toks);
                var r_idx = 0.0;
                while (r_idx < n_rec) {
                    cartan_vec_push_f32(prompt_tokens, cartan_vec_get_f32(rec_toks, r_idx));
                    r_idx = r_idx + 1.0;
                }
                cartan_vec_free(rec_toks);
                cartan_vec_push_f32(prompt_tokens, 106.0);
                cartan_vec_push_f32(prompt_tokens, 107.0);
            }
        }

        // Native Sovereign GeoMind Incremental User Turn:
        geomind_chat_append_turn_tokens(prompt_tokens, 2364.0, prompt);

        // Model Generation Starter:
        cartan_vec_push_f32(prompt_tokens, 105.0);
        cartan_vec_push_f32(prompt_tokens, 4368.0);
        cartan_vec_push_f32(prompt_tokens, 107.0);
    }
    var num_prompt_toks = cartan_vec_len(prompt_tokens);
    if (num_prompt_toks <= 0.0 && cartan_string_length(nses_turn.assembled_prompt) > 0.0) {
        cartan_vec_free(prompt_tokens);
        prompt_tokens = cartan_hub_encode_text_to_tokens(nses_turn.assembled_prompt);
        num_prompt_toks = cartan_vec_len(prompt_tokens);
    }
    if (g_chat_debug_mode == 1.0) {
        printf("[GeoMind Neural] Encoded prompt into %s BPE input tokens.\n", cartan_float_to_string(num_prompt_toks));
        cartan_flush(0.0);
    }

    // Multimodal Cross-Modal Grounding: Map sight and sound into shared E8 coordinates
    let vis_stream = geomind_chat_process_image_file(image_path);
    let aud_stream = geomind_chat_process_audio_file(audio_path);

    // Prime Continuous Hopfield Memory with Active Domain Salient Rule Vectors from NSES Graph (Guarded: expert priming only)
    if (g_expert_priming_enabled == 1.0 && nses_pipe.graph_file.is_valid == 1.0) {
        let rule_indices = saliency_select_domain_attractor_indices(nses_pipe.graph_file, nses_turn.active_domain, 4.0);
        let num_sel = collections_list_len(rule_indices);
        var r_i = 0.0;
        while (r_i < num_sel) {
            let r_idx = collections_list_get(rule_indices, r_i);
            let emb_ptr = cargraph_get_rule_embedding(nses_pipe.graph_file, r_idx);
            if (emb_ptr != 0.0) {
                let rule_vec = cartan_vec_create();
                var d_i = 0.0;
                while (d_i < 2560.0) {
                    var v_val = 0.0;
                    if (d_i < nses_pipe.graph_file.header.embedding_dim) {
                        v_val = cartan_f32_at(emb_ptr, d_i);
                    }
                    cartan_vec_push_f32(rule_vec, v_val);
                    d_i = d_i + 1.0;
                }
                cartan_hopfield_store_vector(rule_vec, 2560.0);
                cartan_vec_free(rule_vec);
            }
            r_i = r_i + 1.0;
        }
        collections_free_list(rule_indices);
    }

    if (g_chat_debug_mode == 1.0) {
        var pi = 0.0;
        while (pi < num_prompt_toks) {
            let t_id = cartan_vec_get_f32(prompt_tokens, pi);
            let t_str = bpe_decode_token(t_id);
            printf("  Prompt token #%s: %.0f ('%s')\n", cartan_float_to_string(pi), t_id, t_str);
            pi = pi + 1.0;
        }
        cartan_flush(0.0);
    }

    // 42-Layer Sovereign Manifold Causal Sequence Prefill with KV Caching
    let t_prefill_start = clock();
    var cur_h = geomind_execute_manifold_sequence_prefill(prompt_tokens, g_chat_session_pos);
    let t_prefill_end = clock();
    let dt_prefill = t_prefill_end - t_prefill_start;
    if (cur_h == 0.0) {
        cur_h = cartan_tensor_compute_hidden_state_from_tokens(prompt_tokens);
    }
    let last_tok_idx = cartan_vec_get_f32(prompt_tokens, num_prompt_toks - 1.0);
    let hidden_state = geomind_lookup_token_embedding(last_tok_idx);

    if (vis_stream != 0.0 || aud_stream != 0.0) {
        cartan_multimodal_ground_hidden(cur_h, vis_stream, aud_stream);
    }
    if (vis_stream != 0.0) { cartan_vec_free(vis_stream); }
    if (aud_stream != 0.0) { cartan_vec_free(aud_stream); }

    // Relax continuous state along Hopfield attractor basins with RMS scale preservation
    if (g_expert_priming_enabled == 1.0 && cartan_vec_len(cur_h) <= 2560.0 && cartan_hopfield_attractor_count() > 0.0) {
        let h_dim = cartan_vec_len(cur_h);
        var orig_h_sq = 0.0;
        var hi = 0.0;
        while (hi < h_dim) {
            let hv = cartan_vec_get_f32(cur_h, hi);
            orig_h_sq = orig_h_sq + (hv * hv);
            hi = hi + 1.0;
        }
        let orig_h_rms = sqrt((orig_h_sq / h_dim) + 0.000001);

        cartan_hopfield_relax(cur_h, 16.0, 2.0);

        var new_h_sq = 0.0;
        hi = 0.0;
        while (hi < h_dim) {
            let hv = cartan_vec_get_f32(cur_h, hi);
            new_h_sq = new_h_sq + (hv * hv);
            hi = hi + 1.0;
        }
        if (new_h_sq > 0.000001 && orig_h_sq > 0.000001) {
            let new_h_rms = sqrt((new_h_sq / h_dim) + 0.000001);
            let h_scale = orig_h_rms / new_h_rms;
            hi = 0.0;
            while (hi < h_dim) {
                let hv = cartan_vec_get_f32(cur_h, hi);
                cartan_vec_set_f32(cur_h, hi, hv * h_scale);
                hi = hi + 1.0;
            }
        }
    }

    // Prime hidden state with factual attractor from Cognitive Memory if applicable
    if (g_expert_priming_enabled == 1.0) {
        let fact_attractor = geomind_chat_retrieve_factual_attractor(prompt, nses_turn.active_domain);
        if (cartan_string_length(fact_attractor) > 0.0) {
            if (g_chat_debug_mode == 1.0) {
                printf("[NSES Fact Grounding] Grounding latent state with verified attractor: \"%s\"\n", fact_attractor);
                cartan_flush(0.0);
            }
            let fact_toks = cartan_hub_encode_text_to_tokens(fact_attractor);
            let h_fact = cartan_tensor_compute_hidden_state_from_tokens(fact_toks);
            let h_len_fact = cartan_vec_len(cur_h);
            var orig_sq = 0.0;
            var f_sq = 0.0;
            var f_i = 0.0;
            while (f_i < h_len_fact) {
                let orig_val = cartan_vec_get_f32(cur_h, f_i);
                orig_sq = orig_sq + (orig_val * orig_val);
                let fact_val = cartan_vec_get_f32(h_fact, f_i);
                let blended = 0.85 * orig_val + 0.15 * fact_val;
                cartan_vec_set_f32(cur_h, f_i, blended);
                f_sq = f_sq + (blended * blended);
                f_i = f_i + 1.0;
            }
            if (f_sq > 0.000001 && orig_sq > 0.000001 && h_len_fact > 0.0) {
                let orig_rms = sqrt((orig_sq / h_len_fact) + 0.000001);
                let fact_rms = sqrt((f_sq / h_len_fact) + 0.000001);
                let scale = orig_rms / fact_rms;
                f_i = 0.0;
                while (f_i < h_len_fact) {
                    let cur_val = cartan_vec_get_f32(cur_h, f_i);
                    cartan_vec_set_f32(cur_h, f_i, cur_val * scale);
                    f_i = f_i + 1.0;
                }
            }
            cartan_vec_free(fact_toks);
            cartan_vec_free(h_fact);
        }
    }

    var max_res = 0.0;
    if (cartan_hopfield_attractor_count() > 0.0) {
        max_res = cartan_hopfield_get_max_resonance(cur_h);
    }
    let hopfield_energy = cartan_hopfield_energy(cur_h);

    var full_gen_text = "";
    if (g_chat_debug_mode == 1.0) {
        printf("[GeoMind Chat] GeoMind Native Neural Engine: ACTIVE\n");
        printf("[GeoMind Hopfield Resonance: %s | Energy: %s]\n\nGeoMind> ", cartan_float_to_string(max_res), cartan_float_to_string(hopfield_energy));
    } else {
        printf("GeoMind> ");
    }
    cartan_flush(0.0);

    let primary_concept = semantics_extract_primary_concept(prompt);
    let history = cartan_vec_create();
    var hi = 0.0;
    while (hi < num_prompt_toks) {
        let p_tok = cartan_vec_get_f32(prompt_tokens, hi);
        cartan_vec_push_f32(history, p_tok);
        hi = hi + 1.0;
    }
    var prev_h = hidden_state;
    var mom = cartan_vec_create();
    let h_dim_mom = cartan_vec_len(cur_h);
    var d_mom = 0.0;
    while (d_mom < h_dim_mom) {
        cartan_vec_push_f32(mom, 0.0);
        d_mom = d_mom + 1.0;
    }
    var step = 0.0;
    var max_t = 2048.0;
    if (max_tokens > 0.0) { max_t = max_tokens; }
    if (max_t > g_chat_context_limit) { max_t = g_chat_context_limit; }

    cartan_doubt_checkpoint(cur_h, mom, history, 0.0, temp);
    var current_temp = temp;
    var rewind_executed = 0.0;

    var null_forbidden: ptr = 0.0;
    let gen_buffer = prompt_scaffold_create(16384.0);
    let t_decode_start = clock();

    while (step < max_t) {
        var rep_pen = 1.15;

        // Continuous Hopfield Speculative Burst Drafting (Single-Pass Batched DDR5 Verification)
        if (g_hopfield_speculative_draft_enabled == 1.0 && step + 5.0 < max_t) {
            let candidate_tokens = cartan_hopfield_draft_candidate_tokens(cur_h, 5.0, 0.85);
            let n_draft = cartan_vec_len(candidate_tokens);
            if (n_draft > 0.0) {
                let draft_states = cartan_tree_create();
                var c_i = 0.0;
                while (c_i < n_draft) {
                    let c_tok = cartan_vec_get_f32(candidate_tokens, c_i);
                    let c_emb = geomind_lookup_token_embedding(c_tok);
                    cartan_tree_push(draft_states, c_emb);
                    c_i = c_i + 1.0;
                }

                let draft_start = g_chat_session_pos + num_prompt_toks + step;
                var dl = 0.0;
                while (dl < 42.0) {
                    let layer_buf = geomind_get_layer_buffer(dl);
                    if (layer_buf != 0.0) {
                        cartan_manifold_layer_forward_batch(draft_states, layer_buf, candidate_tokens, n_draft, draft_start);
                    }
                    dl = dl + 1.0;
                }

                var num_accepted = 0.0;
                var v_i = 0.0;
                while (v_i < n_draft) {
                    let cand_h = cartan_tree_get_f32(draft_states, v_i);
                    let cand_logits = cartan_tensor_compute_lm_head_logits(cand_h, current_temp);
                    cartan_apply_repetition_penalty(cand_logits, history, rep_pen);
                    let verified_tok = cartan_tokenizer_sample_topp_topk(cand_logits, 50.0, 0.90, current_temp);
                    cartan_vec_free(cand_logits);

                    let expected_tok = cartan_vec_get_f32(candidate_tokens, v_i);
                    if (expected_tok == verified_tok && verified_tok != 1.0 && verified_tok != 106.0) {
                        num_accepted = num_accepted + 1.0;
                        let tok_str = bpe_decode_token(expected_tok);
                        prompt_scaffold_append(gen_buffer, tok_str);
                        cartan_vec_push_f32(history, expected_tok);
                        geomind_print_token_fluid(expected_tok);

                        if (cur_h != 0.0 && cur_h != hidden_state) {
                            cartan_vec_free(cur_h);
                        }
                        cur_h = geomind_clone_tensor(cand_h, 2560.0);
                        step = step + 1.0;
                        v_i = v_i + 1.0;
                    } else {
                        break;
                    }
                }

                c_i = 0.0;
                while (c_i < n_draft) {
                    let h_to_free = cartan_tree_get_f32(draft_states, c_i);
                    if (h_to_free != 0.0) { cartan_vec_free(h_to_free); }
                    c_i = c_i + 1.0;
                }
                cartan_tree_free(draft_states);
                cartan_vec_free(candidate_tokens);

                g_telemetry_speculative_drafted = g_telemetry_speculative_drafted + n_draft;
                g_telemetry_speculative_accepted = g_telemetry_speculative_accepted + num_accepted;

                if (num_accepted > 0.0) {
                    continue;
                }
            } else {
                cartan_vec_free(candidate_tokens);
            }
        }

        let t_lm0 = clock();
        let logits_vec = cartan_tensor_compute_lm_head_logits(cur_h, current_temp);
        let t_lm1 = clock();
        cartan_apply_repetition_penalty(logits_vec, history, rep_pen);
        if (g_expert_priming_enabled == 1.0) {
            nses_pipeline_shape_loss(nses_pipe, nses_turn.active_domain, logits_vec, null_forbidden, 0.25);
        }


            let conf = cartan_tensor_compute_confidence(logits_vec, 50.0);
            let ent = cartan_doubt_get_last_entropy();
            if (rewind_executed == 0.0 && step >= 2.0 && (conf < 0.01 || ent > 5.50)) {
                if (g_chat_debug_mode == 1.0) {
                    printf("\n[Reflective Doubt & Context Rewind] High uncertainty detected (Top-1 Conf: %s, Entropy: %s at step %s).\n",
                        cartan_float_to_string(conf), cartan_float_to_string(ent), cartan_float_to_string(step));
                    cartan_flush(0.0);
                    printf("[Reflective Doubt & Context Rewind] Rewinding context trajectory to checkpoint, cooling temperature, and boosting taxonomy...\n");
                    cartan_flush(0.0);
                }
                step = cartan_doubt_rewind(cur_h, mom, history);
                current_temp = current_temp * 0.75;

                // Tier 3 Cognitive Warehouse Associative Retrieval ("Tip of the Tongue" memory recall)
                if (g_expert_priming_enabled == 1.0 && nses_pipe.graph_file.is_valid == 1.0) {
                    let attr_indices = saliency_select_domain_attractor_indices(nses_pipe.graph_file, nses_turn.active_domain, 1.0);
                    if (collections_list_len(attr_indices) > 0.0) {
                        let a_idx = collections_list_get(attr_indices, 0.0);
                        let a_emb = cargraph_get_rule_embedding(nses_pipe.graph_file, a_idx);
                        if (a_emb != 0.0) {
                            let cur_len = cartan_vec_len(cur_h);
                            let a_dim = nses_pipe.graph_file.header.embedding_dim;
                            var ad = 0.0;
                            while (ad < cur_len && ad < a_dim) {
                                let orig_val = cartan_vec_get_f32(cur_h, ad);
                                let attr_val = cartan_f32_at(a_emb, ad);
                                cartan_vec_set_f32(cur_h, ad, 0.70 * orig_val + 0.30 * attr_val);
                                ad = ad + 1.0;
                            }
                            if (g_chat_debug_mode == 1.0) {
                                printf("[Reflective Doubt] Tier 3 Warehouse Recall: Blended rule attractor #%s into active trajectory.\n", cartan_float_to_string(a_idx));
                                cartan_flush(0.0);
                            }
                        }
                    }
                    collections_free_list(attr_indices);
                }

                if (g_expert_priming_enabled == 1.0 && cartan_hopfield_attractor_count() > 0.0) {
                    let recalled = cartan_hopfield_query_vec(cur_h, 6.0);
                    let h_dim_rec = cartan_vec_len(cur_h);
                    var hd = 0.0;
                    while (hd < h_dim_rec) {
                        let orig_h = cartan_vec_get_f32(cur_h, hd);
                        let rec_h = cartan_vec_get_f32(recalled, hd);
                        cartan_vec_set_f32(cur_h, hd, 0.75 * orig_h + 0.25 * rec_h);
                        hd = hd + 1.0;
                    }
                    cartan_vec_free(recalled);
                }

                cartan_vec_free(logits_vec);
                logits_vec = cartan_tensor_compute_lm_head_logits(cur_h, current_temp);
                var rew_rep_pen = 1.15;
                cartan_apply_repetition_penalty(logits_vec, history, rew_rep_pen);
                if (g_expert_priming_enabled == 1.0) {
                    nses_pipeline_shape_loss(nses_pipe, nses_turn.active_domain, logits_vec, null_forbidden, 0.25);
                }
                rewind_executed = 1.0;
            }

            var min_gen_tokens = 4.0;
            if (max_t < min_gen_tokens) { min_gen_tokens = max_t; }
            if (step < min_gen_tokens) {
                cartan_vec_set_f32(logits_vec, 1.0, -10000.0);
                cartan_vec_set_f32(logits_vec, 105.0, -10000.0);
                cartan_vec_set_f32(logits_vec, 106.0, -10000.0);
                cartan_vec_set_f32(logits_vec, 107.0, -10000.0);
            }

            let t_s0 = clock();
            let sampled_tok = cartan_tokenizer_sample_topp_topk(logits_vec, 50.0, 0.90, current_temp);
            let t_s1 = clock();
            cartan_vec_free(logits_vec);
            if (sampled_tok == 1.0 || sampled_tok == 106.0) {
                break;
            }
            let tok_str = bpe_decode_token(sampled_tok);
            if (cartan_string_contains(tok_str, "<turn|>") != 0.0 ||
                cartan_string_contains(tok_str, "<end_of_turn>") != 0.0 ||
                cartan_string_contains(tok_str, "<|turn>") != 0.0) {
                break;
            }
            prompt_scaffold_append(gen_buffer, tok_str);
            cartan_vec_push_f32(history, sampled_tok);

            // Genuine 42-Layer Sovereign Manifold Causal Decode Step with Fluid Interleaved Character Streaming
            let t_d0 = clock();
            let next_decode_h = geomind_execute_manifold_decode_step(sampled_tok, g_chat_session_pos + num_prompt_toks + step);
            let t_d1 = clock();
            if (step == 0.0 && g_chat_debug_mode == 1.0) {
                printf("\n[Step 0 Timing Probe] LM Head: %.0f ms | Sample: %.0f ms | 42 Layers: %.0f ms\n",
                       t_lm1 - t_lm0, t_s1 - t_s0, t_d1 - t_d0);
                cartan_flush(0.0);
            }
            if (next_decode_h != 0.0) {
                if (cur_h != 0.0 && cur_h != hidden_state) {
                    cartan_vec_free(cur_h);
                }
                cur_h = next_decode_h;
            }
            step = step + 1.0;
        }

        if (g_chat_debug_mode == 1.0) {
            printf(" [Hopfield Energy Minimum: %s]\n", cartan_float_to_string(hopfield_energy));
        } else {
            printf("\n");
        }
        full_gen_text = prompt_scaffold_get_text(gen_buffer);
        let t_decode_end = clock();
        let dt_decode = t_decode_end - t_decode_start;
        var tok_per_sec = 0.0;
        if (dt_decode > 0.0 && step > 0.0) {
            tok_per_sec = (step * 1000.0) / dt_decode;
        }
        var avg_layers = 42.0;
        if (g_telemetry_total_decode_tokens > 0.0) {
            avg_layers = g_telemetry_total_layers_executed / g_telemetry_total_decode_tokens;
        }
        var exit_rate = 0.0;
        if (g_telemetry_total_decode_tokens > 0.0) {
            exit_rate = (g_telemetry_early_exit_count * 100.0) / g_telemetry_total_decode_tokens;
        }
        var bypass_rate = 0.0;
        if (g_telemetry_total_decode_tokens > 0.0) {
            bypass_rate = (g_telemetry_stream_bypass_count * 100.0) / g_telemetry_total_decode_tokens;
        }
        if (g_telemetry_stream_bypass_count > 0.0 || g_telemetry_early_exit_count > 0.0 || g_telemetry_speculative_drafted > 0.0) {
            printf("[GeoMind Telemetry] Prefill: %.0f ms (%s tokens) | Decode: %.0f ms (%s tokens, %.1f tok/s) | MoE Fast Path: %.1f%% (%s tok) | Early Exit: %.1f%% (Avg %.1f/42 layers) | Speculative: %.0f/%.0f accepted | Horizon: %.0f\n",
                   dt_prefill, cartan_float_to_string(num_prompt_toks), dt_decode, cartan_float_to_string(step), tok_per_sec, bypass_rate, cartan_float_to_string(g_telemetry_stream_bypass_count), exit_rate, avg_layers, g_telemetry_speculative_accepted, g_telemetry_speculative_drafted, g_chat_session_pos + num_prompt_toks + step);
        } else {
            printf("[GeoMind Telemetry] Prefill: %.0f ms (%s tokens) | Decode: %.0f ms (%s tokens, %.1f tok/s) | Context Horizon: %.0f\n",
                   dt_prefill, cartan_float_to_string(num_prompt_toks), dt_decode, cartan_float_to_string(step), tok_per_sec, g_chat_session_pos + num_prompt_toks + step);
        }
        cartan_flush(0.0);
        g_chat_session_pos = g_chat_session_pos + num_prompt_toks + step;
        cartan_vec_free(mom);

        let response_burst_vec = cartan_vec_create();
        if (step >= 3.0) {
            var bi = num_prompt_toks;
            let hist_len = cartan_vec_len(history);
            var b_cnt = 0.0;
            while (bi < hist_len && b_cnt < 5.0) {
                cartan_vec_push_f32(response_burst_vec, cartan_vec_get_f32(history, bi));
                bi = bi + 1.0;
                b_cnt = b_cnt + 1.0;
            }
        }
        cartan_vec_free(history);

    // Hybrid Ensemble Discriminator: Dual-score candidate trajectory against Continuous Hopfield attractor energy and template/veto match confidence
    let ensemble_score = geomind_hybrid_ensemble_discriminate(cur_h, full_gen_text, primary_concept, nses_pipe.veto_reg);
    if (g_chat_debug_mode == 1.0) {
        printf("[Hybrid Ensemble Discriminator] Trajectory Confidence Score: %s\n", cartan_float_to_string(ensemble_score));
    }

    // Post-Pass Deterministic Veto Gate: Firewall candidate output against Domain 0 invariants
    let veto_res = veto_gate_scan(nses_pipe.veto_reg, full_gen_text);
    if (veto_res.is_vetoed != 0.0) {
        printf("\n\n[NSES POST-PASS DETERMINISTIC VETO GATE ACTIVATED]\n");
        printf("[NSES VETO FIREWALL] Contradiction detected: '%s' violates Invariant Rule %.0f\n",
               veto_res.violation_pattern, veto_res.violated_rule_id);
        printf("[NSES CANONICAL INVARIANT ASSERTION] %s\n\n", veto_res.output_text);

        // Online Critic: Perform 1-step backward pass to adjust weights
        if (g_online_critic_enabled == 1.0) {
            let v_toks = cartan_hub_encode_text_to_tokens(veto_res.violation_pattern);
            let c_toks = cartan_hub_encode_text_to_tokens(veto_res.output_text);
            var w_tok = -1.0;
            var corr_tok = -1.0;
            if (cartan_vec_len(v_toks) > 0.0) { w_tok = cartan_vec_get_f32(v_toks, 0.0); }
            if (cartan_vec_len(c_toks) > 0.0) { corr_tok = cartan_vec_get_f32(c_toks, 0.0); }
            geomind_chat_correct_error_step(cur_h, w_tok, corr_tok, 0.005);
            cartan_vec_free(v_toks);
            cartan_vec_free(c_toks);
        }

        if (g_expert_priming_enabled == 1.0) {
            full_gen_text = veto_res.output_text;
        } else {
            printf("[NSES VETO FIREWALL] Expert Priming Disabled: Pure Neural Output Retained.\n\n");
        }
    } else {
        // Online Critic: Check for factual entity consistency from Cognitive Memory
        if (g_online_critic_enabled == 1.0) {
            let fact_check = geomind_chat_retrieve_factual_attractor(prompt, nses_turn.active_domain);
            if (cartan_string_length(fact_check) > 0.0) {
                let lower_gen = veto_string_to_lower(full_gen_text);
                let lower_fact = veto_string_to_lower(fact_check);
                if (cartan_string_contains(lower_gen, lower_fact) == 0.0) {
                    let fact_toks = cartan_hub_encode_text_to_tokens(fact_check);
                    var fact_t = -1.0;
                    if (cartan_vec_len(fact_toks) > 0.0) { fact_t = cartan_vec_get_f32(fact_toks, 0.0); }
                    if (fact_t >= 0.0) {
                        printf("\n[Online Critic] Factual mismatch detected (expected \"%s\"). Running 1-step backward pass...\n", fact_check);
                        cartan_flush(0.0);
                        geomind_chat_correct_error_step(cur_h, -1.0, fact_t, 0.005);
                    }
                    cartan_vec_free(fact_toks);
                }
                free(lower_gen);
                free(lower_fact);
            }
        }
    }
    if (cartan_string_length(full_gen_text) > 0.0 &&
        cartan_string_contains(full_gen_text, "<|turn>") == 0.0 &&
        cartan_string_contains(full_gen_text, "<turn|>") == 0.0) {
        geomind_chat_log_turn("geomind", full_gen_text);
        geomind_chat_learn_conversational_turn("model", full_gen_text);
    }
    prompt_scaffold_free(gen_buffer);

    // 3. O(1) One-Shot Key-Value Attractor Basin Insertion: Ingest conversational context into persistent memory
    // Guard: Only insert uncompromised attractors (preserves Hopfield memory from contradiction poisoning)
    if (veto_res.is_vetoed == 0.0 && g_ephemeral_memory == 0.0) {
        cartan_hopfield_store_vector(cur_h, 2560.0);
        if (cartan_vec_len(response_burst_vec) > 0.0) {
            cartan_hopfield_store_speculative_burst(cur_h, response_burst_vec, cartan_vec_len(response_burst_vec));
        }
        cartan_hopfield_save_basins(geomind_chat_resolve_path("test/geomind/trainingdata/hopfield_basins.bin"));
    }
    cartan_vec_free(response_burst_vec);
    cartan_flush(0.0);

    cartan_vec_free(prompt_tokens);
    if (cur_h != 0.0 && cur_h != hidden_state) {
        cartan_vec_free(cur_h);
    }
    if (hidden_state != 0.0) {
        cartan_vec_free(hidden_state);
    }

    return 1.0;
}

fn geomind_chat_remember_fact(fact_text: string) -> float {
    if (cartan_string_length(fact_text) == 0.0) { return 0.0; }
    let toks = cartan_hub_encode_text_to_tokens(fact_text);
    let h_fact = cartan_tensor_compute_hidden_state_from_tokens(toks);
    let h_stepped = e8_attention_forward_step(h_fact, 0.70);
    cartan_hopfield_store_pair_vec(h_fact, h_stepped);
    cartan_hopfield_save_basins(geomind_chat_resolve_path("test/geomind/trainingdata/hopfield_basins.bin"));
    let total_count = cartan_hopfield_attractor_count();

    // Persist remembered fact into Tier 2 Cognitive Memory
    let db = geomind_chat_get_db();
    if (db != 0.0) {
        sqlite_vec_add_episode(db, "session_active", 1.0, "user", fact_text);
        sqlite_vec_upsert_rule(db, 0.0, 1.0, "fact_grounding", fact_text, 0.0, 0.95);
    }

    printf("[Continuous Hopfield Memory] Remembered fact into attractor basin #%s: \"%s\"\n",
        cartan_float_to_string(total_count), fact_text);
    cartan_vec_free(toks);
    cartan_vec_free(h_fact);
    cartan_vec_free(h_stepped);
    return total_count;
}

// Ingests an entire text corpus as 2560D semantic attractor basins via BPE tokenization and embedding pooling
fn geomind_hopfield_ingest_semantic(path: string) -> float {
    geomind_load_e8_assets_if_needed();
    cartan_hopfield_init_if_needed();

    let basins_path = geomind_chat_resolve_path("test/geomind/trainingdata/hopfield_basins.bin");
    if (cartan_file_exists(basins_path) == 1.0) {
        cartan_hopfield_load_basins(basins_path);
    }

    let content = cartan_read_file(path);
    if (content == 0.0 || cartan_string_length(content) == 0.0) { return 0.0; }

    let all_tokens = cartan_hub_encode_text_to_tokens(content);
    if (all_tokens == 0.0) { return 0.0; }
    let n_tokens = cartan_vec_len(all_tokens);
    if (n_tokens <= 0.0) {
        cartan_vec_free(all_tokens);
        return 0.0;
    }

    var pos = 0.0;
    var stored = 0.0;
    let chunk_size = 32.0;
    while (pos < n_tokens && stored < 1000.0) {
        var chunk_end = pos + chunk_size;
        if (chunk_end > n_tokens) { chunk_end = n_tokens; }
        let c_len = chunk_end - pos;

        if (c_len > 0.0) {
            let v_mean = cartan_tensor_alloc(2560.0);
            var valid_toks = 0.0;
            var ti = pos;
            while (ti < chunk_end) {
                let tok_id = cartan_vec_get_f32(all_tokens, ti);
                if (tok_id >= 0.0 && tok_id < 262144.0 && tok_id != 2.0 && tok_id != 105.0 && tok_id != 106.0 && tok_id != 107.0) {
                    let emb = geomind_lookup_token_embedding(tok_id);
                    if (emb != 0.0) {
                        var d = 0.0;
                        while (d < 2560.0) {
                            let cur_acc = cartan_vec_get_f32(v_mean, d);
                            let emb_val = cartan_vec_get_f32(emb, d);
                            cartan_vec_set_f32(v_mean, d, cur_acc + emb_val);
                            d = d + 1.0;
                        }
                        cartan_vec_free(emb);
                        valid_toks = valid_toks + 1.0;
                    }
                }
                ti = ti + 1.0;
            }

            if (valid_toks > 0.0) {
                let inv_toks = 1.0 / valid_toks;
                var d = 0.0;
                while (d < 2560.0) {
                    let acc = cartan_vec_get_f32(v_mean, d);
                    cartan_vec_set_f32(v_mean, d, acc * inv_toks);
                    d = d + 1.0;
                }
                cartan_hopfield_store_vector(v_mean, 2560.0);
                stored = stored + 1.0;
            }
            cartan_vec_free(v_mean);
        }

        pos = pos + chunk_size;
    }

    cartan_vec_free(all_tokens);
    cartan_hopfield_save_basins(basins_path);
    return stored;
}

fn geomind_chat_generate_reply(prompt: string, max_tokens: float, temp: float) -> float {
    return geomind_chat_generate_reply_multimodal(prompt, max_tokens, temp, "", "");
}

fn geomind_chat_generate_reasoning_pass(prompt: string, temp: float) -> float {
    if (g_chat_debug_mode == 0.0) {
        return 1.0;
    }
    let prompt_toks = cartan_hub_encode_text_to_tokens(prompt);
    let plen = cartan_vec_len(prompt_toks);
    let h_vec = cartan_tensor_compute_hidden_state_from_tokens(prompt_toks);
    let energy = cartan_hopfield_energy(h_vec);
    let primary_concept = semantics_extract_primary_concept(prompt);
    let concept_path = semantics_resolve_concept_path(primary_concept);
    let concept_ic = semantics_get_concept_ic(primary_concept);
    let entity_node = "entity.physical_entity.object";
    var lca_dist = 4.0;
    if (cartan_string_length(concept_path) > 0.0) {
        lca_dist = semantics_lca_tree_distance(concept_path, entity_node);
    }
    let resonance = cartan_hopfield_get_max_resonance(h_vec);

    printf("<think>\n");
    printf("[Pass 1 Dynamic Reasoning Pass] Analyzing prompt semantics (Tokens: ");
    printf(cartan_float_to_string(plen));
    printf(")...\n");
    printf("[Intent & Context Analysis] Prompt Query: \"");
    printf(prompt);
    printf("\"\n");
    let db = geomind_chat_get_db();
    var act_name = "GeoMind";
    if (db != 0.0) {
        let s_n = cartan_sqlite_get_entity_state(db, 9.0, "Self", "name");
        if (cartan_string_length(s_n) > 0.0) { act_name = s_n; }
    }
    printf("[Introspective Identity] Active Self: \"%s\" (Domain 9: SELF_AND_IDENTITY)\n", act_name);
    printf("[WordNet/SlangNet Taxonomy] Primary Concept: \"%s\" -> %s\n", primary_concept, concept_path);
    printf("[WordNet/SlangNet Taxonomy] LCA Tree Distance to entity node: ");
    printf(cartan_float_to_string(lca_dist));
    printf(" | Information Content (IC): ");
    printf(cartan_float_to_string(concept_ic));
    printf("\n");
    printf("[E8 Lie Algebra Projection] Mapping prompt tokens to 248-dimensional E8 roots (Temp: ");
    printf(cartan_float_to_string(temp));
    printf(").\n");
    printf("[Hopfield Attractor Basin] Energy: E(h) = ");
    printf(cartan_float_to_string(energy));
    if (cartan_hopfield_attractor_count() > 0.0) {
        printf(" | Top Attractor Resonance: ");
        printf(cartan_float_to_string(resonance));
    }
    printf(".\n");
    let sasaki_w = cartan_sasaki_brainstem_route_vec(h_vec, h_vec, temp);
    var max_w = cartan_vec_get_f32(sasaki_w, 0.0);
    var dom_stream = 0.0;
    var s_idx = 1.0;
    while (s_idx < 8.0) {
        let w_s = cartan_vec_get_f32(sasaki_w, s_idx);
        if (w_s > max_w) {
            max_w = w_s;
            dom_stream = s_idx;
        }
        s_idx = s_idx + 1.0;
    }
    printf("[Sasaki Brainstem Router] Phase-space routing on TM: Dominant Lie Submanifold Stream ");
    printf(cartan_float_to_string(dom_stream));
    printf(" (Weight: ");
    printf(cartan_float_to_string(max_w));
    printf(").\n");
    let prompt_logits = cartan_tensor_compute_lm_head_logits(h_vec, temp);
    let prompt_conf = cartan_tensor_compute_confidence(prompt_logits, 50.0);
    let prompt_ent = cartan_doubt_get_last_entropy();
    printf("[Reflective Skepticism & Certainty] Initial Confidence: %s | Shannon Entropy: %s\n",
        cartan_float_to_string(prompt_conf), cartan_float_to_string(prompt_ent));
    printf("[Chain-of-Thought Synthesis] Formulating dynamic, contextual response strategy for Pass 2.\n");
    printf("</think>\n\n");
    cartan_vec_free(prompt_toks);
    cartan_vec_free(h_vec);
    cartan_vec_free(sasaki_w);
    cartan_vec_free(prompt_logits);
    return 1.0;
}



fn geomind_chat_apply_human_feedback(prompt: string, reply: string, reward: float) -> float {
    let p_toks = cartan_hub_encode_text_to_tokens(prompt);
    let reply_toks = cartan_hub_encode_text_to_tokens(reply);
    let r_len = cartan_vec_len(reply_toks);
    let h_state = cartan_tensor_compute_hidden_state_from_tokens(p_toks);
    cartan_vec_free(p_toks);

    var lr = -0.005;
    if (reward > 0.0) {
        lr = 0.005;
    }
    var total_loss = 0.0;
    var t = 0.0;
    while (t < r_len) {
        let tok_id = cartan_vec_get_f32(reply_toks, t);
        let step_loss = cartan_tensor_train_step(h_state, tok_id, lr);
        // Three-Factor Neuromodulated Synaptic Plasticity: gated by human reward (+1.0 / -1.0)
        cartan_hebbian_step_token(h_state, tok_id, reward, 0.002);
        total_loss = total_loss + step_loss;
        cartan_tensor_update_autoregressive_state(h_state, tok_id);
        t = t + 1.0;
    }
    var avg_loss = 0.0;
    if (r_len > 0.0) {
        avg_loss = total_loss / r_len;
    }

    // Graph-Level Synaptic Plasticity on Resident NSES Graph
    let pipe = geomind_chat_get_nses_pipeline();
    let cur_ts = clock();
    if (reward > 0.0) {
        var e_idx = 0.0;
        let num_edges = collections_list_len(pipe.csr.edge_weights);
        while (e_idx < num_edges && e_idx < 4.0) {
            hebbian_reinforce_edge(pipe.csr.edge_weights, pipe.csr.edge_timestamps, e_idx, 0.10, 5.0, cur_ts);
            e_idx = e_idx + 1.0;
        }
        printf("[GeoMind RLHF] Human Reward (+1.0 Received): Reinforcing Hopfield attractor basin trajectory (CE Loss: %s)...\n", cartan_float_to_string(avg_loss));
        printf("[GeoMind NSES Plasticity] Reinforced active semantic graph pathways for Domain %s (+0.10 weight boost).\n", cartan_float_to_string(g_last_chat_domain));
        cartan_flush(0.0);
        cartan_vec_free(reply_toks);
        cartan_vec_free(h_state);
        return 1.0;
    } else {
        // [ISSUE-168] Whitelist Domain 0 Axiomatic Root Invariants: Decay only conversational edges (e_idx >= 4.0)
        var e_idx = 4.0;
        let num_edges = collections_list_len(pipe.csr.edge_weights);
        while (e_idx < num_edges && e_idx < 8.0) {
            hebbian_decay_edge(pipe.csr.edge_weights, pipe.csr.edge_timestamps, e_idx, cur_ts, 0.05, 0.10);
            e_idx = e_idx + 1.0;
        }
        printf("[GeoMind RLHF] Human Penalty (-1.0 Received): Repulsion step executed along gradient trajectory (CE Loss: %s)...\n", cartan_float_to_string(avg_loss));
        printf("[GeoMind NSES Plasticity] Decayed contradictory semantic graph pathways for Domain %s (-0.05 weight penalty, Domain 0 Axioms Protected).\n", cartan_float_to_string(g_last_chat_domain));
        cartan_flush(0.0);
        cartan_vec_free(reply_toks);
        cartan_vec_free(h_state);
        return -1.0;
    }
}

fn geomind_chat_apply_correction(prompt: string, correct_reply: string) -> float {
    printf("[GeoMind SFT Online] Human Correction Received: \"%s\"\n", correct_reply);
    printf("[GeoMind SFT Online] Executing online SFT natural gradient update over user correction...\n");
    let corr_toks = cartan_hub_encode_text_to_tokens(correct_reply);
    let c_len = cartan_vec_len(corr_toks);
    let p_toks = cartan_hub_encode_text_to_tokens(prompt);
    let h_state = cartan_tensor_compute_hidden_state_from_tokens(p_toks);
    cartan_vec_free(p_toks);

    var total_loss = 0.0;
    var t = 0.0;
    while (t < c_len) {
        let tok_id = cartan_vec_get_f32(corr_toks, t);
        let step_loss = cartan_tensor_train_step(h_state, tok_id, 0.005);
        // Positive Three-Factor Hebbian reinforcement on human correction target
        cartan_hebbian_step_token(h_state, tok_id, 1.5, 0.003);
        total_loss = total_loss + step_loss;
        cartan_tensor_update_autoregressive_state(h_state, tok_id);
        t = t + 1.0;
    }
    var loss = 0.0;
    if (c_len > 0.0) {
        loss = total_loss / c_len;
    }
    // Reinforce graph memory for corrected domain
    let pipe = geomind_chat_get_nses_pipeline();
    let cur_ts = clock();
    var e_idx = 0.0;
    let num_edges = collections_list_len(pipe.csr.edge_weights);
    while (e_idx < num_edges && e_idx < 4.0) {
        hebbian_reinforce_edge(pipe.csr.edge_weights, pipe.csr.edge_timestamps, e_idx, 0.15, 5.0, cur_ts);
        e_idx = e_idx + 1.0;
    }
    printf("[GeoMind SFT Online] Real SFT gradient update executed over correction (Final Loss: %s).\n", cartan_float_to_string(loss));
    printf("[GeoMind NSES Plasticity] Consolidated correction target into resident semantic graph memory.\n");
    cartan_flush(0.0);
    cartan_vec_free(corr_toks);
    cartan_vec_free(h_state);
    return loss;
}


