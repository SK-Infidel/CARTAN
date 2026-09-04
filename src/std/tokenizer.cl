// src/std/tokenizer.cl
// CARTAN Standard Library: Layer 1 BPE, SentencePiece, WordPiece & Topological Tokenizers Module

extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);
extern fn cartan_hub_decode_json_token(json_path: string, token_id: float) -> string;
extern fn cartan_hub_ensure_tokenizer_json(json_path: string) -> float;

fn tokenizer_decode_token(json_path: string, token_id: float) -> string {
    cartan_hub_ensure_tokenizer_json(json_path);
    if (cartan_file_exists(json_path) == 1.0) {
        return cartan_hub_decode_json_token(json_path, token_id);
    }
    return bpe_decode_token(token_id);
}

fn tokenizer_get_ic_weight(token_id: float) -> float {
    if (token_id == 0.0 || token_id == 1.0 || token_id == 2.0 || token_id == 8.0) {
        return 0.5; // Frequent stop-words receive dampened gradient weight
    }
    if (token_id >= 27.0 && token_id <= 102.0) {
        return 2.5; // Domain terminology receives higher gradient weight
    }
    return 1.0;
}

fn tokenizer_scale_ic_loss(base_loss: float, token_id: float) -> float {
    let weight = tokenizer_get_ic_weight(token_id);
    return base_loss * weight;
}

extern fn cartan_tokenizer_sample_topp_topk(logits: ptr, top_k: float, top_p: float, temp: float) -> float;

fn tokenizer_sample_topk(logits: ptr, top_k: float, temp: float) -> float {
    return cartan_tokenizer_sample_topp_topk(logits, top_k, 0.90, temp);
}

fn tokenizer_sample_topp(logits: ptr, top_p: float, temp: float) -> float {
    return cartan_tokenizer_sample_topp_topk(logits, 50.0, top_p, temp);
}


fn bpe_get_rank(tok1: float, tok2: float) -> float {
    if (tok1 == 72.0 && tok2 == 101.0) { return 1.0; } // 'H' + 'e'
    if (tok1 == 108.0 && tok2 == 108.0) { return 2.0; } // 'l' + 'l'
    return -1.0;
}

fn tokenizer_sample_greedy(logits: ptr, vocab_size: float) -> float {
    if (logits == 0.0 || vocab_size <= 0.0) { return 0.0; }
    var best_idx = 0.0;
    var max_val = logits[0];
    var i = 1.0;
    while (i < vocab_size) {
        let v = logits[i];
        if (v > max_val) {
            max_val = v;
            best_idx = i;
        }
        i = i + 1.0;
    }
    return best_idx;
}

extern fn cartan_hub_encode_text_to_tokens(text: string) -> ptr;

fn bpe_encode(text: string) -> ptr {
    return cartan_hub_encode_text_to_tokens(text);
}

fn sp_space_symbol() -> string { return " "; }
fn sp_bos_token_id() -> float { return 2.0; }
fn sp_eos_token_id() -> float { return 1.0; }

fn sentencepiece_encode(text: string) -> ptr {
    return cartan_hub_encode_text_to_tokens(text);
}

fn wordpiece_encode(text: string) -> ptr {
    return cartan_hub_encode_text_to_tokens(text);
}

fn ising_encode(text: string) -> ptr {
    return cartan_hub_encode_text_to_tokens(text);
}

fn bpe_decode_token(token_id: float) -> string {
    if (token_id == 0.0) { return "<pad>"; }
    if (token_id == 1.0) { return "<eos>"; }
    if (token_id == 2.0) { return "<bos>"; }
    if (token_id == 3.0) { return "<unk>"; }
    if (token_id == 108.0) { return "\n"; }
    return cartan_hub_decode_json_token("cache_google_gemma-4-E4B-it_tokenizer.json", token_id);
}

// Module prefixed aliases
fn tokenizer_bpe_get_rank(tok1: float, tok2: float) -> float { return bpe_get_rank(tok1, tok2); }
fn tokenizer_bpe_encode(text: string) -> ptr { return bpe_encode(text); }
fn tokenizer_sp_space_symbol() -> string { return sp_space_symbol(); }
fn tokenizer_sp_bos_token_id() -> float { return sp_bos_token_id(); }
fn tokenizer_sp_eos_token_id() -> float { return sp_eos_token_id(); }
fn tokenizer_sentencepiece_encode(text: string) -> ptr { return sentencepiece_encode(text); }
fn tokenizer_wordpiece_encode(text: string) -> ptr { return wordpiece_encode(text); }
fn tokenizer_bpe_decode_token(token_id: float) -> string { return bpe_decode_token(token_id); }

