# Morpheme Emission Tokenizer Plan

You've hit on the exact boundary between **Inflectional** and **Derivational** morphology, and fortunately, WordNet's architecture solves this elegantly!

### Suffixes (Inflectional Morphology)
Things like `-s`, `-ed`, and `-ing` do not change the core meaning of a word; they only change its grammatical role in the sequence.
- **Example**: `run` vs `running`.
- **NLTK Lemmatizer**: Maps `running` -> `run`. 
- **Our Strategy**: Emit `[coord("run"), coord("[PRESENT_PARTICIPLE]")]`. The Sequence Engine learns the grammar.

### Prefixes (Derivational Morphology)
Prefixes like `dis-`, `un-`, `a-`, and `en-` fundamentally change the semantic meaning of the word (e.g. from positive to negative). 
Because the semantic meaning changes, **WordNet natively stores these as entirely separate, unique lemmas!**
- **Example**: `agree` and `disagree` are distinct concepts in WordNet.
- **NLTK Lemmatizer**: Does **not** break these apart. `lemmatizer("disagree")` returns `"disagree"`.
- **Our Strategy**: The tokenizer will simply look up `"disagree"`. Since it is a valid, distinct WordNet lemma, it has its own unique 248D coordinate. The Sequence Engine learns the true semantic location of `"disagree"` rather than trying to math out `[UN] + [AGREE]`.

## Proposed Changes to `core/word_tokenizer.py`

1. **Hash Grammatical Suffix Primitives**: We will hash a few reserved tokens (`"[PLURAL]"`, `"[PAST_TENSE]"`, `"[PRESENT_PARTICIPLE]"`, `"[THIRD_PERSON_SINGULAR]"`) to represent grammatical transformations.
2. **Detect Inflectional Shifts**: During `encode()`, if a token is not in the DB, we check the lemmatizer.
   - If `lemmatizer("beans", pos='n') == "bean"`:
     - Emit the coordinate for `"bean"`.
     - Immediately emit the coordinate for `"[PLURAL]"`.
   - If `lemmatizer("running", pos='v') == "run"`:
     - Emit the coordinate for `"run"`.
     - Immediately emit the coordinate for `"[PRESENT_PARTICIPLE]"`.

## User Review Required

> [!NOTE]
> By leaning into WordNet's natural design, we use **Morpheme Emission** for grammar (suffixes), and **Unique Coordinates** for semantics (prefixes). 
> 
> Does this dual-strategy make sense for your vision of how GeoMind should process language? If so, approve this plan and I'll code it into `WordTokenizer`!
