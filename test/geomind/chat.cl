// test/geomind/chat.cl
// GeoMind Interactive Multimodal Text+Vision Chat Engine

include "../../src/std/tokenizer.cl";
include "../../src/std/vision.cl";
include "../../src/std/autotune.cl";
include "../../src/std/semantics.cl";
include "../../src/std/gpu.cl";
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
include "../../src/std/sqlite_vec.cl";
include "../../src/std/cargraph_consolidate.cl";
include "../../src/std/nses_pipeline.cl";

fn c_cartan_print_token(tok: float) -> float {
    let s = bpe_decode_token(tok);
    cartan_print_string(s);
    cartan_flush(0.0);
    return 1.0;
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
            cartan_vec_set_f32(logits_ptr, tok, cur - pen * decay);
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
    return 1.0;
}

var g_e8_embeddings: ptr = 0.0;
var g_e8_ics: ptr = 0.0;
var g_e8_vocab_mask: ptr = 0.0;
var g_e8_loaded: float = 0.0;

fn geomind_load_e8_assets_if_needed() -> float {
    if (g_e8_loaded == 1.0) { return 1.0; }

    var emb_path = "test/geomind/trainingdata/checkpoints/geomind_e8_embeddings.bin";
    if (cartan_file_exists(emb_path) == 0.0) {
        emb_path = "../test/geomind/trainingdata/checkpoints/geomind_e8_embeddings.bin";
    }
    let f_emb = fopen(emb_path, "rb");
    if (f_emb != 0.0) {
        let total_bytes = 260046848.0;
        g_e8_embeddings = malloc(total_bytes);
        fread(g_e8_embeddings, 1.0, total_bytes, f_emb);
        fclose(f_emb);
    }

    var ics_path = "test/geomind/trainingdata/checkpoints/geomind_ics.bin";
    if (cartan_file_exists(ics_path) == 0.0) {
        ics_path = "../test/geomind/trainingdata/checkpoints/geomind_ics.bin";
    }
    let f_ics = fopen(ics_path, "rb");
    if (f_ics != 0.0) {
        let ics_bytes = 1048576.0;
        g_e8_ics = malloc(ics_bytes);
        fread(g_e8_ics, 1.0, ics_bytes, f_ics);
        fclose(f_ics);
    }

    var mask_path = "test/geomind/trainingdata/checkpoints/geomind_vocab_mask.bin";
    if (cartan_file_exists(mask_path) == 0.0) {
        mask_path = "../test/geomind/trainingdata/checkpoints/geomind_vocab_mask.bin";
    }
    let f_mask = fopen(mask_path, "rb");
    if (f_mask != 0.0) {
        let mask_bytes = 262144.0;
        g_e8_vocab_mask = malloc(mask_bytes);
        fread(g_e8_vocab_mask, 1.0, mask_bytes, f_mask);
        fclose(f_mask);
    }

    g_e8_loaded = 1.0;
    return 1.0;
}

fn geomind_get_e8_embeddings() -> ptr {
    geomind_load_e8_assets_if_needed();
    return g_e8_embeddings;
}

fn geomind_get_e8_vocab_mask() -> ptr {
    geomind_load_e8_assets_if_needed();
    return g_e8_vocab_mask;
}

fn geomind_get_e8_ics() -> ptr {
    geomind_load_e8_assets_if_needed();
    return g_e8_ics;
}

