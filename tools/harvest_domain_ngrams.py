import re
import json
import os
import collections
from datasets import load_dataset

# 1. HF Token Setup
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

# 2. Universal Syntactic Grammatical Categories
PREP_HEADS = {"in", "on", "at", "by", "with", "through", "under", "upon", "after", "before", "during", "between", "across", "along", "around", "near", "into", "over", "above", "behind", "beneath", "beside", "beyond", "towards", "onto"}
PREP_TAILS = {"to", "for", "with", "of", "in", "at", "by", "on", "from", "as", "about", "into", "through"}
DETERMINERS = {"the", "a", "an", "this", "that", "these", "those", "their", "our", "my", "his", "her", "its"}

MONTHS = {"january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"}
DAYS = {"monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"}
TERRAINS = {"farmland", "forest", "desert", "mountain", "valley", "river", "ocean", "jungle", "field", "meadow", "woods", "plain", "hills", "island", "sea", "lake"}
LOCATIONS = {"scotland", "england", "france", "germany", "america", "japan", "china", "london", "paris", "tokyo", "europe", "asia", "africa", "italy", "spain"}

def reduce_to_meta_schema(phrase):
    """Reduces specific prepositional phrases into Universal Meta-Parametric Schemas."""
    words = phrase.split()
    if len(words) < 3:
        return None
        
    w_head = words[0].lower().strip()
    w_tail = words[-1].lower().strip()
    
    if w_head not in PREP_HEADS or w_tail not in PREP_TAILS:
        return None
        
    middle_words = words[1:-1]
    meta_middle = []
    
    for mw in middle_words:
        clean_mw = mw.lower().strip()
        if clean_mw in DETERMINERS:
            meta_middle.append("<DET>")
        elif clean_mw in TERRAINS:
            meta_middle.append("<TERRAIN>")
        elif clean_mw in LOCATIONS:
            meta_middle.append("<LOCATION>")
        elif clean_mw in MONTHS:
            meta_middle.append("<MONTH>")
        elif clean_mw in DAYS:
            meta_middle.append("<DAY>")
        elif clean_mw.isdigit() and len(clean_mw) == 4:
            meta_middle.append("<YEAR>")
        elif clean_mw.isdigit():
            meta_middle.append("<NUMBER>")
        else:
            meta_middle.append("<NOUN_SLOT>")

    schema_str = f"<PREP_HEAD> {' '.join(meta_middle)} <PREP_TAIL>"
    return schema_str

# Prepositional Frame Regex Capture
FRAME_REGEX = r'\b(?:in|on|at|by|with|through|under|upon|after|before|during|between|across|along|around|near|into|over|above|behind|beneath|beside|beyond|towards|onto)\s+[a-z\-0-9]+(?:\s+[a-z\-0-9]+)?\s+(?:to|for|with|of|in|at|by|on|from|as|about|into|through)\b'

def harvest_meta_parametric_schemas():
    """Harvests Universal Meta-Parametric Prepositional Schemas across datasets."""
    print("================================================================================")
    print("  UNIVERSAL META-PARAMETRIC SCHEMA REDUCTION HARVESTER")
    print("================================================================================")

    domains = [
        {"name": "Salesforce/wikitext", "config": "wikitext-103-raw-v1", "field": "text", "type": "structural"},
        {"name": "OpenAssistant/oasst1", "config": None, "field": "text", "type": "conversational"},
        {"name": "gfissore/arxiv-abstracts-2021", "config": None, "field": "abstract", "type": "scientific"},
        {"name": "roneneldan/TinyStories", "config": None, "field": "text", "type": "narrative"}
    ]

    meta_schema_counter = collections.Counter()
    meta_schema_instantiations = collections.defaultdict(list)

    for dom in domains:
        print(f"\n[Harvester Stream] Streaming 25,000 sentences from '{dom['name']}' ({dom['type']})...")
        try:
            kwargs = {"split": "train", "streaming": True}
            if token:
                kwargs["token"] = token
            if dom["config"]:
                ds = load_dataset(dom["name"], dom["config"], **kwargs)
            else:
                ds = load_dataset(dom["name"], **kwargs)
        except Exception as e:
            print(f"[Harvester Warning] Could not stream {dom['name']}: {e}")
            continue

        dataset_count = 0
        for i, example in enumerate(ds):
            if i >= 25000:
                break
                
            text_val = example.get(dom["field"], "")
            if not text_val and isinstance(example, dict):
                for k in ["abstract", "text", "dialog", "dialogue", "content"]:
                    if k in example and example[k]:
                        text_val = example[k]
                        if isinstance(text_val, list):
                            text_val = " ".join(text_val)
                        break

            text_str = re.sub(r'[\r\n\t]+', ' ', str(text_val)).strip()
            text_str = re.sub(r'\s+', ' ', text_str)
            if len(text_str) < 15:
                continue

            matches = re.findall(FRAME_REGEX, text_str.lower())
            for raw_m in matches:
                clean_m = raw_m.strip()
                meta_schema = reduce_to_meta_schema(clean_m)
                if meta_schema:
                    meta_schema_counter[meta_schema] += 1
                    dataset_count += 1
                    if len(meta_schema_instantiations[meta_schema]) < 5:
                        if clean_m not in meta_schema_instantiations[meta_schema]:
                            meta_schema_instantiations[meta_schema].append(clean_m)

        print(f"[Harvester Stream] Harvested {dataset_count} meta-parametric instances from {dom['name']}")

    harvested_items = []
    for schema, freq in meta_schema_counter.most_common(1000):
        harvested_items.append({
            "meta_schema": schema,
            "total_frequency": freq,
            "syntactic_structure": "<PREP_HEAD> [INNER_SLOT] <PREP_TAIL>",
            "sample_concrete_instances": meta_schema_instantiations.get(schema, []),
            "word_count": len(schema.split()),
            "cloze_prompt": f"Universal Meta-Schema [{schema}]: [BLANK] -> {schema}",
            "target_phrase": schema
        })

    os.makedirs("scratch", exist_ok=True)
    out_file = "scratch/mined_expanded_corpus_cloze.jsonl"
    with open(out_file, "w", encoding="utf-8") as f:
        for item in harvested_items:
            f.write(json.dumps(item) + "\n")

    print("\n================================================================================")
    print("  UNIVERSAL META-PARAMETRIC SCHEMA SUMMARY")
    print("================================================================================")
    print(f"  Total Universal Meta-Schemas Mined   : {len(harvested_items)}")
    print(f"  Top Universal Meta-Parametric Schemas:")
    for item in harvested_items[:8]:
        print(f"    - Meta-Schema '{item['meta_schema']}' (Found {item['total_frequency']}x)")
        print(f"      Instantiations: {item['sample_concrete_instances'][:3]}")
    print(f"  Output Checkpoint Dataset            : {out_file}")
    print("================================================================================\n")

if __name__ == "__main__":
    harvest_meta_parametric_schemas()
