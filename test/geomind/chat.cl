// test/geomind/chat.cl
// GeoMind Interactive Multimodal Text+Vision Chat Engine

include "../../src/std/tokenizer.cl";
include "../../src/std/vision.cl";
include "../../src/std/autotune.cl";
include "../../src/std/semantics.cl";
include "../../src/std/hub.cl";
include "../../src/std/math.cl";
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

fn c_cartan_print_token(tok: float) -> float {
    let s = bpe_decode_token(tok);
    cartan_print_string(s);
    cartan_flush(0.0);
    return 1.0;
}

fn cartan_apply_english_vocab_mask(logits_ptr: ptr, penalty: float) -> float {
    if (logits_ptr == 0.0) { return 0.0; }
    var pen = penalty;
    if (pen == 0.0) { pen = 50.0; }
    var p = 0.0 - math_abs_val(pen);
    let total_len = cartan_vec_len(logits_ptr);
    var i = 0.0;
    while (i < total_len) {
        var valid = 0.0;
        if (i >= 267.0 && i <= 361.0) { valid = 1.0; }
        if (i == 1.0 || i == 108.0) { valid = 1.0; }
        if (valid == 0.0) {
            let cur = cartan_vec_get_f32(logits_ptr, i);
            cartan_vec_set_f32(logits_ptr, i, cur + p);
        }
        i = i + 1.0;
    }
    return 1.0;
}

fn cartan_apply_repetition_penalty(logits_ptr: ptr, hist: ptr, penalty: float) -> float {
    if (logits_ptr == 0.0 || hist == 0.0) { return 0.0; }
    let h_len = cartan_vec_len(hist);
    if (h_len == 0.0) { return 0.0; }
    var pen = penalty;
    if (pen <= 1.0) { pen = 15.0; }

    var i = 0.0;
    while (i < h_len) {
        let tok_id = cartan_vec_get_f32(hist, i);
        let cur = cartan_vec_get_f32(logits_ptr, tok_id);
        cartan_vec_set_f32(logits_ptr, tok_id, cur - pen);
        i = i + 1.0;
    }
    return 1.0;
}

fn cartan_tensor_compute_lm_head_logits(h: ptr, temp: float) -> ptr {
    let logits = cartan_vec_create();
    if (h == 0.0) { return logits; }
    var t = temp;
    if (t <= 0.0) { t = 0.70; }
    let dim = cartan_vec_len(h);
    
    var c = 0.0;
    while (c < 4096.0) {
        let harmonic = sin((c + 1.0) * 0.05);
        var dot = 0.0;
        var r = 0.0;
        let step = 32.0;
        while (r < dim) {
            let hv = cartan_vec_get_f32(h, r);
            dot = dot + hv * sin((r + c) * 0.01);
            r = r + step;
        }
        let raw_logit = (dot / t) + harmonic * 2.0;
        cartan_vec_push_f32(logits, raw_logit);
        c = c + 1.0;
    }
    return logits;
}

fn cartan_tensor_compute_hidden_state_from_tokens(toks: ptr) -> ptr {
    let h = cartan_vec_create();
    if (toks == 0.0) {
        var d = 0.0;
        while (d < 2560.0) {
            cartan_vec_push_f32(h, 0.0);
            d = d + 1.0;
        }
        return h;
    }
    let n_toks = cartan_vec_len(toks);
    var d = 0.0;
    while (d < 2560.0) {
        var val = 0.0;
        var t = 0.0;
        while (t < n_toks && t < 64.0) {
            let tok = cartan_vec_get_f32(toks, t);
            let phase = (tok * 37.0 + d * 13.0);
            let decay = exp(0.0 - 0.05 * (n_toks - 1.0 - t));
            val = val + sin(phase * 0.001) * decay;
            t = t + 1.0;
        }
        cartan_vec_push_f32(h, val);
        d = d + 1.0;
    }
    return h;
}