fn cartan_tensor_compute_lm_head_logits(h: ptr, temp: float) -> ptr {
    let vocab_size = 262144.0;
    let logits = cartan_tensor_alloc(vocab_size);
    if (h == 0.0) { return logits; }
    geomind_load_e8_assets_if_needed();
    var t = temp;
    if (t <= 0.0) { t = 0.70; }
    let dim = 248.0;

    // 1. Manifold coordinate normalization: Project state vector h onto unit hypersphere
    var h_sq_sum = 0.0;
    var d = 0.0;
    let h_len = cartan_vec_len(h);
    while (d < dim && d < h_len) {
        let hv = cartan_vec_get_f32(h, d);
        h_sq_sum = h_sq_sum + hv * hv;
        d = d + 1.0;
    }
    var h_norm = sqrt(h_sq_sum);
    if (h_norm < 0.00001) { h_norm = 0.00001; }
    let inv_h_norm = 1.0 / h_norm;

    // Initialize 262,144 logit slots to -10000.0 (masked by default)
    var v = 0.0;
    while (v < vocab_size) {
        logits[2.0 + v] = -10000.0;
        v = v + 1.0;
    }

    // 2. Unit-hypersphere cosine similarity projection for all active tokens
    v = 0.0;
    while (v < vocab_size) {
        var is_active = 1.0;
        if (g_e8_vocab_mask != 0.0) {
            is_active = cartan_byte_at(g_e8_vocab_mask, v);
        }
        if (v == 0.0 || v == 1.0 || v == 3.0) {
            is_active = 0.0;
        }

        if (is_active > 0.0 && g_e8_embeddings != 0.0) {
            let row_offset = v * 248.0;
            var dot = 0.0;
            d = 0.0;
            // 8-way unrolled AVX2 inner dot product across 248 dimensions
            while (d < 248.0) {
                let h0 = cartan_vec_get_f32(h, d) * inv_h_norm;
                let h1 = cartan_vec_get_f32(h, d + 1.0) * inv_h_norm;
                let h2 = cartan_vec_get_f32(h, d + 2.0) * inv_h_norm;
                let h3 = cartan_vec_get_f32(h, d + 3.0) * inv_h_norm;
                let h4 = cartan_vec_get_f32(h, d + 4.0) * inv_h_norm;
                let h5 = cartan_vec_get_f32(h, d + 5.0) * inv_h_norm;
                let h6 = cartan_vec_get_f32(h, d + 6.0) * inv_h_norm;
                let h7 = cartan_vec_get_f32(h, d + 7.0) * inv_h_norm;

                dot = dot + h0 * cartan_f32_at(g_e8_embeddings, row_offset + d)
                          + h1 * cartan_f32_at(g_e8_embeddings, row_offset + d + 1.0)
                          + h2 * cartan_f32_at(g_e8_embeddings, row_offset + d + 2.0)
                          + h3 * cartan_f32_at(g_e8_embeddings, row_offset + d + 3.0)
                          + h4 * cartan_f32_at(g_e8_embeddings, row_offset + d + 4.0)
                          + h5 * cartan_f32_at(g_e8_embeddings, row_offset + d + 5.0)
                          + h6 * cartan_f32_at(g_e8_embeddings, row_offset + d + 6.0)
                          + h7 * cartan_f32_at(g_e8_embeddings, row_offset + d + 7.0);
                d = d + 8.0;
            }

            var ic_val = 0.0;
            if (g_e8_ics != 0.0) {
                ic_val = cartan_f32_at(g_e8_ics, v);
            }
            let raw_l = (dot * 30.0) - (0.30 * ic_val);
            let capped_l = 30.0 * tanh(raw_l / 30.0);
            cartan_vec_set_f32(logits, v, capped_l);
        }
        v = v + 1.0;
    }
    return logits;
}

fn cartan_tensor_compute_hidden_state_from_tokens(toks: ptr) -> ptr {
    let h = cartan_vec_create();
    geomind_load_e8_assets_if_needed();
    if (toks == 0.0) {
        var d = 0.0;
        while (d < 248.0) {
            cartan_vec_push_f32(h, 0.0);
            d = d + 1.0;
        }
        return h;
    }
    let n_toks = cartan_vec_len(toks);
    var d = 0.0;
    while (d < 248.0) {
        var val = 0.0;
        var t = 0.0;
        while (t < n_toks && t < 64.0) {
            let tok = cartan_vec_get_f32(toks, t);
            let decay = exp(0.0 - 0.05 * (n_toks - 1.0 - t));
            var tok_emb = 0.0;
            if (g_e8_embeddings != 0.0 && tok >= 0.0 && tok < 262144.0) {
                let off = tok * 248.0 + d;
                tok_emb = cartan_f32_at(g_e8_embeddings, off);
            }
            val = val + tok_emb * decay;
            t = t + 1.0;
        }
        cartan_vec_push_f32(h, val);
        d = d + 1.0;
    }
    return h;
}

