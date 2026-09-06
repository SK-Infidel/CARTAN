// CARTAN Standard Library: Production WordNet/SlangNet Semantic Taxonomy & Hierarchy Engine
// Layer 1 Module: std::semantics

include "src/std/string.cl";
include "src/std/math.cl";
include "src/std/io.cl";
include "src/std/fs.cl";


var g_taxonomy_loaded = 0.0;
var g_taxonomy_node_count = 0.0;
var g_taxonomy_synset_count = 0.0;
var g_taxonomy_lemma_count = 0.0;

fn semantics_synset_to_hash(path: string) -> float {
    return cartan_hash_string(path);
}

fn semantics_dot_path_depth(path: string) -> float {
    let len = cartan_string_length(path);
    if (len == 0.0) { return 0.0; }
    var depth = 1.0;
    var i = 0.0;
    while (i < len) {
        let ch = cartan_string_get_char(path, i);
        if (ch == 46.0) { // '.' ASCII code
            depth = depth + 1.0;
        }
        i = i + 1.0;
    }
    return depth;
}

fn semantics_lca_tree_distance(path1: string, path2: string) -> float {
    return cartan_taxonomy_get_lca_distance(path1, path2);
}

fn semantics_compute_shannon_entropy(s: string) -> float {
    let len = cartan_string_length(s);
    if (len <= 1.0) { return 0.0; }
    let freq = malloc(256.0 * 8.0);
    var i = 0.0;
    while (i < 256.0) {
        freq[i] = 0.0;
        i = i + 1.0;
    }
    i = 0.0;
    while (i < len) {
        let ch = cartan_string_get_char(s, i);
        if (ch >= 0.0 && ch < 256.0) {
            freq[ch] = freq[ch] + 1.0;
        }
        i = i + 1.0;
    }
    var entropy = 0.0;
    i = 0.0;
    while (i < 256.0) {
        let c = freq[i];
        if (c > 0.0) {
            let p = c / len;
            entropy = entropy - p * math_log2(p);
        }
        i = i + 1.0;
    }
    free(freq);
    return entropy;
}

extern fn cartan_taxonomy_load_dag(path: string) -> float;
extern fn cartan_taxonomy_resolve_path(word: string) -> string;
extern fn cartan_taxonomy_get_lca_distance(p1: string, p2: string) -> float;
extern fn cartan_taxonomy_get_ic(word: string) -> float;
extern fn cartan_taxonomy_resnik_similarity(w1: string, w2: string) -> float;
extern fn cartan_taxonomy_lin_similarity(w1: string, w2: string) -> float;
extern fn cartan_taxonomy_apply_logit_boost(logits: ptr, concept_word: string, boost: float);
extern fn cartan_taxonomy_node_count() -> float;
extern fn cartan_taxonomy_extract_primary_concept(prompt: string) -> string;

fn semantics_resolve_concept_path(word: string) -> string {
    return cartan_taxonomy_resolve_path(word);
}

fn semantics_extract_primary_concept(prompt: string) -> string {
    return cartan_taxonomy_extract_primary_concept(prompt);
}

fn semantics_apply_concept_logit_boost(logits: ptr, concept_word: string, boost_factor: float) {
    cartan_taxonomy_apply_logit_boost(logits, concept_word, boost_factor);
}

fn semantics_get_concept_ic(concept: string) -> float {
    return cartan_taxonomy_get_ic(concept);
}

fn semantics_load_taxonomy(filepath: string) -> float {
    let count = cartan_taxonomy_load_dag(filepath);
    if (count > 0.0) {
        g_taxonomy_loaded = 1.0;
        g_taxonomy_node_count = count;
        printf("[std::semantics] Ingested WordNet & SlangNet Taxonomy DAG: %s synset nodes indexed.\n", cartan_float_to_string(count));
        return 1.0;
    }
    printf("[std::semantics] Taxonomy file %s not found or empty.\n", filepath);
    return 0.0;
}

fn semantics_resnik_similarity(c1: string, c2: string) -> float {
    return cartan_taxonomy_resnik_similarity(c1, c2);
}

fn semantics_lin_similarity(c1: string, c2: string) -> float {
    return cartan_taxonomy_lin_similarity(c1, c2);
}

fn semantics_apply_lca_boost(logits: ptr, history_token_id: float, vocab_size: float, boost_factor: float) {
    if (logits == 0.0 || boost_factor <= 0.0 || vocab_size <= 0.0) { return; }
    var i = 0.0;
    while (i < vocab_size) {
        if (i == history_token_id) {
            // Apply semantic coherence boost along geodesic
            logits[i] = logits[i] + boost_factor * 0.5;
        }
        i = i + 1.0;
    }
}


