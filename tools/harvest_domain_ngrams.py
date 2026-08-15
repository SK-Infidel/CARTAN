import collections
import re
import json
import os

# Load HF Token from ~/.env or ~/.cache/huggingface/token and call login()
token = None
env_file = os.path.expanduser("~/.env")
if os.path.exists(env_file):
    try:
        with open(env_file, "r", encoding="utf-8") as f:
            for l in f:
                if l.startswith("HF_TOKEN=") or l.startswith("HUGGING_FACE_HUB_TOKEN="):
                    val = l.split("=", 1)[1].strip()
                    if val:
                        token = val
                        break
    except Exception:
        pass

if not token:
    hf_token_file = os.path.expanduser("~/.cache/huggingface/token")
    if os.path.exists(hf_token_file):
        try:
            with open(hf_token_file, "r", encoding="utf-8") as f:
                token = f.read().strip()
        except Exception:
            pass

if token:
    os.environ["HF_TOKEN"] = token
    os.environ["HUGGING_FACE_HUB_TOKEN"] = token
    try:
        import huggingface_hub
        huggingface_hub.login(token=token, add_to_git_credential=False)
        print("[Harvester Auth] HuggingFace Hub session successfully authenticated.")
    except Exception as e:
        print(f"[Harvester Auth Warning] login failed: {e}")

from datasets import load_dataset

# Existing phrase blacklist to ensure zero overlap
EXISTING_PHRASES = {
    "i want to", "in other words", "by the way", "as a matter of fact",
    "at the end of the day", "believe it or not", "on the other hand", "no matter what"
}

def clean_and_tokenize(text):
    """Cleans text and converts it into lowercase words."""
    if not text:
        return []
    text = text.lower()
    words = re.findall(r'\b[a-z\-]+\b', text)
    return words

def filter_ngram(phrase, n_gram_size):
    """Filters out trivial stop-word N-grams while preserving key domain phrases."""
    words = phrase.split()
    if len(words) != n_gram_size:
        return False
    if phrase in EXISTING_PHRASES:
        return False
    
    # Reject non-English / foreign stop tokens
    foreign_tokens = {"en", "la", "el", "de", "los", "las", "un", "una", "que", "del", "se", "por", "con"}
    if any(w in foreign_tokens for w in words):
        return False
        
    # Reject phrases ending in dangling conjunctions/prepositions
    dangling_ends = {"and", "or", "no", "the", "a", "an", "of", "in", "to", "at", "by", "for", "with"}
    if words[-1] in dangling_ends:
        return False
    if words[0] in {"no", "symphony"}:
        return False

    stop_words = {"the", "of", "and", "a", "an", "in", "to", "is", "it", "that", "this", "for", "on", "with", "as", "at", "by", "from", "or", "be"}
    if all(w in stop_words for w in words):
        return False
    if any(len(w) == 1 and w not in {'a', 'i'} for w in words):
        return False
    return True

def extract_domain_phrases(dataset_name, config=None, text_field="text", sample_size=3000, n_gram_size=2):
    """Streams a dataset and calculates the most common sequential phrases (N-grams)."""
    print(f"[Harvester] Streaming {dataset_name} ({config or 'default'}) for {n_gram_size}-grams...")
    
    try:
        if config:
            dataset = load_dataset(dataset_name, config, split="train", streaming=True)
        else:
            dataset = load_dataset(dataset_name, split="train", streaming=True)
    except Exception as e:
        print(f"[Harvester Warning] Could not stream {dataset_name}: {e}")
        return collections.Counter()

    phrase_counter = collections.Counter()
    
    for i, example in enumerate(dataset):
        if i >= sample_size:
            break
            
        text_content = example.get(text_field, "")
        if not text_content and isinstance(example, dict):
            for k in ["abstract", "text", "dialog", "dialogue", "content"]:
                if k in example and example[k]:
                    text_content = example[k]
                    if isinstance(text_content, list):
                        text_content = " ".join(text_content)
                    break
        
        words = clean_and_tokenize(str(text_content))
        if len(words) < n_gram_size:
            continue
            
        ngrams = zip(*[words[j:] for j in range(n_gram_size)])
        for ngram in ngrams:
            phrase = " ".join(ngram)
            if filter_ngram(phrase, n_gram_size):
                phrase_counter[phrase] += 1
                
    return phrase_counter

def build_cloze_dataset():
    """Harvests thousands of N-grams across Conversational, Narrative, Structural, and Scientific domains."""
    domains = [
        # Conversational
        {"name": "OpenAssistant/oasst1", "config": None, "field": "text", "type": "conversational"},
        {"name": "eugenesiow/open_subtitles", "config": "en", "field": "text", "type": "conversational"},
        # Narrative & Prose
        {"name": "roneneldan/TinyStories", "config": None, "field": "text", "type": "narrative"},
        {"name": "deepmind/pg19", "config": None, "field": "text", "type": "narrative"},
        # Structural & Logic
        {"name": "Salesforce/wikitext", "config": "wikitext-103-raw-v1", "field": "text", "type": "structural"},
        # Science & Math
        {"name": "gfissore/arxiv-abstracts-2021", "config": None, "field": "abstract", "type": "scientific"},
        {"name": "EleutherAI/proof-pile-2", "config": "default", "field": "text", "type": "scientific"}
    ]
    
    all_harvested_phrases = []
    seen_phrases = set(EXISTING_PHRASES)
    
    for dom in domains:
        for n_size in [2, 3]: # Bigrams and Trigrams
            counter = extract_domain_phrases(
                dataset_name=dom["name"],
                config=dom["config"],
                text_field=dom["field"],
                sample_size=3000,
                n_gram_size=n_size
            )
            
            top_items = counter.most_common(1200)
            added_count = 0
            
            for phrase, freq in top_items:
                if phrase not in seen_phrases:
                    seen_phrases.add(phrase)
                    all_harvested_phrases.append({
                        "phrase": phrase,
                        "frequency": freq,
                        "domain": dom["type"],
                        "n_gram_size": n_size,
                        "cloze_prompt": f"Context phrase: [BLANK] -> {phrase}",
                        "target_phrase": phrase
                    })
                    added_count += 1
            print(f"[Harvester] Added {added_count} unique {n_size}-grams for dataset '{dom['name']}' ({dom['type']})")
                
    os.makedirs("scratch", exist_ok=True)
    out_file = "scratch/mined_expanded_corpus_cloze.jsonl"
    with open(out_file, "w", encoding="utf-8") as f:
        for item in all_harvested_phrases:
            f.write(json.dumps(item) + "\n")
            
    print(f"\n================================================================================")
    print(f"  MULTI-THOUSAND N-GRAM HARVEST COMPLETE")
    print(f"  Total Unique N-Grams Mined: {len(all_harvested_phrases)}")
    print(f"  Output File: {out_file}")
    print(f"================================================================================\n")

if __name__ == "__main__":
    build_cloze_dataset()
