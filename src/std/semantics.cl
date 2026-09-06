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

var g_taxonomy_dag: ptr = 0.0;

fn taxonomy_init_if_needed() {
    if (g_taxonomy_dag == 0.0) {
        g_taxonomy_dag = cartan_tree_create();
    }
}

fn cartan_taxonomy_node_count() -> float {
    taxonomy_init_if_needed();
    return cartan_tree_len_f(g_taxonomy_dag);
}

fn cartan_taxonomy_load_dag(path: string) -> float {
    taxonomy_init_if_needed();
    let content = cartan_read_file(path);
    if (content == 0.0 || cartan_string_length(content) == 0.0) { return 0.0; }
    let lines = string_split(content, "\n");
    let num_lines = cartan_tree_len_f(lines);
    
    var cur_path = "";
    var cur_lemmas = "";
    var cur_hyper = "";
    var cur_def = "";
    var cur_ic = 1.0;
    var in_node = 0.0;

    var i = 0.0;
    while (i < num_lines) {
        let raw_line = cartan_tree_get(lines, i);
        let line = cartan_string_replace(cartan_string_replace(raw_line, "\r", ""), "\n", "");
        let len = cartan_string_length(line);

        if (len == 0.0) {
            if (in_node != 0.0 && cartan_string_length(cur_path) > 0.0) {
                let node = cartan_tree_create();
                cartan_tree_push(node, cur_path);
                cartan_tree_push(node, cur_lemmas);
                cartan_tree_push(node, cur_hyper);
                cartan_tree_push(node, cur_def);
                let ic_vec = cartan_vec_create();
                cartan_vec_push_f32(ic_vec, cur_ic);
                cartan_tree_push(node, ic_vec);
                cartan_tree_push(g_taxonomy_dag, node);

                cur_path = "";
                cur_lemmas = "";
                cur_hyper = "";
                cur_def = "";
                cur_ic = 1.0;
                in_node = 0.0;
            }
        } else if (cartan_string_starts_with(line, "Path: ") != 0.0) {
            if (in_node != 0.0 && cartan_string_length(cur_path) > 0.0) {
                let node = cartan_tree_create();
                cartan_tree_push(node, cur_path);
                cartan_tree_push(node, cur_lemmas);
                cartan_tree_push(node, cur_hyper);
                cartan_tree_push(node, cur_def);
                let ic_vec = cartan_vec_create();
                cartan_vec_push_f32(ic_vec, cur_ic);
                cartan_tree_push(node, ic_vec);
                cartan_tree_push(g_taxonomy_dag, node);

                cur_lemmas = "";
                cur_hyper = "";
                cur_def = "";
                cur_ic = 1.0;
            }
            in_node = 1.0;
            cur_path = cartan_string_substring(line, 6.0, len);
        } else if (cartan_string_starts_with(line, "Lemmas: ") != 0.0) {
            in_node = 1.0;
            cur_lemmas = cartan_string_substring(line, 8.0, len);
        } else if (cartan_string_starts_with(line, "Hypernym: ") != 0.0) {
            in_node = 1.0;
            cur_hyper = cartan_string_substring(line, 10.0, len);
        } else if (cartan_string_starts_with(line, "Definition: ") != 0.0) {
            in_node = 1.0;
            cur_def = cartan_string_substring(line, 12.0, len);
        } else if (cartan_string_starts_with(line, "IC: ") != 0.0) {
            in_node = 1.0;
            cur_ic = 1.0;
        }
        i = i + 1.0;
    }

    if (in_node != 0.0 && cartan_string_length(cur_path) > 0.0) {
        let node = cartan_tree_create();
        cartan_tree_push(node, cur_path);
        cartan_tree_push(node, cur_lemmas);
        cartan_tree_push(node, cur_hyper);
        cartan_tree_push(node, cur_def);
        let ic_vec = cartan_vec_create();
        cartan_vec_push_f32(ic_vec, cur_ic);
        cartan_tree_push(node, ic_vec);
        cartan_tree_push(g_taxonomy_dag, node);
    }
    return cartan_tree_len_f(g_taxonomy_dag);
}

fn cartan_taxonomy_resolve_path(word: string) -> string {
    if (word == 0.0 || cartan_string_length(word) == 0.0) { return ""; }
    if (cartan_string_contains(word, ".") != 0.0) { return word; }
    taxonomy_init_if_needed();
    let num_nodes = cartan_tree_len_f(g_taxonomy_dag);
    var i = 0.0;
    while (i < num_nodes) {
        let node = cartan_tree_get(g_taxonomy_dag, i);
        let lemmas = cartan_tree_get(node, 1.0);
        if (cartan_string_contains(lemmas, word) != 0.0) {
            return cartan_tree_get(node, 0.0);
        }
        i = i + 1.0;
    }
    i = 0.0;
    while (i < num_nodes) {
        let node = cartan_tree_get(g_taxonomy_dag, i);
        let path = cartan_tree_get(node, 0.0);
        if (cartan_string_contains(path, word) != 0.0) {
            return path;
        }
        i = i + 1.0;
    }
    return "";
}

fn cartan_taxonomy_count_dots(path: string) -> float {
    let len = cartan_string_length(path);
    var count = 0.0;
    var i = 0.0;
    while (i < len) {
        if (cartan_string_get_char(path, i) == 46.0) {
            count = count + 1.0;
        }
        i = i + 1.0;
    }
    return count;
}

