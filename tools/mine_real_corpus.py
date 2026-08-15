#!/usr/bin/env python3
"""
tools/mine_real_corpus.py
True Phrase Mining Script for Real Text Corpora
Scans public domain literature, dialogue text files, and documentation corpora
Based on regex mining specification in docs/research/idea.txt
"""

import json
import re
import os
import glob
import sys

def load_target_phrases():
    idea_path = "docs/research/idea.txt"
    if not os.path.exists(idea_path):
        return []
    with open(idea_path, "r", encoding="utf-8") as f:
        text = f.read()

    lines = text.splitlines()
    phrases = []
    in_list = False
    for line in lines:
        line_s = line.strip()
        if "100 Most Statistically Common Noun-Noun Pairs" in line_s or "Binomial Non Reversible pairs" in line_s or "100 Most Common Short Functional Phrases" in line_s or "100 Structural & Functional Phrases" in line_s:
            in_list = True
            continue
        if in_list and line_s and not line_s.startswith("http") and not line_s.startswith("#") and not line_s.startswith("Some python") and not line_s.startswith("----------------"):
            clean_p = re.sub(r"^\d+[\.\)]\s*", "", line_s)
            if len(clean_p) > 2 and len(clean_p) < 60:
                phrases.append(clean_p)
    return sorted(list(set(phrases)), key=len, reverse=True)

def mine_from_corpus(corpus_files, phrases):
    mined_results = []
    pattern_str = r"\b(" + "|".join([re.escape(p) for p in phrases]) + r")\b"
    master_re = re.compile(pattern_str, re.IGNORECASE)

    for c_file in corpus_files:
        if not os.path.exists(c_file) or os.path.getsize(c_file) > 50 * 1024 * 1024:
            continue
        try:
            with open(c_file, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
        except Exception:
            continue

        sentences = re.split(r'(?<=[.!?])\s+', content)
        for sent in sentences:
            sent_clean = re.sub(r'\s+', ' ', sent.strip())
            if len(sent_clean) < 15 or len(sent_clean) > 300:
                continue

            matches = master_re.findall(sent_clean)
            if matches:
                for match_phrase in set(matches):
                    matched_regex = re.compile(rf"\b{re.escape(match_phrase)}\b", re.IGNORECASE)
                    
                    # Stage 1: Anchored Cloze Fill-in-the-Blank Bridge
                    mined_results.append({
                        "stage": 1,
                        "type": "anchored_cloze",
                        "source_file": c_file,
                        "phrase": match_phrase,
                        "raw_sentence": sent_clean,
                        "cloze_prompt": matched_regex.sub("[BLANK]", sent_clean),
                        "target_phrase": match_phrase
                    })

                    # Stage 2: Finish-the-Sentence Narrative Continuation
                    parts = matched_regex.split(sent_clean, 1)
                    if len(parts) == 2 and len(parts[1].strip()) > 5:
                        seed_prompt = parts[0] + match_phrase + " "
                        target_completion = parts[1].strip()
                        mined_results.append({
                            "stage": 2,
                            "type": "finish_the_sentence",
                            "source_file": c_file,
                            "phrase": match_phrase,
                            "seed_prompt": seed_prompt,
                            "target_completion": target_completion,
                            "reward": 1.0
                        })
    return mined_results

def main():
    phrases = load_target_phrases()
    print(f"[Real Phrase Miner] Loaded {len(phrases)} target phrases from docs/research/idea.txt.")

    corpus_files = glob.glob("scratch/movie_scripts/*.txt") + glob.glob("scratch/public_corpus/*.txt") + glob.glob("docs/**/*.md", recursive=True) + glob.glob("docs/**/*.txt", recursive=True) + glob.glob("*.md")
    print(f"[Real Phrase Miner] Scanning {len(corpus_files)} raw text files across scratch/movie_scripts/, scratch/public_corpus/, and docs/...")
    
    mined = mine_from_corpus(corpus_files, phrases)

    os.makedirs("scratch", exist_ok=True)
    out_file = "scratch/mined_real_corpus_cloze.jsonl"
    sym_file = "scratch/cloze_anchored_dataset.jsonl"

    with open(out_file, "w", encoding="utf-8") as f:
        for m in mined:
            f.write(json.dumps(m, ensure_ascii=False) + "\n")

    # Also mirror to scratch/cloze_anchored_dataset.jsonl for training driver
    with open(sym_file, "w", encoding="utf-8") as f:
        for m in mined:
            f.write(json.dumps(m, ensure_ascii=False) + "\n")

    print(f"================================================================================")
    print(f"  REAL CORPUS PHRASE MINER & CLOZE EXTRACTOR")
    print(f"================================================================================")
    print(f"[Real Phrase Miner] Successfully mined {len(mined)} genuine human sentences containing target phrases!")
    print(f"[Real Phrase Miner] Saved to: {out_file} and {sym_file}\n")

if __name__ == "__main__":
    main()
