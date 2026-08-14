#!/usr/bin/env python3
"""
tools/cloze_phrase_miner.py
Automated Phrase Mining & Anchored Cloze / Finish-the-Sentence Dataset Generator
Based on docs/research/idea.txt research specification.
"""

import json
import re
import os
import sys

# Categorized Functional Phrase Libraries from docs/research/idea.txt
NOUN_PAIRS = [
    "Health care", "Ice cream", "Web page", "Cell phone", "Credit card",
    "High school", "Social media", "Real estate", "Data base", "Water bottle",
    "Phone number", "Car insurance", "Home page", "Coffee shop", "Air conditioner",
    "Movie theater", "Room temperature", "Life insurance", "Post office", "Income tax",
    "Gas station", "Blood pressure", "Climate change", "Customer service", "Human rights",
    "Capital gains", "Heart attack", "Computer science", "Case study", "Board game"
]

BINOMIAL_PAIRS = [
    "Law and order", "Bread and butter", "Life and death", "Men and women", "Mom and dad",
    "Ladies and gentlemen", "Body and soul", "Trial and error", "Profit and loss", "Supply and demand",
    "Cause and effect", "Lock and key", "Fish and chips", "Salt and pepper", "Knife and fork",
    "Leaps and bounds", "Thunder and lightning", "Time and tide", "Flesh and blood", "Skin and bones",
    "Black and white", "Safe and sound", "Short and sweet", "Loud and clear", "Alive and well",
    "Give and take", "Live and learn", "Pick and choose", "Wait and see", "Cease and desist",
    "Back and forth", "Up and down", "In and out", "On and off", "Now and then", "By and large"
]

FUNCTIONAL_PHRASES = [
    "Thank you", "You're welcome", "Excuse me", "Good morning", "How are you?",
    "Nice to meet you", "See you later", "Have a good day", "Take care", "No problem",
    "By the way", "As a matter of fact", "In other words", "To be honest", "At the end of the day",
    "For example", "First of all", "On the other hand", "In my opinion", "As far as I know",
    "To tell you the truth", "Believe it or not", "Long story short", "All in all", "In the meantime",
    "Of course", "I agree", "No way", "Fair enough", "I suppose so", "Absolutely", "You're right",
    "I want to", "I would like to", "Can you help me?", "Hold on a second", "Let me know",
    "What's up?", "That's awesome", "I'm so sorry", "Good luck", "Calm down", "Don't give up"
]

TRANSITION_MARKERS = [
    "As previously mentioned", "In contrast to", "On the contrary", "Moving on to",
    "With that being said", "Simultaneously", "As a result", "Consequently", "Subsequently",
    "Historically speaking", "In general terms", "Broadly speaking", "More specifically",
    "In particular", "On a related note", "By extension", "To illustrate", "For instance",
    "In essence", "Fundamentally speaking", "It is important to note", "Given the circumstances",
    "In all likelihood", "There is no doubt that", "It goes without saying", "It is worth mentioning",
    "Taking into account", "All things considered", "Based on the data", "By definition",
    "Strictly speaking", "To a certain extent", "In reality", "On the surface", "Deep down",
    "At first glance", "Upon further inspection", "As far as I'm concerned", "Don't get me wrong",
    "If you think about it", "As you can see", "To wrap things up", "In a nutshell",
    "Suffice it to say", "Needless to say", "That is to say", "To put it simply", "Simply put",
    "Bottom line is", "As long as", "Provided that", "Unless otherwise specified", "No matter what"
]

ALL_PHRASES = NOUN_PAIRS + BINOMIAL_PAIRS + FUNCTIONAL_PHRASES + TRANSITION_MARKERS

def build_cloze_dataset():
    """Generates Stage 1 Anchored Cloze (Fill-in-the-Blank) training pairs."""
    cloze_entries = []
    
    # Template generators for Cloze training
    templates = [
        ("The initial conditions were unclear. [BLANK], the outcome exceeded expectations.", "In other words"),
        ("We searched for hours. [BLANK], we found the solution right in front of us.", "Long story short"),
        ("The project faced severe constraints. [BLANK], the team delivered on schedule.", "On the other hand"),
        ("The initial data was promising. [BLANK], the team proceeded with deployment.", "As a result"),
        ("We discussed the requirements. [BLANK], we agreed on the implementation plan.", "At the end of the day"),
        ("The system encountered an error. [BLANK], the fallback mechanism kicked in.", "All of a sudden"),
        ("The codebase is growing rapidly. [BLANK], code quality remains our top priority.", "With that being said"),
        ("We evaluated multiple options. [BLANK], option A proved to be the most efficient.", "First of all")
    ]

    for setup, anchor in templates:
        cloze_entries.append({
            "stage": 1,
            "type": "anchored_cloze",
            "prompt": setup,
            "target": anchor,
            "full_context": setup.replace("[BLANK]", anchor)
        })

    # Stage 2: Finish-the-Sentence Narrative Continuations
    continuation_templates = [
        ("The room was quiet. All of a sudden, ", "the alarms began to blare and the lights cut out."),
        ("The company was facing insolvency. In other words, ", "they were completely broke and needed immediate restructuring."),
        ("We missed our flight and lost our luggage. Long story short, ", "we eventually made it to the destination safety."),
        ("The initial test run failed. On the other hand, ", "the second trial yielded perfect accuracy across all benchmarks."),
        ("We reviewed all available metrics. At the end of the day, ", "the evidence supported our original hypothesis.")
    ]

    for prompt_prefix, completion in continuation_templates:
        cloze_entries.append({
            "stage": 2,
            "type": "finish_the_sentence",
            "prompt": prompt_prefix,
            "target": completion,
            "full_context": prompt_prefix + completion
        })

    return cloze_entries

def main():
    os.makedirs("scratch", exist_ok=True)
    dataset = build_cloze_dataset()
    out_file = "scratch/cloze_anchored_dataset.jsonl"
    
    with open(out_file, "w", encoding="utf-8") as f:
        for entry in dataset:
            f.write(json.dumps(entry) + "\n")

    print(f"[Cloze Phrase Miner] Generated {len(dataset)} Anchored Cloze & Finish-the-Sentence entries.")
    print(f"[Cloze Phrase Miner] Saved to: {out_file}")
    print(f"[Cloze Phrase Miner] Total Phrase Vocabulary Index Size: {len(ALL_PHRASES)} items.")

if __name__ == "__main__":
    main()
