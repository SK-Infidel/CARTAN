import re
import json
import os
import html
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

def clean_ascii_and_artifacts(text):
    """Sanitizes text by unescaping HTML entities, removing subtoken @-@ markers, curly quotes, and control codes."""
    if not text:
        return ""
    text = html.unescape(str(text))
    text = text.replace("@-@", "-").replace("@,@", ",")
    text = text.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"').replace("—", "-").replace("–", "-")
    text = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', text)
    text = re.sub(r'[\r\n\t]+', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def harvest_chunked_discrete_sentence_cloze():
    """Streams corpora and outputs discrete individual sentence cloze prompts in 50,000-line chunks."""
    print("================================================================================")
    print("  DISCRETE SENTENCE CLOZE HARVESTER & CHUNKING ENGINE")
    print("  Ken Hyland Exact Metadiscourse Inventory (50,000 Discrete Lines Per Chunk)")
    print("================================================================================")

    domains = [
        {"name": "Salesforce/wikitext", "config": "wikitext-103-raw-v1", "field": "text", "type": "structural"},
        {"name": "OpenAssistant/oasst1", "config": None, "field": "text", "type": "conversational"},
        {"name": "gfissore/arxiv-abstracts-2021", "config": None, "field": "abstract", "type": "scientific"},
        {"name": "roneneldan/TinyStories", "config": None, "field": "text", "type": "narrative"}
    ]

    item_category_map = {}
    hyland_flat = []
    for cat, items in HYLAND_EXACT_TAXONOMY.items():
        for item in items:
            clean_item = clean_ascii_and_artifacts(item).lower()
            item_category_map[clean_item] = cat
            hyland_flat.append(clean_item)

    hyland_flat.sort(key=lambda x: len(x), reverse=True)

    os.makedirs("scratch", exist_ok=True)
    chunk_size = 50000
    current_chunk_index = 1
    total_written_lines = 0

    chunk_filename = f"scratch/mined_expanded_corpus_cloze_part{current_chunk_index:02d}.jsonl"
    current_file = open(chunk_filename, "w", encoding="utf-8")
    lines_in_chunk = 0
    category_counts = collections.Counter()

    for dom in domains:
        print(f"\n[Harvester Stream] Streaming sentences from '{dom['name']}' ({dom['type']})...")
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

        domain_lines = 0
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

            raw_text = clean_ascii_and_artifacts(text_val)
            if len(raw_text) < 15:
                continue

            # Split into individual sentences
            sentences = re.split(r'[.!?]+', raw_text)
            for sent in sentences:
                sent_clean = clean_ascii_and_artifacts(sent)
                if len(sent_clean) < 15:
                    continue
                
                sent_lower = sent_clean.lower()
                for item in hyland_flat:
                    pat = r'\b' + re.escape(item) + r'\b'
                    if re.search(pat, sent_lower):
                        cat_name = item_category_map[item]
                        # Replace the first occurrence of item with [BLANK]
                        cloze_sentence = re.sub(pat, "[BLANK]", sent_clean, count=1, flags=re.IGNORECASE)
                        
                        entry = {
                            "sentence_cloze": cloze_sentence,
                            "target_phrase": item,
                            "category": cat_name,
                            "domain": dom["type"],
                            "full_sentence": sent_clean
                        }

                        current_file.write(json.dumps(entry) + "\n")
                        lines_in_chunk += 1
                        total_written_lines += 1
                        domain_lines += 1
                        category_counts[cat_name] += 1

                        # Rotate chunk file when limit reached
                        if lines_in_chunk >= chunk_size:
                            current_file.close()
                            print(f"[Harvester Chunk] Saved {lines_in_chunk} discrete lines -> {chunk_filename}")
                            current_chunk_index += 1
                            chunk_filename = f"scratch/mined_expanded_corpus_cloze_part{current_chunk_index:02d}.jsonl"
                            current_file = open(chunk_filename, "w", encoding="utf-8")
                            lines_in_chunk = 0

                        # Match first dominant metadiscourse marker per sentence to keep training samples crisp
                        break

        print(f"[Harvester Stream] Extracted {domain_lines} discrete sentence cloze prompts from {dom['name']}")

    if not current_file.closed:
        current_file.close()
        print(f"[Harvester Chunk] Saved {lines_in_chunk} discrete lines -> {chunk_filename}")

    # Also create main index / alias file pointing to part 1
    master_file = "scratch/mined_expanded_corpus_cloze.jsonl"
    with open(master_file, "w", encoding="utf-8") as f_out, open("scratch/mined_expanded_corpus_cloze_part01.jsonl", "r", encoding="utf-8") as f_in:
        for l in f_in:
            f_out.write(l)

    print("\n================================================================================")
    print("  DISCRETE SENTENCE CLOZE HARVEST SUMMARY")
    print("================================================================================")
    print(f"  Total Discrete Sentence Cloze Lines Mined : {total_written_lines}")
    print(f"  Total Chunk Files Created                 : {current_chunk_index}")
    print("  Category Distribution:")
    for cat, cnt in category_counts.most_common():
        print(f"    - Category '{cat}': {cnt} discrete sentence prompts")
    print(f"  Primary Dataset Checkpoint                : {master_file}")
    print("================================================================\n")

if __name__ == "__main__":
    harvest_chunked_discrete_sentence_cloze()