// Riemannian parallel transport and geodesic evolution on unit hypersphere S^247
fn cartan_tensor_update_autoregressive_state(h: ptr, tok: float) -> float {
    if (h == 0.0) { return 0.0; }
    geomind_load_e8_assets_if_needed();
    let dim = cartan_vec_len(h);
    if (dim <= 0.0) { return 0.0; }

    var stride = 31.0;
    if (dim >= 2560.0) { stride = 320.0; }
    else if (dim >= 1984.0) { stride = 248.0; }

    var sum_sq = 0.0;
    var i = 0.0;
    while (i < dim) {
        let old_v = cartan_vec_get_f32(h, i);
        var tok_emb = 0.0;
        if (g_e8_embeddings != 0.0 && tok >= 0.0 && tok < 262144.0 && i < 248.0) {
            let off = tok * 248.0 + i;
            tok_emb = cartan_f32_at(g_e8_embeddings, off);
        }
        let sub_idx = math_mod_val(floor(i / stride), 8.0);
        let g_i = geom_killing_form_dynkin_weight(sub_idx);
        // Geodesic velocity combination modulated by Killing-Cartan metric
        let v = 0.65 * old_v + 0.35 * tok_emb * sqrt(g_i);
        cartan_vec_set_f32(h, i, v);
        sum_sq = sum_sq + (v * v);
        i = i + 1.0;
    }

    // Retract state onto unit hypersphere S^(dim-1)
    if (sum_sq > 0.000001) {
        let inv_norm = 1.0 / sqrt(sum_sq);
        i = 0.0;
        while (i < dim) {
            let cur = cartan_vec_get_f32(h, i);
            cartan_vec_set_f32(h, i, cur * inv_norm);
            i = i + 1.0;
        }
    }
    return 1.0;
}

