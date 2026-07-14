use serde::Deserialize;
use std::collections::HashMap;
use std::fs::File;
use std::io::Read;

#[derive(Debug, Deserialize)]
pub struct TokenizerModel {
    pub vocab: HashMap<String, u32>,
    pub merges: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct TokenizerJson {
    pub model: TokenizerModel,
}

#[derive(Debug)]
pub struct BPEData {
    pub vocab: HashMap<String, u32>,
    pub merges: HashMap<(String, String), u32>, // (pair_left, pair_right) -> rank
}

pub fn parse_tokenizer_json(path: &str) -> Result<BPEData, String> {
    let mut file = File::open(path).map_err(|e| format!("Failed to open tokenizer: {}", e))?;
    let mut contents = String::new();
    file.read_to_string(&mut contents).map_err(|e| format!("Failed to read tokenizer: {}", e))?;

    let parsed: TokenizerJson = serde_json::from_str(&contents).map_err(|e| format!("Failed to parse tokenizer JSON: {}", e))?;

    let mut merges = HashMap::new();
    for (rank, merge) in parsed.model.merges.into_iter().enumerate() {
        let parts: Vec<&str> = merge.split(' ').collect();
        if parts.len() == 2 {
            merges.insert((parts[0].to_string(), parts[1].to_string()), rank as u32);
        }
    }

    Ok(BPEData {
        vocab: parsed.model.vocab,
        merges,
    })
}
