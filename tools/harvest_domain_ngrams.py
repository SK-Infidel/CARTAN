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

# 2. Named Entity & Slot Abstraction Dictionaries
MONTHS = {"january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"}
DAYS = {"monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"}
TERRAINS = {"farmland", "forest", "desert", "mountain", "valley", "river", "ocean", "jungle", "field", "meadow", "woods", "plain", "hills"}
LOCATIONS = {"scotland", "england", "france", "germany", "america", "japan", "china", "london", "paris", "tokyo", "europe", "asia", "africa"}

def abstract_parametric_slot(phrase):
    """Abstracts specific proper nouns, dates, months, and terrains into parametric slot tags."""
    words = phrase.split()
    abstracted_words = []
    
    for w in words:
        clean_w = w.lower().strip()
        if clean_w in MONTHS:
            abstracted_words.append("<MONTH>")
        elif clean_w in DAYS:
            abstracted_words.append("<DAY>")
        elif clean_w in TERRAINS:
            abstracted_words.append("<TERRAIN>")
        elif clean_w in LOCATIONS:
            abstracted_words.append("<LOCATION>")
        elif clean_w.isdigit() and len(clean_w) == 4:
            abstracted_words.append("<YEAR>")
        elif clean_w.isdigit():
            abstracted_words.append("<NUMBER>")
        else:
            abstracted_words.append(clean_w)
            
    res = " ".join(abstracted_words)
    # Only keep patterns that contain at least one abstract slot tag
    if any(tag in res for tag in ["<MONTH>", "<DAY>", "<TERRAIN>", "<LOCATION>", "<YEAR>", "<NUMBER>"]):
        return res
    return None

# 3. Parametric Prepositional Frame Regex Patterns
PREPOSITIONAL_FRAME_PATTERNS = [
    r'\b(?:in|on|at|by|with|through|under|upon|after|before|during|between|across|along|around|near|into)\s+[a-z\-0-9]+\s+(?:of|for|in|to|with|at|by|on|from)\b',
    r'\b(?:in|on|at|by|with|through|under|upon|after|before|during|between|across|along|around|near|into)\s+[a-z\-0-9]+\s+[a-z\-0-9]+\s+(?:of|for|in|to|with|at|by|on|from)\b'
]

def harvest_parametric_discourse_schemas():
    """Harvests thousands of Abstract Parametric Discourse Schemas & Attention Triggers."""
    print("================================================================================")
    print("  PARAMETRIC DISCOURSE SCHEMA & ATTENTION TRIGGER HARVESTER ENGINE")
    print("================================================================================")

    domains = [
        {"name": "Salesforce/wikitext", "config": "wikitext-103-raw-v1", "field": "text", "type": "structural"},
        {"name": "OpenAssistant/oasst1", "config": None, "field": "text", "type": "conversational"},
        {"name": "gfissore/arxiv-abstracts-2021", "config": None, "field": "abstract", "type": "scientific"},
        {"name": "roneneldan/TinyStories", "config": None, "field": "text", "type": "narrative"}
    ]

    schema_counter = collections.Counter()
    schema_examples = collections.defaultdict(list)

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

            for pat in PREPOSITIONAL_FRAME_PATTERNS:
                matches = re.findall(pat, text_str.lower())
                for m in matches:
                    raw_phrase = m.strip()
                    abstract_schema = abstract_parametric_slot(raw_phrase)
                    if abstract_schema:
                        schema_counter[abstract_schema] += 1
                        dataset_count += 1
                        if len(schema_examples[abstract_schema]) < 3:
                            schema_examples[abstract_schema].append(raw_phrase)

        print(f"[Harvester Stream] Extracted {dataset_count} parametric frame instances from {dom['name']}")

    harvested_items = []
    for schema, freq in schema_counter.most_common(5000):
        harvested_items.append({
            "parametric_schema": schema,
            "frequency": freq,
            "boundary_anchors": [schema.split()[0], schema.split()[-1]],
            "sample_instantiations": schema_examples.get(schema, []),
            "word_count": len(schema.split()),
            "cloze_prompt": f"Parametric Trigger [{schema}]: [BLANK] -> {schema}",
            "target_phrase": schema
        })

    os.makedirs("scratch", exist_ok=True)
    out_file = "scratch/mined_expanded_corpus_cloze.jsonl"
    with open(out_file, "w", encoding="utf-8") as f:
        for item in harvested_items:
            f.write(json.dumps(item) + "\n")

    print("\n================================================================================")
    print("  PARAMETRIC DISCOURSE SCHEMA HARVEST SUMMARY")
    print("================================================================================")
    print(f"  Total Abstract Parametric Schemas Mined : {len(harvested_items)}")
    print(f"  Top 5 Parametric Attention Triggers    :")
    for item in harvested_items[:5]:
        print(f"    - Schema '{item['parametric_schema']}' (Found {item['frequency']}x) | Samples: {item['sample_instantiations']}")
    print(f"  Output File                             : {out_file}")
    print("================================================================================\n")

if __name__ == "__main__":
    harvest_parametric_discourse_schemas()