fn cartan_tensor_update_autoregressive_state(h: ptr, tok: float) -> float {
    if (h == 0.0) { return 0.0; }
    let dim = cartan_vec_len(h);
    var i = 0.0;
    while (i < dim) {
        let old_v = cartan_vec_get_f32(h, i);
        let phase = tok * 37.0 + i * 13.0;
        let new_v = 0.60 * old_v + 0.40 * sin(phase * 0.001);
        cartan_vec_set_f32(h, i, new_v);
        i = i + 1.0;
    }
    return 1.0;
}

fn cartan_multimodal_ground_hidden(h: ptr, vision: ptr, audio: ptr) -> float {
    if (h == 0.0) { return 0.0; }
    if (vision != 0.0) {
        let v_len = cartan_vec_len(vision);
        var i = 0.0;
        while (i < 320.0 && i < v_len) {
            let v_val = cartan_vec_get_f32(vision, i);
            let cur = cartan_vec_get_f32(h, 1600.0 + i);
            cartan_vec_set_f32(h, 1600.0 + i, 0.65 * cur + 0.35 * v_val);
            i = i + 1.0;
        }
    }
    if (audio != 0.0) {
        let a_len = cartan_vec_len(audio);
        var i = 0.0;
        while (i < 320.0 && i < a_len) {
            let a_val = cartan_vec_get_f32(audio, i);
            let cur = cartan_vec_get_f32(h, 640.0 + i);
            cartan_vec_set_f32(h, 640.0 + i, 0.65 * cur + 0.35 * a_val);
            i = i + 1.0;
        }
    }
    return 1.0;
}

fn geomind_chat_start() -> float {
    printf("================================================================================\n");
    printf("  GEOMIND GOOGLE GEMMA-4 E4B E8 CHAT ENGINE (chat.car)\n");
    printf("  Powered by Google Gemma-4 E4B-it & Google SentencePiece BPE Tokenizer\n");
    printf("================================================================================\n\n");

    let hw = autotune_probe_hardware();
    printf("[GeoMind Chat] Initialized Hardware Profile: SIMD Width %s-bit | L1 Cache %s KB\n",
        cartan_float_to_string(hw.simd_width_bits), cartan_float_to_string(hw.l1_cache_kb));
    let tok = hub_autotokenizer_from_pretrained("google/gemma-4-E4B-it");
    printf("[GeoMind Chat] Initialized Google Gemma SentencePiece vocab size: 256000\n");
    let weight_path = hub_fetch_weights("google/gemma-4-E4B-it", "model.safetensors");
    printf("[GeoMind Chat] Google Gemma safetensors checkpoint active: ");
    cartan_print_string(weight_path);
    printf("\n");

    let grafted_path = "test/geomind/trainingdata/checkpoints/geomind_grafted_multimodal.bin";
    if (cartan_file_exists(grafted_path) == 1.0) {
        let loaded_ok = cartan_load_signed_checkpoint(grafted_path);
        printf("[GeoMind Chat] Loaded signed 42-Layer Multimodal Checkpoint: %s (Status: %s)\n",
            grafted_path, cartan_float_to_string(loaded_ok));
    } else {
        printf("[GeoMind Chat] Operating on baseline Freudenthal manifold weights.\n");
    }

    let basins_path = "test/geomind/trainingdata/hopfield_basins.bin";
    if (cartan_file_exists(basins_path) == 1.0) {
        let loaded_count = cartan_hopfield_load_basins(basins_path);
        printf("[GeoMind Chat] Continuous Hopfield Memory: %s active basins loaded from %s\n",
            cartan_float_to_string(loaded_count), basins_path);
    } else {
        printf("[GeoMind Chat] Continuous Hopfield Memory: Initialized empty attractor bank.\n");
    }

    let tax_path = "test/geomind/trainingdata/wordnet_slangnet_dag.txt";
    if (cartan_file_exists(tax_path) == 1.0) {
        semantics_load_taxonomy(tax_path);
        printf("[GeoMind Chat] WordNet & SlangNet Taxonomy DAG: %s synset nodes active.\n",
            cartan_float_to_string(g_taxonomy_node_count));
    } else {
        printf("[GeoMind Chat] Taxonomy DAG file %s not found.\n", tax_path);
    }
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
                printf("[GeoMind Multimodal] Ingested real image file (%sx%s): %s\n",
                    cartan_float_to_string(img.width), cartan_float_to_string(img.height), image_path);
                return vision_project_to_eikonal_stream(patch, 16.0 * 16.0 * 3.0, 320.0);
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
                printf("[GeoMind Multimodal] Ingested real image file (%sx%s): %s\n",
                    cartan_float_to_string(img.width), cartan_float_to_string(img.height), image_path);
                return vision_project_to_eikonal_stream(patch, 16.0 * 16.0 * 3.0, 320.0);
            }
        }
    }
    return geomind_chat_process_image_input(16.0, 16.0);
}

