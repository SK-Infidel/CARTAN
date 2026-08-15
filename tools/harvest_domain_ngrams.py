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

# 2. Ken Hyland's Exact 10-Category Metadiscourse Inventory (Hyland, 2005)
HYLAND_EXACT_TAXONOMY = {
    "Transitions": [
        "however", "therefore", "moreover", "furthermore", "consequently", "in contrast",
        "on the other hand", "in addition", "as a result", "in fact", "conversely",
        "nevertheless", "accordingly", "hence", "thus", "instead", "likewise", "similarly",
        "indeed", "additionally", "subsequently", "inevitably", "besides", "further",
        "alternatively", "on the contrary", "in comparison", "by contrast", "in spite of",
        "on the one hand", "at the same time", "in the first place", "nonetheless"
    ],
    "Frame Markers": [
        "first", "firstly", "second", "secondly", "third", "thirdly", "finally", "lastly",
        "in conclusion", "to conclude", "to summarize", "in summary", "overall", "in short",
        "briefly", "to sum up", "now", "then", "next", "at this point", "so far",
        "to begin with", "my purpose is", "our aim is", "the goal of this paper is",
        "this section discusses", "let us turn to", "moving to", "with regard to"
    ],
    "Code Glosses": [
        "namely", "specifically", "in other words", "that is", "that is to say", "such as",
        "for example", "for instance", "including", "defined as", "meaning", "which means",
        "i.e.", "e.g.", "in particular", "put another way", "called", "known as"
    ],
    "Evidentials": [
        "according to", "demonstrate", "show", "indicate", "suggest", "report", "find",
        "argues", "states", "notes", "observed", "found by", "cited in", "as noted by",
        "as shown by", "as reported by", "claims", "observed by"
    ],
    "Endophoric Markers": [
        "see figure", "see table", "refer to", "shown in figure", "discussed in section",
        "in chapter", "below", "above", "as noted above", "as shown below", "see section"
    ],
    "Self Mentions": [
        "i", "we", "my", "our", "me", "us", "the author", "this study", "i argue",
        "we propose", "our research", "my view", "we believe", "i conclude", "this paper",
        "our findings", "our results", "my analysis"
    ],
    "Hedges": [
        "might", "could", "perhaps", "possibly", "probably", "likely", "seem", "appear",
        "suggest", "indicate", "assume", "presume", "somewhat", "partly", "relatively",
        "about", "around", "almost", "tentatively", "may", "would", "in general",
        "appears to", "seems to", "tends to"
    ],
    "Boosters": [
        "clearly", "obviously", "definitely", "certainly", "undoubtedly", "strongly",
        "in fact", "indeed", "always", "never", "proves", "demonstrates", "shows beyond doubt",
        "it is clear that", "there is no doubt", "it is evident that", "conclusively"
    ],
    "Attitude Markers": [
        "unfortunately", "surprisingly", "hopefully", "remarkably", "interestingly",
        "importantly", "crucially", "significantly", "strikingly", "regrettably",
        "understandably", "admittedly", "prefer", "agree", "disagree", "essential",
        "even more important", "surprisingly enough"
    ],
    "Engagement Markers": [
        "note that", "consider", "observe", "see", "you", "your", "one", "we should",
        "must", "need to", "imagine", "let us", "suppose", "recall", "look at",
        "think about", "notice that"
    ]
}

import html

def clean_ascii_and_artifacts(text):
    """Sanitizes text by unescaping HTML entities, removing subtoken @-@ markers, curly quotes, and control codes."""
    if not text:
        return ""
    # Unescape HTML entities (&amp;, &#39;, &quot;)
    text = html.unescape(str(text))
    # Remove subtoken artifacts like '@-@'
    text = text.replace("@-@", "-").replace("@,@", ",")
    # Normalize curly quotes/dashes to standard ASCII
    text = text.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"').replace("—", "-").replace("–", "-")
    # Strip non-printable ASCII control characters
    text = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', text)
    # Collapse newlines/tabs and whitespace
    text = re.sub(r'[\r\n\t]+', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def harvest_hyland_exact_list():
    """Harvests Ken Hyland's exact 10-category metadiscourse inventory across streaming datasets."""
    print("================================================================================")
    print("  KEN HYLAND EXACT METADISCOURSE TAXONOMY HARVESTER ENGINE (ASCII CLEAN)")
    print("================================================================================")

    domains = [
        {"name": "Salesforce/wikitext", "config": "wikitext-103-raw-v1", "field": "text", "type": "structural"},
        {"name": "OpenAssistant/oasst1", "config": None, "field": "text", "type": "conversational"},
        {"name": "gfissore/arxiv-abstracts-2021", "config": None, "field": "abstract", "type": "scientific"},
        {"name": "roneneldan/TinyStories", "config": None, "field": "text", "type": "narrative"}
    ]

    item_counter = collections.Counter()
    category_counts = collections.Counter()
    item_category_map = {}
    item_examples = collections.defaultdict(list)

    # Flatten Hyland list into exact regex lookup
    hyland_flat = []
    for cat, items in HYLAND_EXACT_TAXONOMY.items():
        for item in items:
            clean_item = clean_ascii_and_artifacts(item).lower()
            item_category_map[clean_item] = cat
            hyland_flat.append(clean_item)

    # Sort items by length (longest first) to avoid partial sub-token overlap
    hyland_flat.sort(key=lambda x: len(x), reverse=True)

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

            text_str = clean_ascii_and_artifacts(text_val).lower()
            if len(text_str) < 15:
                continue

            for item in hyland_flat:
                # Word boundary regex search for exact Hyland items
                pat = r'\b' + re.escape(item) + r'\b'
                matches = re.findall(pat, text_str)
                if matches:
                    cnt = len(matches)
                    item_counter[item] += cnt
                    cat_name = item_category_map[item]
                    category_counts[cat_name] += cnt
                    dataset_count += cnt
                    if len(item_examples[item]) < 3:
                        clean_ctx = clean_ascii_and_artifacts(text_str[:120])
                        item_examples[item].append(clean_ctx)

        print(f"[Harvester Stream] Matched {dataset_count} Hyland metadiscourse occurrences in {dom['name']}")

    harvested_items = []
    for item, freq in item_counter.most_common():
        cat_name = item_category_map[item]
        harvested_items.append({
            "phrase": item,
            "category": cat_name,
            "frequency": freq,
            "word_count": len(item.split()),
            "sample_contexts": item_examples.get(item, []),
            "cloze_prompt": f"Hyland Metadiscourse [{cat_name}]: [BLANK] -> {item}",
            "target_phrase": item
        })

    os.makedirs("scratch", exist_ok=True)
    out_file = "scratch/mined_expanded_corpus_cloze.jsonl"
    with open(out_file, "w", encoding="utf-8") as f:
        for entry in harvested_items:
            f.write(json.dumps(entry) + "\n")

    print("\n================================================================================")
    print("  KEN HYLAND EXACT METADISCOURSE HARVEST SUMMARY")
    print("================================================================================")
    print(f"  Total Unique Hyland Metadiscourse Items Mined : {len(harvested_items)}")
    print(f"  Total Metadiscourse Tokens Matched            : {sum(item_counter.values())}")
    print("  Breakdown by Hyland Taxonomy Category:")
    for cat, cnt in category_counts.most_common():
        print(f"    - Category '{cat}': {cnt} token occurrences")
    print(f"  Output Checkpoint Dataset                     : {out_file}")
    print("================================================================================\n")

if __name__ == "__main__":
    harvest_hyland_exact_list()