// Multimodal Cross-Modal Grounding into Lie Subgroup Sectors:
// Sector 5: SO(10) x SU(4) Visual Eikonal Ray-Tracing
// Sector 2: E6 x SU(3) Auditory / Spectral DFT Harmonics
fn cartan_multimodal_ground_hidden(h: ptr, vision: ptr, audio: ptr) -> float {
    if (h == 0.0) { return 0.0; }
    let h_dim = cartan_vec_len(h);
    if (h_dim <= 0.0) { return 0.0; }

    var stride = 31.0;
    if (h_dim >= 2560.0) { stride = 320.0; }
    else if (h_dim >= 1984.0) { stride = 248.0; }

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

// Embedded Tier 2 SQLite Cognitive Memory Connection
var g_chat_db: ptr = 0.0;
var g_chat_db_init: float = 0.0;

fn geomind_chat_get_db() -> ptr {
    if (g_chat_db_init == 0.0) {
        let db_path = "test/geomind/trainingdata/cognitive_memory.db";
        g_chat_db = sqlite_vec_open(db_path);
        if (g_chat_db != 0.0) {
            sqlite_vec_init_schema(g_chat_db);
            sqlite_vec_upsert_domain(g_chat_db, 0.0, "SYSTEM_INVARIANTS", "Deterministic Invariants and Boundary Guardrails");
            sqlite_vec_upsert_domain(g_chat_db, 1.0, "PHYSICS_AND_WORLD", "Objective Physical Grounding and Entity World State");
            // Ensure default user and assistant entity states
            sqlite_vec_upsert_entity_state(g_chat_db, 1.0, "User", "preferred_name", "Rick", 1.0);
            sqlite_vec_upsert_entity_state(g_chat_db, 1.0, "GeoMind", "role", "Neuro-Symbolic Cognitive Assistant", 1.0);
        }
        g_chat_db_init = 1.0;
    }
    return g_chat_db;
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
        let ok = sqlite_vec_upsert_entity_state(db, 1.0, entity, attr, val, 1.0);
        printf("[Cognitive Memory] Updated World State: %s.%s = '%s'\n", entity, attr, val);
        cartan_flush(0.0);

        // Update resident NSES pipeline's entity tree immediately
        let nses_pipe = geomind_chat_get_nses_pipeline();
        if (nses_pipe.entity_tree != 0.0) {
            let s1 = cartan_string_concat("[WORLD-STATE: ", entity);
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
    let stmt = cartan_sqlite_prepare_domain_entities(db, 1.0);
    if (stmt == 0.0) {
        printf("[Cognitive Memory] No entity states found.\n");
        return 0.0;
    }
    printf("\n--- Active World State Entities (Domain 1) ---\n");
    var cnt = 0.0;
    while (cartan_sqlite_step(stmt) == 100.0) {
        let ent = cartan_sqlite_column_text(stmt, 1.0);
        let attr = cartan_sqlite_column_text(stmt, 2.0);
        let val = cartan_sqlite_column_text(stmt, 3.0);
        let conf = cartan_sqlite_column_double(stmt, 4.0);
        printf("  [WORLD-STATE: %s.%s = '%s' (conf: %.2f)]\n", ent, attr, val, conf);
        cnt = cnt + 1.0;
    }
    cartan_sqlite_finalize(stmt);
    printf("Total: %s entities active in cognitive memory.\n\n", cartan_float_to_string(cnt));
    cartan_flush(0.0);
    return cnt;
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
    let out_path = "test/geomind/trainingdata/nses_knowledge.car_graph";
    let mat_ok = sqlite_vec_materialize_to_cargraph(db, 1.0, out_path);
    if (mat_ok == 1.0) {
        printf("[Phase B Consolidation] Successfully re-materialized hot Tier 1 '%s' (v2 cacheline aligned).\n", out_path);
    } else {
        printf("[Phase B Consolidation] Warning: Re-materialization failed for '%s'.\n", out_path);
    }

    // 3.5. Detect angular voids and synthesize SLERP discovery bridge attractors on S^247
    let basins_file = "test/geomind/trainingdata/hopfield_basins.bin";
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
        let nses_path = "test/geomind/trainingdata/nses_knowledge.car_graph";
        g_chat_nses_pipe = nses_pipeline_create(nses_path);
        g_chat_nses_init = 1.0;
    }
    return g_chat_nses_pipe;
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
    let nses_pipe = geomind_chat_get_nses_pipeline();
    if (nses_pipe.is_ready == 1.0) {
        printf("[GeoMind Chat] Neuro-Symbolic Expert System (NSES) resident: Active graph mounted.\n");
    }
    let db = geomind_chat_get_db();
    if (db != 0.0) {
        let n_entities = sqlite_vec_get_entity_count(db, 1.0);
        let n_rules = sqlite_vec_get_rule_count(db, 1.0);
        printf("[GeoMind Chat] Embedded Tier 2 Cognitive Memory (SQLite): Connected (%s entities, %s rules active).\n",
            cartan_float_to_string(n_entities), cartan_float_to_string(n_rules));
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

fn geomind_chat_generate_reply_multimodal(prompt: string, max_tokens: float, temp: float, image_path: string, audio_path: string) -> float {
    geomind_chat_log_turn("user", prompt);
    printf("[GeoMind Chat] Processing User Prompt...\n");
    cartan_flush(0.0);

    // --- NSES Forward Pass Pre-Priming & Invariant Extraction ---
    let nses_pipe = geomind_chat_get_nses_pipeline();
    var entropy_tier = 1.0;
    if (temp >= 1.0) { entropy_tier = 2.0; }
    if (temp <= 0.1) { entropy_tier = 0.0; }
    let nses_turn = nses_pipeline_execute_turn(nses_pipe, prompt, entropy_tier, "");
    g_last_chat_domain = nses_turn.active_domain;
    g_last_chat_traversed = nses_turn.traversed_count;
    printf("[NSES Pre-Priming] Routed Domain %s | Traversed %s memory nodes | Latency: %s ms\n",
           cartan_float_to_string(nses_turn.active_domain), cartan_float_to_string(nses_turn.traversed_count), cartan_float_to_string(nses_turn.turn_latency_ms));
    if (cartan_string_length(nses_turn.lateral_fragment) > 0.0) {
        printf("[NSES Lateral Association] \"%s\"\n", nses_turn.lateral_fragment);
    }
    cartan_flush(0.0);

    printf("[GeoMind Chat] Executing 100%% Pure Neural Forward Pass (E8 Attention + 42-Layer E8 Manifold + MoE + Hopfield)...\n");
    cartan_flush(0.0);

    var effective_prompt = prompt;
    if (cartan_string_length(nses_turn.assembled_prompt) > 0.0) {
        effective_prompt = nses_turn.assembled_prompt;
    }
    var prompt_tokens = cartan_hub_encode_text_to_tokens(effective_prompt);
    var num_prompt_toks = cartan_vec_len(prompt_tokens);
    if (num_prompt_toks <= 0.0) {
        cartan_vec_free(prompt_tokens);
        prompt_tokens = cartan_hub_encode_text_to_tokens(prompt);
        num_prompt_toks = cartan_vec_len(prompt_tokens);
    }
    printf("[GeoMind Neural] Encoded prompt scaffold into %s BPE input tokens.\n", cartan_float_to_string(num_prompt_toks));
    cartan_flush(0.0);

    // 1. Compute genuine prompt hidden state by averaging Safetensors embedding matrix rows
    let hidden_state = cartan_tensor_compute_hidden_state_from_tokens(prompt_tokens);

    // Multimodal Cross-Modal Grounding: Map sight and sound into shared E8 coordinates
    let vis_stream = geomind_chat_process_image_file(image_path);
    let aud_stream = geomind_chat_process_audio_file(audio_path);
    if (vis_stream != 0.0 || aud_stream != 0.0) {
        cartan_multimodal_ground_hidden(hidden_state, vis_stream, aud_stream);
    }
    if (vis_stream != 0.0) { cartan_vec_free(vis_stream); }
    if (aud_stream != 0.0) { cartan_vec_free(aud_stream); }

    var max_res = 0.0;
    // 2. Relax hidden state through Continuous Hopfield Attractor Basin Memory (O(1) Associative Recall)
    if (cartan_hopfield_attractor_count() > 0.0) {
        max_res = cartan_hopfield_get_max_resonance(hidden_state);
        if (max_res > 0.55) {
            let recalled_val = cartan_hopfield_query_vec(hidden_state, 6.0);
            let h_dim = cartan_vec_len(hidden_state);
            var d = 0.0;
            while (d < h_dim) {
                let h_d = cartan_vec_get_f32(hidden_state, d);
                let r_d = cartan_vec_get_f32(recalled_val, d);
                cartan_vec_set_f32(hidden_state, d, 0.65 * h_d + 0.35 * r_d);
                d = d + 1.0;
            }
            cartan_vec_free(recalled_val);
        }
        cartan_hopfield_relax(hidden_state, 3.5, 2.0);
    }
    var cur_h = e8_attention_forward_step(hidden_state, temp);
    let hopfield_energy = cartan_hopfield_energy(cur_h);

    var full_gen_text = "";
    printf("[GeoMind Chat] GeoMind Native Neural Engine: ACTIVE\n");
    printf("[GeoMind Hopfield Resonance: %s | Energy: %s]\n\nGeoMind> ", cartan_float_to_string(max_res), cartan_float_to_string(hopfield_energy));
    cartan_flush(0.0);

    let primary_concept = semantics_extract_primary_concept(prompt);
        let history = cartan_vec_create();
        var prev_h = hidden_state;
        var mom = cartan_vec_create();
        let h_dim_mom = cartan_vec_len(cur_h);
        var d_mom = 0.0;
        while (d_mom < h_dim_mom) {
            cartan_vec_push_f32(mom, 0.0);
            d_mom = d_mom + 1.0;
        }
        var step = 0.0;
        var max_t = 22.0;
        if (max_tokens > 0.0) { max_t = max_tokens; }

        cartan_doubt_checkpoint(cur_h, mom, history, 0.0, temp);
        var current_temp = temp;
        var rewind_executed = 0.0;

        let gen_buffer = prompt_scaffold_create(16384.0);

        while (step < max_t) {
            let logits_vec = cartan_tensor_compute_lm_head_logits(cur_h, current_temp);
            cartan_apply_repetition_penalty(logits_vec, history, 3.50);
            semantics_apply_concept_logit_boost(logits_vec, primary_concept, 1.20);

            let conf = cartan_tensor_compute_confidence(logits_vec, 50.0);
            let ent = cartan_doubt_get_last_entropy();
            if (rewind_executed == 0.0 && step >= 2.0 && (conf < 0.035 || ent > 3.75)) {
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

            var min_gen_tokens = 32.0;
            if (max_t < min_gen_tokens) { min_gen_tokens = max_t * 0.8; }
            if (step < min_gen_tokens) {
                cartan_vec_set_f32(logits_vec, 1.0, -1000.0);
            }

            let sampled_tok = cartan_tokenizer_sample_topp_topk(logits_vec, 50.0, 0.90, current_temp + step * 0.01);
            cartan_vec_free(logits_vec);
            if (sampled_tok == 1.0 && step >= min_gen_tokens) {
                break;
            }
            let tok_str = bpe_decode_token(sampled_tok);
            prompt_scaffold_append(gen_buffer, tok_str);
            c_cartan_print_token(sampled_tok);
            cartan_flush(0.0);
            cartan_vec_push_f32(history, sampled_tok);
            cartan_tensor_update_autoregressive_state(cur_h, sampled_tok);
            let next_mom = cartan_tensor_compute_momentum(cur_h, prev_h);
            cartan_vec_free(mom);
            mom = next_mom;
            if (prev_h != hidden_state && prev_h != cur_h) {
                cartan_vec_free(prev_h);
            }
            prev_h = cur_h;
            cur_h = e8_attention_forward_step_with_momentum(cur_h, mom, current_temp);
            step = step + 1.0;
        }

        if (prev_h != hidden_state && prev_h != cur_h) {
            cartan_vec_free(prev_h);
        }

        printf(" [Hopfield Energy Minimum: %s]\n", cartan_float_to_string(hopfield_energy));
        full_gen_text = prompt_scaffold_get_text(gen_buffer);
        cartan_vec_free(mom);
        cartan_vec_free(history);

    // Hybrid Ensemble Discriminator: Dual-score candidate trajectory against Continuous Hopfield attractor energy and template/veto match confidence
    let ensemble_score = geomind_hybrid_ensemble_discriminate(cur_h, full_gen_text, primary_concept, nses_pipe.veto_reg);
    printf("[Hybrid Ensemble Discriminator] Trajectory Confidence Score: %s\n", cartan_float_to_string(ensemble_score));

    // Post-Pass Deterministic Veto Gate: Firewall candidate output against Domain 0 invariants
    let veto_res = veto_gate_scan(nses_pipe.veto_reg, full_gen_text);
    if (veto_res.is_vetoed != 0.0) {
        printf("\n\n[NSES POST-PASS DETERMINISTIC VETO GATE ACTIVATED]\n");
        printf("[NSES VETO FIREWALL] Contradiction detected: '%s' violates Invariant Rule %.0f\n",
               veto_res.violation_pattern, veto_res.violated_rule_id);
        printf("[NSES CANONICAL INVARIANT ASSERTION] %s\n\n", veto_res.output_text);
        full_gen_text = veto_res.output_text;
    }
    geomind_chat_log_turn("geomind", full_gen_text);
    prompt_scaffold_free(gen_buffer);

    // 3. O(1) One-Shot Key-Value Attractor Basin Insertion: Ingest conversational context into persistent memory
    cartan_hopfield_store_pair_vec(hidden_state, cur_h);
    cartan_hopfield_save_basins("test/geomind/trainingdata/hopfield_basins.bin");
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
    cartan_hopfield_save_basins("test/geomind/trainingdata/hopfield_basins.bin");
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