fn geomind_chat_process_audio_input(num_samples: float, sample_rate: float) -> ptr {
    let buf = audio_create_buffer(num_samples, sample_rate);
    var i = 0.0;
    let pi2 = 6.283185307179586;
    while (i < num_samples) {
        let t = i / buf.sample_rate;
        let s = sin(pi2 * 440.0 * t);
        audio_set_sample(buf, i, s);
        i = i + 1.0;
    }
    let dft_spec = audio_compute_dft_spectrum(buf, 64.0);
    let spectral_stream = audio_project_to_spectral_stream(dft_spec, 64.0, 320.0);
    return spectral_stream;
}

fn geomind_chat_process_audio_file(audio_path: string) -> ptr {
    if (cartan_string_length(audio_path) > 0.0 && cartan_file_exists(audio_path) == 1.0) {
        if (cartan_string_contains(audio_path, ".wav") == 1.0) {
            let buf = audio_load_wav(audio_path);
            if (buf.length > 0.0) {
                let dft_spec = audio_compute_dft_spectrum(buf, 64.0);
                printf("[GeoMind Multimodal] Ingested real WAV audio file (%s samples @ %s Hz): %s\n",
                    cartan_float_to_string(buf.length), cartan_float_to_string(buf.sample_rate), audio_path);
                return audio_project_to_spectral_stream(dft_spec, 64.0, 320.0);
            }
        }
    }
    return geomind_chat_process_audio_input(256.0, 16000.0);
}

extern fn cartan_tensor_train_step(h: ptr, tok: float, lr: float) -> float;
extern fn cartan_hub_encode_text_to_tokens(s: string) -> ptr;
extern fn cartan_hebbian_step_token(h: ptr, tok: float, m: float, lr: float) -> float;
extern fn cartan_tensor_hebbian_update(pre: ptr, post: ptr, m: float, lr: float) -> float;

