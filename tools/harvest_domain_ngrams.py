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

# 2. Research-Grade Hyland Metadiscourse Pattern Engine (from metadiscourse_analysis)
HYLAND_PATTERNS = {
    'self_mentions': [
        r'\b(?:in\s+)?my\s+(?:opinion|view|perspective|belief|judgment|analysis|assessment|conclusion|argument|position|stance|understanding|experience)\b',
        r'\b(?:I\s+)?(?:believe|argue|contend|maintain|assert|claim|suggest|propose|conclude|find|observe|note|demonstrate|show|establish|prove)\s+that\b',
        r'\b(?:I\s+)?(?:will|shall)\s+(?:demonstrate|show|argue|analyze|examine|investigate|explore|discuss|present|propose|suggest|conclude)\b',
        r'\bwe\s+(?:can|must|should|need\s+to|have\s+to)\s+(?:understand|recognize|acknowledge|accept|consider|examine|analyze|investigate|conclude|observe|note|realize|see|assume|presume|infer|deduce|argue|claim|suggest|propose|demonstrate|show|establish|prove|find|determine)\b',
        r'\bwe\s+(?:find|see|observe|note|notice|discover|establish|demonstrate|show|prove|conclude|determine|realize|recognize|understand|know|believe|argue|contend|maintain|assert|claim)\s+that\b',
        r'\bas\s+we\s+(?:have\s+)?(?:seen|observed|noted|discussed|examined|analyzed|established|demonstrated|shown|proved|found|discovered|learned|understood|argued|concluded)\b',
        r'\b(?:our|my)\s+(?:research|study|investigation|analysis|findings|results|conclusions|observations|data|evidence)\b'
    ],
    'hedges': [
        r'(?i)\b(?:the\s+)?(?:results?|data|evidence|findings?|research|study)\s+(?:seem|seems?|appear|appears?)\s+to\s+(?:indicate|suggest|show|demonstrate|support|imply)\b',
        r'(?i)\b(?:this|that|it|they|these)\s+(?:might|may|could|would)\s+(?:suggest|indicate|imply|show|demonstrate|mean|signify)\b',
        r'(?i)\bit\s+(?:appears|seems)\s+that\b',
        r'(?i)\bperhaps\s+(?:this|that|these|the)\s+(?:finding|result|evidence|data|research|study|analysis|approach|method)\b',
        r'(?i)\b(?:the\s+)?(?:data|evidence|results?|findings?)\s+(?:may|might|could)\s+(?:imply|suggest|indicate|mean|show)\b',
        r'(?i)\bto\s+some\s+extent\b',
        r'(?i)\b(?:possibly|probably|likely|presumably|apparently|seemingly)\b',
        r'(?i)\bit\s+is\s+(?:possible|probable|likely)\s+that\b'
    ],
    'boosters': [
        r'(?i)\bit\s+is\s+clear\s+that\b',
        r'(?i)\b(?:this|that|it|they|these|research|evidence|data|results|findings)\s+(?:certainly|definitely|clearly|obviously|undoubtedly|evidently)\s+(?:proves?|demonstrates?|shows?|indicates?|suggests?|supports?|confirms?|establishes?)\b',
        r'(?i)^obviously\s*,\s*\b',
        r'(?i)\b(?:the\s+)?(?:evidence|data|results|findings|research|study)\s+(?:clearly|obviously|certainly|definitely|undoubtedly|evidently)\s+(?:indicates?|shows?|demonstrates?|suggests?|supports?|proves?)\b',
        r'(?i)\bthere\s+is\s+no\s+doubt\s+that\b',
        r'(?i)\b(?:without\s+doubt|beyond\s+doubt|no\s+question)\b',
        r'(?i)\b(?:absolutely|completely|entirely|totally)\s+(?:necessary|essential|crucial|certain|clear|correct|valid)\b',
        r'(?i)\b(?:strong|compelling|convincing|solid|robust)\s+(?:evidence|support|indication|correlation|case|argument)\b'
    ],
    'frame_markers': [
        r'^\s*(?:first|firstly|second|secondly|third|thirdly|fourth|fourthly|fifth|fifthly|finally|lastly|in\s+conclusion|to\s+conclude|to\s+summarize|in\s+summary|overall|all\s+in\s+all|in\s+short|briefly)\b',
        r'\bthe\s+(?:first|second|third|fourth|fifth|final|last|next|previous|above|following)\s+(?:section|chapter|part|point|issue|aspect|factor|element|component|argument|example|case|study|analysis)\b',
        r'\bin\s+(?:this|the\s+following|the\s+next|the\s+final|the\s+last|the\s+above|the\s+previous)\s+(?:section|chapter|part|paper|study|analysis|discussion|essay|article|work|research)\b',
        r'\bas\s+(?:mentioned|noted|discussed|shown|demonstrated|illustrated|indicated|stated)\s+(?:above|below|earlier|previously|before)\b',
        r'\b(?:moving|turning|shifting)\s+(?:to|on\s+to)\s+(?:the|our|my)\s+(?:next|final|last)\b',
        r'\b(?:in\s+sum|to\s+sum\s+up|summing\s+up|in\s+summary|to\s+summarize|in\s+conclusion|to\s+conclude|overall|all\s+things\s+considered|on\s+the\s+whole)\b',
        r'\b(?:the\s+purpose\s+of|the\s+aim\s+of|the\s+goal\s+of)\s+(?:this|the)\s+(?:paper|study|research|analysis|discussion|essay|work)\b'
    ],
    'code_glosses': [
        r'\b(?:that\s+is\s+to\s+say|namely|specifically|in\s+other\s+words|in\s+particular)\b',
        r'(?i)\b(?:for\s+example|for\s+instance)\b',
        r'\b(?:such\s+as)\b',
        r'\bincluding\b',
        r'\bthat\s+is\b'
    ],
    'transitions': [
        r'\b(?:furthermore|consequently|critically|conversely|nevertheless|accordingly|undoubtedly|meanwhile|admittedly|ultimately|finally|moreover|nonetheless|hence|thus|instead|likewise|similarly|indeed|additionally|subsequently|inevitably)\b',
        r'\b(?:as\s+well\s+as|in\s+addition\s+to|on\s+the\s+other\s+hand|as\s+a\s+result|in\s+contrast\s+to|it\s+follows\s+that|as\s+a\s+matter\s+of\s+fact|on\s+the\s+contrary|in\s+the\s+first\s+place|in\s+the\s+mean\s+time|to\s+begin\s+with|first\s+of\s+all|all\s+in\s+all|in\s+conclusion|to\s+summarize|in\s+light\s+of|owing\s+to|with\s+respect\s+to|in\s+terms\s+of|for\s+this\s+reason)\b'
    ]
}

