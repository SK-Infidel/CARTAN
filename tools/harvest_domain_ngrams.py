import collections
import re
import json
import os
from datasets import load_dataset

# 1. Explicit HF Token Initialization
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
    print("[Harvester Auth] HF_TOKEN active for explicit dataset authentication.")

# 2. Linguistic Metadiscourse Taxonomy (Hyland & Kennett Framework)
METADISCOURSE_PATTERNS = {
    "single_word_transitions": [
        "furthermore", "consequently", "critically", "conversely", "nevertheless",
        "accordingly", "undoubtedly", "meanwhile", "admittedly", "ultimately",
        "finally", "moreover", "nonetheless", "hence", "thus", "instead",
        "likewise", "similarly", "indeed", "additionally", "subsequently", "inevitably"
    ],
    "multi_word_transitions": [
        "as well as", "in addition to", "on the other hand", "as a result",
        "in contrast to", "it follows that", "as a matter of fact", "on the contrary",
        "in the first place", "in the mean time", "to begin with", "first of all",
        "all in all", "in conclusion", "to summarize", "in light of", "owing to",
        "with respect to", "in terms of", "for this reason"
    ],
    "hedges_and_boosters": [
        "it seems likely that", "evidence suggests that", "appears to be",
        "may indicate that", "without a doubt", "most importantly",
        "there is no question that", "it is clear that", "undeniably",
        "it is evident that", "it stands to reason that", "in all probability",
        "highly probable that", "strongly suggests that", "it is vital to"
    ],
    "code_glosses": [
        "that is to say", "in simple terms", "to put it another way",
        "namely", "specifically", "in other words", "for instance",
        "for example", "such as", "specifically speaking", "to illustrate",
        "put simply", "defined as", "means that"
    ],
    "discourse_frames": [
        "by the way", "mind you", "you see", "frankly speaking",
        "to be honest", "at the end of the day", "look at it this way",
        "believe it or not", "truth be told", "speaking of which",
        "as far as", "it goes without saying"
    ]
}

# Flatten all reference patterns for instant lookup
ALL_METADISCOURSE_PHRASES = set()
for cat, phrases in METADISCOURSE_PATTERNS.items():
    for p in phrases:
        ALL_METADISCOURSE_PHRASES.add(p.lower())

def clean_and_split_sentences(text):
    """Splits text into clean lowercase sentences."""
    if not text:
        return []
    # Clean formatting
    text = text.lower().replace("\n", " ").strip()
    sentences = re.split(r'[.!?]+', text)
    return [s.strip() for s in sentences if len(s.strip()) > 5]

def extract_metadiscourse_from_corpus(dataset_name, config=None, text_field="text", sample_size=4000):
    """Streams a dataset and harvests genuine Metadiscourse Attractors and Transitions."""
    print(f"[Harvester] Streaming {dataset_name} ({config or 'default'}) for Metadiscourse Attractors...")
    
    try:
        kwargs = {"split": "train", "streaming": True}
        if token:
            kwargs["token"] = token
        if config:
            dataset = load_dataset(dataset_name, config, **kwargs)
        else:
            dataset = load_dataset(dataset_name, **kwargs)
    except Exception as e:
        print(f"[Harvester Warning] Could not stream {dataset_name}: {e}")
        return collections.Counter()

    found_counter = collections.Counter()
    
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
        
        sentences = clean_and_split_sentences(str(text_content))
        for sent in sentences:
            # 1. Match pre-defined metadiscourse patterns
            for target_p in ALL_METADISCOURSE_PHRASES:
                if target_p in sent:
                    found_counter[target_p] += 1
            
            # 2. Extract syntactic sentence-initial transition adverbs ([Adverb] ,)
            words = sent.split()
            if len(words) > 3 and words[0].isalpha() and len(words[0]) > 4:
                first_word = words[0]
                if first_word.endswith("ly") or first_word.endswith("wise") or first_word.endswith("more"):
                    found_counter[first_word] += 1

    return found_counter

def build_metadiscourse_dataset():
    """Harvests thousands of genuine Metadiscourse & Discourse Attractors across datasets."""
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
    seen_phrases = set()
    
    # First seed all taxonomy phrases into the dataset so they are 100% present
    for category_name, phrase_list in METADISCOURSE_PATTERNS.items():
        for phrase in phrase_list:
            if phrase not in seen_phrases:
                seen_phrases.add(phrase)
                all_harvested_phrases.append({
                    "phrase": phrase,
                    "category": category_name,
                    "domain": "taxonomy_core",
                    "word_count": len(phrase.split()),
                    "cloze_prompt": f"Discourse frame: [BLANK] -> {phrase}",
                    "target_phrase": phrase
                })

    print(f"[Harvester] Seeded {len(all_harvested_phrases)} core Metadiscourse taxonomy attractors.")

    # Second stream real datasets to discover thousands of active occurrences
    for dom in domains:
        counter = extract_metadiscourse_from_corpus(
            dataset_name=dom["name"],
            config=dom["config"],
            text_field=dom["field"],
            sample_size=4000
        )
        
        top_items = counter.most_common(1500)
        added_count = 0
        
        for phrase, freq in top_items:
            if phrase not in seen_phrases:
                seen_phrases.add(phrase)
                all_harvested_phrases.append({
                    "phrase": phrase,
                    "frequency": freq,
                    "domain": dom["type"],
                    "word_count": len(phrase.split()),
                    "cloze_prompt": f"Discourse frame: [BLANK] -> {phrase}",
                    "target_phrase": phrase
                })
                added_count += 1
        print(f"[Harvester] Added {added_count} discovered discourse attractors from dataset '{dom['name']}' ({dom['type']})")
            
    os.makedirs("scratch", exist_ok=True)
    out_file = "scratch/mined_expanded_corpus_cloze.jsonl"
    with open(out_file, "w", encoding="utf-8") as f:
        for item in all_harvested_phrases:
            f.write(json.dumps(item) + "\n")
            
    print(f"\n================================================================================")
    print(f"  METADISCOURSE ATTRACTOR HARVEST COMPLETE")
    print(f"  Total Unique Discourse Attractors Mined: {len(all_harvested_phrases)}")
    print(f"  Output File: {out_file}")
    print(f"================================================================================\n")

if __name__ == "__main__":
    build_metadiscourse_dataset()