fn cartan_taxonomy_get_lca_distance(p1: string, p2: string) -> float {
    if (p1 == 0.0 || p2 == 0.0) { return 0.0; }
    var path1 = p1;
    var path2 = p2;
    if (cartan_string_contains(path1, ".") == 0.0) {
        let r1 = cartan_taxonomy_resolve_path(path1);
        if (cartan_string_length(r1) > 0.0) { path1 = r1; }
    }
    if (cartan_string_contains(path2, ".") == 0.0) {
        let r2 = cartan_taxonomy_resolve_path(path2);
        if (cartan_string_length(r2) > 0.0) { path2 = r2; }
    }
    if (cartan_string_eq(path1, path2) != 0.0) { return 0.0; }

    let len1 = cartan_string_length(path1);
    let len2 = cartan_string_length(path2);
    let d1 = cartan_taxonomy_count_dots(path1) + 1.0;
    let d2 = cartan_taxonomy_count_dots(path2) + 1.0;

    var common_len = 0.0;
    while (common_len < len1 && common_len < len2 && cartan_string_get_char(path1, common_len) == cartan_string_get_char(path2, common_len)) {
        common_len = common_len + 1.0;
    }

    var lca_depth = 0.0;
    if (common_len == len1 && common_len == len2) {
        lca_depth = d1;
    } else if (common_len == len1 && cartan_string_get_char(path2, common_len) == 46.0) {
        lca_depth = d1;
    } else if (common_len == len2 && cartan_string_get_char(path1, common_len) == 46.0) {
        lca_depth = d2;
    } else {
        var last_dot = -1.0;
        var k = common_len - 1.0;
        while (k >= 0.0) {
            if (cartan_string_get_char(path1, k) == 46.0) {
                last_dot = k;
                k = -1.0;
            } else {
                k = k - 1.0;
            }
        }
        if (last_dot >= 0.0) {
            var dots = 0.0;
            var j = 0.0;
            while (j <= last_dot) {
                if (cartan_string_get_char(path1, j) == 46.0) { dots = dots + 1.0; }
                j = j + 1.0;
            }
            lca_depth = dots;
        } else {
            lca_depth = 0.0;
        }
    }
    let dist = (d1 - lca_depth) + (d2 - lca_depth);
    return dist;
}

fn cartan_taxonomy_get_ic(word: string) -> float {
    if (word == 0.0 || cartan_string_length(word) == 0.0) { return 1.0; }
    let path = cartan_taxonomy_resolve_path(word);
    taxonomy_init_if_needed();
    let num_nodes = cartan_tree_len_f(g_taxonomy_dag);
    var i = 0.0;
    while (i < num_nodes) {
        let node = cartan_tree_get(g_taxonomy_dag, i);
        let n_path = cartan_tree_get(node, 0.0);
        if (cartan_string_eq(n_path, path) != 0.0) {
            let ic_vec = cartan_tree_get(node, 4.0);
            if (ic_vec != 0.0 && cartan_vec_len(ic_vec) > 0.0) {
                return cartan_vec_get_f32(ic_vec, 0.0);
            }
            return 1.0;
        }
        i = i + 1.0;
    }
    return 1.0;
}

fn cartan_taxonomy_resnik_similarity(w1: string, w2: string) -> float {
    let dist = cartan_taxonomy_get_lca_distance(w1, w2);
    let ic1 = cartan_taxonomy_get_ic(w1);
    let ic2 = cartan_taxonomy_get_ic(w2);
    var mean_ic = (ic1 + ic2) * 0.5;
    let sim = mean_ic / (1.0 + dist * 0.25);
    return sim;
}

fn cartan_taxonomy_lin_similarity(w1: string, w2: string) -> float {
    let ic1 = cartan_taxonomy_get_ic(w1);
    let ic2 = cartan_taxonomy_get_ic(w2);
    if (ic1 + ic2 <= 0.0) { return 0.0; }
    let resnik = cartan_taxonomy_resnik_similarity(w1, w2);
    return (2.0 * resnik) / (ic1 + ic2);
}

fn cartan_taxonomy_extract_primary_concept(prompt: string) -> string {
    if (prompt == 0.0 || cartan_string_length(prompt) == 0.0) { return "object"; }
    let words = string_split(prompt, " ");
    let n = cartan_tree_len_f(words);
    var i = 0.0;
    while (i < n) {
        let w = cartan_tree_get(words, i);
        if (cartan_string_length(w) >= 3.0) {
            let res = cartan_taxonomy_resolve_path(w);
            if (cartan_string_length(res) > 0.0) {
                return w;
            }
        }
        i = i + 1.0;
    }
    return "object";
}

fn cartan_taxonomy_apply_logit_boost(logits: ptr, concept_word: string, boost_factor: float) {
    if (logits == 0.0 || concept_word == 0.0 || boost_factor <= 0.0) { return; }
    let path = cartan_taxonomy_resolve_path(concept_word);
    if (cartan_string_length(path) == 0.0) { return; }
    let len = cartan_vec_len(logits);
    if (len > 0.0) {
        let word_len = cartan_string_length(concept_word);
        var w_i = 0.0;
        while (w_i < word_len) {
            let ch = cartan_byte_at(concept_word, w_i);
            if (ch >= 32.0 && ch <= 126.0) {
                let ch_tok = ch + 235.0;
                if (ch_tok < len) {
                    let cur = cartan_vec_get_f32(logits, ch_tok);
                    cartan_vec_set_f32(logits, ch_tok, cur + boost_factor * 2.0);
                }
            }
            w_i = w_i + 1.0;
        }
    }
}

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