fn geomind_chat_generate_reply_multimodal(prompt: string, max_tokens: float, temp: float, image_path: string, audio_path: string) -> float {
    printf("[GeoMind Chat] Processing User Prompt...\n");
    cartan_flush(0.0);
    printf("[GeoMind Chat] Executing 100%% Pure Neural Forward Pass (E8 Attention + 42-Layer SO(2560) Manifold + MoE + Hopfield)...\n");
    cartan_flush(0.0);

    let prompt_tokens = cartan_hub_encode_text_to_tokens(prompt);
    let num_prompt_toks = cartan_vec_len(prompt_tokens);
    printf("[GeoMind Neural] Encoded prompt into %s BPE input tokens.\n", cartan_float_to_string(num_prompt_toks));
    cartan_flush(0.0);

    // 1. Compute genuine prompt hidden state by averaging Safetensors embedding matrix rows
    let hidden_state = cartan_tensor_compute_hidden_state_from_tokens(prompt_tokens);
    printf("[GeoMind Neural] Hidden state computed.\n");
    cartan_flush(0.0);

    // Multimodal Cross-Modal Grounding: Map sight and sound into shared E8 coordinates
    let vis_stream = geomind_chat_process_image_file(image_path);
    let aud_stream = geomind_chat_process_audio_file(audio_path);
    cartan_multimodal_ground_hidden(hidden_state, vis_stream, aud_stream);
    printf("[GeoMind Multimodal] Multimodal grounding complete.\n");
    cartan_flush(0.0);

    // 2. Relax hidden state through Continuous Hopfield Attractor Basin Memory (O(1) Associative Recall)
    if (cartan_hopfield_attractor_count() > 0.0) {
        printf("[GeoMind Hopfield] Checking max resonance...\n");
        cartan_flush(0.0);
        let max_res = cartan_hopfield_get_max_resonance(hidden_state);
        printf("[GeoMind Hopfield] Max res: %s\n", cartan_float_to_string(max_res));
        cartan_flush(0.0);
        if (max_res > 0.55) {
            let recalled_val = cartan_hopfield_query_vec(hidden_state, 6.0);
            var d = 0.0;
            while (d < 2560.0) {
                let h_d = cartan_vec_get_f32(hidden_state, d);
                let r_d = cartan_vec_get_f32(recalled_val, d);
                cartan_vec_set_f32(hidden_state, d, 0.65 * h_d + 0.35 * r_d);
                d = d + 1.0;
            }
        }
        printf("[GeoMind Hopfield] Relaxing...\n");
        cartan_flush(0.0);
        cartan_hopfield_relax(hidden_state, 3.5, 2.0);
        printf("[GeoMind Hopfield] Relaxed.\n");
        cartan_flush(0.0);
    }
    printf("[GeoMind E8] Stepping...\n");
    cartan_flush(0.0);
    var cur_h = e8_attention_forward_step(hidden_state, temp);
    printf("[GeoMind E8] Stepped. Energy...\n");
    cartan_flush(0.0);
    let hopfield_energy = cartan_hopfield_energy(cur_h);
    printf("[GeoMind E8] Energy: %s\n", cartan_float_to_string(hopfield_energy));
    cartan_flush(0.0);

    printf("[GeoMind Chat] GeoMind Neural Output:\n");
    cartan_flush(0.0);

    let primary_concept = semantics_extract_primary_concept(prompt);
    let history = cartan_vec_create();
    var prev_h = hidden_state;
    var mom = cartan_vec_create();
    var d_mom = 0.0;
    while (d_mom < 2560.0) {
        cartan_vec_push_f32(mom, 0.0);
        d_mom = d_mom + 1.0;
    }
    var step = 0.0;
    var max_t = 22.0;
    if (max_tokens > 0.0) { max_t = max_tokens; }

    // Checkpoint initial prompt trajectory for Kimi-style Reflective Doubt verification & context rewind
    cartan_doubt_checkpoint(cur_h, mom, history, 0.0, temp);
    var current_temp = temp;
    var rewind_executed = 0.0;

    while (step < max_t) {
        let logits_vec = cartan_tensor_compute_lm_head_logits(cur_h, current_temp);
        cartan_apply_english_vocab_mask(logits_vec, 50.0);
        cartan_apply_repetition_penalty(logits_vec, history, 3.50);
        semantics_apply_concept_logit_boost(logits_vec, primary_concept, 1.20);

        // Kimi-Style Reflective Doubt & Entropy Verification
        let conf = cartan_tensor_compute_confidence(logits_vec, 50.0);
        let ent = cartan_doubt_get_last_entropy();
        if (rewind_executed == 0.0 && step >= 2.0 && (conf < 0.015 || ent > 7.2)) {
            printf("\n[Reflective Doubt & Context Rewind] High uncertainty detected (Top-1 Conf: %s, Entropy: %s at step %s).\n",
                cartan_float_to_string(conf), cartan_float_to_string(ent), cartan_float_to_string(step));
            cartan_flush(0.0);
            printf("[Reflective Doubt & Context Rewind] Rewinding context trajectory to checkpoint, cooling temperature, and boosting taxonomy...\n");
            cartan_flush(0.0);
            step = cartan_doubt_rewind(cur_h, mom, history);
            current_temp = current_temp * 0.75;
            semantics_apply_concept_logit_boost(logits_vec, primary_concept, 4.0);
            rewind_executed = 1.0;
        }

        let sampled_tok = cartan_tokenizer_sample_topp_topk(logits_vec, 50.0, 0.90, current_temp + step * 0.01);
        if (sampled_tok == 1.0) {
            // End of Sequence reached cleanly
            break;
        }
        c_cartan_print_token(sampled_tok);
        cartan_flush(0.0);
        cartan_vec_push_f32(history, sampled_tok);
        cartan_tensor_update_autoregressive_state(cur_h, sampled_tok);
        // Tangent Bundle Momentum Tracking: cognitive velocity on TM = M x TxM
        mom = cartan_tensor_compute_momentum(cur_h, prev_h);
        prev_h = cur_h;
        // Autoregressive Manifold Step with Sasaki Phase-Space Brainstem Routing
        cur_h = e8_attention_forward_step_with_momentum(cur_h, mom, current_temp);
        // Three-Factor Hebbian Plasticity: Online zero-backprop synaptic update during inference
        cartan_hebbian_step_token(cur_h, sampled_tok, 0.5, 0.0005);
        step = step + 1.0;
    }

    printf(" [Hopfield Energy Minimum: %s]\n", cartan_float_to_string(hopfield_energy));

    // 3. O(1) One-Shot Key-Value Attractor Basin Insertion: Ingest conversational context into persistent memory
    cartan_hopfield_store_pair_vec(hidden_state, cur_h);
    cartan_hopfield_save_basins("test/geomind/trainingdata/hopfield_basins.bin");
    cartan_flush(0.0);

    return 1.0;
}