def harvest_hyland_metadiscourse():
    """Extracts research-grade Hyland metadiscourse attractors across public corpora."""
    print("================================================================================")
    print("  RESEARCH-GRADE HYLAND METADISCOURSE HARVESTER ENGINE")
    print("================================================================================")

    domains = [
        {"name": "OpenAssistant/oasst1", "config": None, "field": "text", "type": "conversational"},
        {"name": "roneneldan/TinyStories", "config": None, "field": "text", "type": "narrative"},
        {"name": "Salesforce/wikitext", "config": "wikitext-103-raw-v1", "field": "text", "type": "structural"},
        {"name": "gfissore/arxiv-abstracts-2021", "config": None, "field": "abstract", "type": "scientific"}
    ]

    harvested_items = []
    seen_phrases = set()
    category_counts = collections.Counter()

    for dom in domains:
        print(f"\n[Harvester Stream] Extracting Hyland Metadiscourse from '{dom['name']}' ({dom['type']})...")
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
            if i >= 4000:
                break
                
            text_val = example.get(dom["field"], "")
            if not text_val and isinstance(example, dict):
                for k in ["abstract", "text", "dialog", "dialogue", "content"]:
                    if k in example and example[k]:
                        text_val = example[k]
                        if isinstance(text_val, list):
                            text_val = " ".join(text_val)
                        break

            text_str = str(text_val).strip()
            if len(text_str) < 15:
                continue

            for cat_name, pattern_list in HYLAND_PATTERNS.items():
                for pat in pattern_list:
                    matches = re.findall(pat, text_str)
                    for m in matches:
                        clean_m = m.lower().strip() if isinstance(m, str) else m[0].lower().strip()
                        if len(clean_m) <= 2 or clean_m in seen_phrases:
                            continue
                        seen_phrases.add(clean_m)
                        category_counts[cat_name] += 1
                        dataset_count += 1
                        harvested_items.append({
                            "phrase": clean_m,
                            "category": cat_name,
                            "domain": dom["type"],
                            "word_count": len(clean_m.split()),
                            "cloze_prompt": f"Metadiscourse [{cat_name}]: [BLANK] -> {clean_m}",
                            "target_phrase": clean_m
                        })

        print(f"[Harvester Stream] Harvested {dataset_count} unique metadiscourse attractors from {dom['name']}")

    os.makedirs("scratch", exist_ok=True)
    out_file = "scratch/mined_expanded_corpus_cloze.jsonl"
    with open(out_file, "w", encoding="utf-8") as f:
        for item in harvested_items:
            f.write(json.dumps(item) + "\n")

    print("\n================================================================================")
    print("  HYLAND METADISCOURSE HARVEST SUMMARY")
    print("================================================================================")
    print(f"  Total Metadiscourse Attractors Mined : {len(harvested_items)}")
    for cat, cnt in category_counts.most_common():
        print(f"    - Category '{cat}': {cnt} unique attractors")
    print(f"  Output File                          : {out_file}")
    print("================================================================================\n")

if __name__ == "__main__":
    harvest_hyland_metadiscourse()
