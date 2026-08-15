import collections
import re
import json
import os
import math
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
    
    stop_words = {"the", "of", "and", "a", "an", "in", "to", "is", "it", "that", "this", "for", "on", "with", "as", "at", "by", "from", "or", "be"}
    # Reject if ALL words are stop words (e.g., "of the", "in a")
    if all(w in stop_words for w in words):
        return False
    # Reject if phrase contains single-letter words other than 'a' or 'i'
    if any(len(w) == 1 and w not in {'a', 'i'} for w in words):
        return False
    return True

def extract_domain_phrases(dataset_name, config=None, text_field="text", sample_size=1000, n_gram_size=2):
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
    """Harvests N-grams across Conversational, Narrative, Structural, and Scientific domains."""
    domains = [
        # Conversational
        {"name": "OpenAssistant/oasst1", "config": None, "field": "text", "type": "conversational"},
        # Narrative & Prose
        {"name": "roneneldan/TinyStories", "config": None, "field": "text", "type": "narrative"},
        # Structural & Logic
        {"name": "Salesforce/wikitext", "config": "wikitext-103-raw-v1", "field": "text", "type": "structural"},
        # Science & Math
        {"name": "gfissore/arxiv-abstracts-2021", "config": None, "field": "abstract", "type": "scientific"}
    ]
    
    all_harvested_phrases = []
    
    for dom in domains:
        for n_size in [2, 3]: # Bigrams and Trigrams
            counter = extract_domain_phrases(
                dataset_name=dom["name"],
                config=dom["config"],
                text_field=dom["field"],
                sample_size=300,
                n_gram_size=n_size
            )
            
            top_items = counter.most_common(100)
            print(f"[Harvester] Extracted {len(top_items)} top {n_size}-grams for domain '{dom['type']}'")
            
            for phrase, freq in top_items:
                all_harvested_phrases.append({
                    "phrase": phrase,
                    "frequency": freq,
                    "domain": dom["type"],
                    "n_gram_size": n_size,
                    "cloze_prompt": f"Context phrase: [BLANK] -> {phrase}",
                    "target_phrase": phrase
                })
                
    os.makedirs("scratch", exist_ok=True)
    out_file = "scratch/mined_expanded_corpus_cloze.jsonl"
    with open(out_file, "w", encoding="utf-8") as f:
        for item in all_harvested_phrases:
            f.write(json.dumps(item) + "\n")
            
    print(f"\n[Harvester Complete] Harvested {len(all_harvested_phrases)} unique N-grams into {out_file}")

if __name__ == "__main__":
    build_cloze_dataset()
