#!/usr/bin/env python3
"""
tools/download_public_corpus.py
Downloads open-source public domain text corpora (Gutenberg classic prose & dialogue corpora)
for high-volume regex phrase mining into scratch/public_corpus/
"""

import os
import sys
import urllib.request

CORPUS_URLS = [
    # Classic English Literature & Dialogues (Public Domain Project Gutenberg)
    ("https://www.gutenberg.org/files/1342/1342-0.txt", "pride_and_prejudice.txt"),
    ("https://www.gutenberg.org/files/11/11-0.txt", "alice_in_wonderland.txt"),
    ("https://www.gutenberg.org/files/84/84-0.txt", "frankenstein.txt"),
    ("https://www.gutenberg.org/files/2701/2701-0.txt", "moby_dick.txt"),
    ("https://www.gutenberg.org/files/1661/1661-0.txt", "sherlock_holmes.txt"),
    ("https://www.gutenberg.org/files/1250/1250-0.txt", "anthem.txt"),
    ("https://www.gutenberg.org/files/74/74-0.txt", "tom_sawyer.txt"),
    ("https://www.gutenberg.org/files/76/76-0.txt", "huckleberry_finn.txt"),
    ("https://www.gutenberg.org/files/345/345-0.txt", "dracula.txt"),
    ("https://www.gutenberg.org/files/1400/1400-0.txt", "great_expectations.txt")
]

def download_corpus():
    target_dir = os.path.join("scratch", "public_corpus")
    os.makedirs(target_dir, exist_ok=True)
    downloaded_files = []

    print("================================================================================")
    print("  PUBLIC DOMAIN TEXT CORPUS DOWNLOADER")
    print("================================================================================")

    for url, filename in CORPUS_URLS:
        out_path = os.path.join(target_dir, filename)
        if os.path.exists(out_path) and os.path.getsize(out_path) > 10000:
            print(f"[Corpus Downloader] Cached: {filename}")
            downloaded_files.append(out_path)
            continue

        try:
            print(f"[Corpus Downloader] Fetching: {url} -> {filename}...")
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=15) as response:
                content = response.read().decode('utf-8', errors='ignore')
                with open(out_path, "w", encoding="utf-8") as f:
                    f.write(content)
            print(f"[Corpus Downloader] Successfully saved {filename} ({len(content)} bytes).")
            downloaded_files.append(out_path)
        except Exception as e:
            print(f"[Corpus Downloader] Error fetching {filename}: {e}")

    return downloaded_files

if __name__ == "__main__":
    download_corpus()