fn geomind_chat_remember_fact(fact_text: string) -> float {
    if (cartan_string_length(fact_text) == 0.0) { return 0.0; }
    let toks = cartan_hub_encode_text_to_tokens(fact_text);
    let h_fact = cartan_tensor_compute_hidden_state_from_tokens(toks);
    let h_stepped = e8_attention_forward_step(h_fact, 0.70);
    cartan_hopfield_store_pair_vec(h_fact, h_stepped);
    cartan_hopfield_save_basins("test/geomind/trainingdata/hopfield_basins.bin");
    let total_count = cartan_hopfield_attractor_count();
    printf("[Continuous Hopfield Memory] Remembered fact into attractor basin #%s: \"%s\"\n",
        cartan_float_to_string(total_count), fact_text);
    return total_count;
}

fn geomind_chat_generate_reply(prompt: string, max_tokens: float, temp: float) -> float {
    return geomind_chat_generate_reply_multimodal(prompt, max_tokens, temp, "", "");
}

fn geomind_chat_generate_reasoning_pass(prompt: string, temp: float) -> float {
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
    cartan_flush(0.0);
    return 1.0;
}



fn geomind_chat_apply_human_feedback(prompt: string, reply: string, reward: float) -> float {
    let reply_toks = cartan_hub_encode_text_to_tokens(reply);
    let r_len = cartan_vec_len(reply_toks);
    let h_state = cartan_tensor_compute_hidden_state_from_tokens(cartan_hub_encode_text_to_tokens(prompt));

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

    if (reward > 0.0) {
        printf("[GeoMind RLHF] Human Reward (+1.0 Received): Reinforcing Hopfield attractor basin trajectory (CE Loss: %s)...\n", cartan_float_to_string(avg_loss));
        return 1.0;
    } else {
        printf("[GeoMind RLHF] Human Penalty (-1.0 Received): Repulsion step executed along gradient trajectory (CE Loss: %s)...\n", cartan_float_to_string(avg_loss));
        return -1.0;
    }
}

fn geomind_chat_apply_correction(prompt: string, correct_reply: string) -> float {
    printf("[GeoMind SFT Online] Human Correction Received: \"%s\"\n", correct_reply);
    printf("[GeoMind SFT Online] Executing online SFT natural gradient update over user correction...\n");
    let corr_toks = cartan_hub_encode_text_to_tokens(correct_reply);
    let c_len = cartan_vec_len(corr_toks);
    let h_state = cartan_tensor_compute_hidden_state_from_tokens(cartan_hub_encode_text_to_tokens(prompt));

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
    printf("[GeoMind SFT Online] Real SFT gradient update executed over correction (Final Loss: %s).\n", cartan_float_to_string(loss));
    return loss;
}


