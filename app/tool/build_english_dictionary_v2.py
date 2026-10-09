"""Build familiar English vocabulary from a pinned, licensed offline snapshot.

No network or third-party packages are needed. --write updates generated files;
--check verifies exact reproduction. The default previews counts and exceptions.
"""
import argparse
from collections import Counter
import gzip
import hashlib
import json
from pathlib import Path
import re

POLICY_PATH = Path("assets/content/curation/english_v2_policy.json")
OUTPUT_PATH = Path("assets/content/generated/english_v2.json")
REPORT_PATH = Path("../reports/content/english_dictionary_v2.json")
SOURCE_PREFIX = "Simple English Wiktionary contributors (CC BY-SA 4.0); "
RISK = re.compile(
    r"\b(?:fuck\w*|shit\w*|cunt\w*|nigg\w*|fagg\w*|bitch\w*|bastard\w*|"
    r"whore\w*|slut\w*|piss\w*|porn\w*|sexual\w*|sex|penis|vagina|genital\w*|"
    r"masturbat\w*|prostitut\w*|rape|raping|rapist|incest|orgasm\w*|erotic|"
    r"suicid\w*|murder\w*|tortur\w*|kill\w*|weapon\w*|gun\w*|bomb\w*|"
    r"cocaine|heroin|marijuana|cannabis|tobacco|cigarette\w*|alcohol\w*|drunk\w*|"
    r"gambl\w*|racis\w*|slur\w*|offensive|vulgar|derogatory|insult\w*|"
    r"retard\w*|idiot\w*|stupid|imbecile\w*|heathen\w*|infidel\w*|"
    r"spank\w*|master[\s-]+bait\w*)\b", re.I)
BAD_TAG = re.compile(
    r"archaic|obsolete|dated|rare|offensive|vulgar|slang|derogatory|pejorative|"
    r"figurative|historical|old, no longer used|euphemism|humorous|nonstandard|initialism|abbreviation|"
    r"anatomy|pathology|military|sexual|medicine|law|finance", re.I)
REFERENCE = re.compile(
    r"^(?:the )?(?:(?:simple )?past(?: tense| participle)?|present participle|"
    r"plural|third.person|comparative|superlative|alternative|variant|another (?:way|word)|a spelling|"
    r"a form|contraction|abbreviation|acronym|initialism|short (?:form|for)|see)\b", re.I)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def clean_definition(word, gloss):
    """Only mechanical transformations; exact source gloss remains in evidence."""
    text = re.sub(r"\s+", " ", gloss).strip()
    # The first complete sentence avoids appended secondary senses and examples.
    text = re.split(r"(?<=[.!?])\s+(?=[A-Z])", text, maxsplit=1)[0]
    lemma = re.escape(word)
    # Basic noun definitions: 'An apple is a ...', 'Words are the ...'.
    text = re.sub(rf"^(?:(?:a|an|the) )?{lemma}(?:s|es)? (?:is|are|means) ", "", text, flags=re.I)
    # Basic adjective definitions preserve the predicate, without revealing the answer.
    text = re.sub(rf"^(?:something|someone|a person|somebody) (?:that |who )?"
                  rf"(?:is|feels) {lemma} (?:is|feels) ", "", text, flags=re.I)
    text = re.sub(rf"^(?:if|when) you (?:feel|are) {lemma}, you (?:feel|are) ", "", text, flags=re.I)
    # Verb patterns are deliberately narrow; arbitrary conditional text is held.
    text = re.sub(rf"^(?:if|when) you {lemma}(?: (?:something|someone|somebody))?, you ", "To ", text, flags=re.I)
    text = re.sub(r"^To do not ", "To not ", text)
    text = re.sub(r"^To don't ", "To not ", text)
    text = re.sub(r"\bit\b", "something", text) if text.startswith("To ") else text
    text = re.sub(r"\bthem\b", "someone", text) if text.startswith("To ") else text
    if text:
        text = text[0].upper() + text[1:]
    return text


def sense_problem(word, sense, text, maximum_length):
    if RISK.search(word) or RISK.search(sense["gloss"]):
        return "sensitive_word_or_sense"
    if BAD_TAG.search(" ".join(sense["tags"])):
        return "labelled_uncommon_or_specialist_sense"
    if REFERENCE.search(text):
        return "reference_or_inflected_form"
    if re.search(r"\b(?:sth|sb|sbdy)\b|^The (?:act|process) of \w+[.!]?$", text, re.I):
        return "unclear_definition"
    if re.search(r"section needs|needs someone|add to it|definition needed|entry needs|a something", text, re.I):
        return "source_maintenance_or_bad_grammar"
    if re.fullmatch(r"A(?:n)? (?:(?:type|kind|sort) of )?(?:fruit|vegetable|thing|animal|bird|insect|plant|colou?r)\.", text, re.I):
        return "definition_too_general"
    if len(text) < 8 or len(text) > maximum_length:
        return "definition_length"
    if re.search(rf"\b{re.escape(word)}(?:s|es)?\b", text, re.I):
        return "definition_reveals_answer"
    if re.search(r"\b(?:i\.e\.|e\.g\.|etc\.|wikipedia|wiktionary)\b|[\[\]{}]|\ufffd", text, re.I):
        return "unclear_definition"
    if re.match(r"^(?:if|when|this|it|they|these|those)\b", text, re.I):
        return "context_dependent_definition"
    return None


def build(snapshot, policy):
    entries, holds = [], []
    counts = Counter()
    exceptions = set(policy["familiarExceptions"])
    excluded = set(policy["excludedWords"])
    overrides = policy["definitionOverrides"]
    answer_holds = {}
    for reason, words in policy.get("answerHolds", {}).items():
        for word in words:
            if word in answer_holds:
                raise ValueError(f"Duplicate English answer hold: {word}")
            answer_holds[word] = reason
    for source in snapshot["entries"]:
        word, zipf = source["word"], source["zipf"]
        if word in excluded:
            counts["explicitlyExcluded"] += 1
            continue
        if zipf < policy["minimumZipf"] and word not in exceptions:
            counts["belowFrequencyThreshold"] += 1
            continue
        selected = None
        reasons = set()
        # Only the source's first leading sense may be selected automatically.
        # A failed adjective must not silently switch to an obscure noun (e.g.
        # FAMILIAR's magical pet). Specific alternatives need exact evidence.
        candidates = [s for s in source["senses"] if s["senseIndex"] == 0][:1]
        override = overrides.get(word)
        if override:
            candidates = [s for s in source["senses"] if s["gloss"] == override["sourceGloss"]]
            if not candidates:
                raise ValueError(f"Stale source-linked definition exception: {word}")
        for sense in candidates:
            definition = override["definition"] if override else clean_definition(word, sense["gloss"])
            reason = sense_problem(word, sense, definition, policy["maximumDefinitionCharacters"])
            if reason:
                reasons.add(reason)
                continue
            selected = (sense, definition)
            break
        if selected is None:
            holds.append({"word": word, "zipf": zipf, "reasons": sorted(reasons or {"no_base_sense"})})
            counts["held"] += 1
            continue
        sense, definition = selected
        entries.append({
            "id": f"en_v2_{word}", "language": "english", "latin": word.upper(),
            "gurmukhi": None, "definitions": {"en": [definition], "pa": []},
            "lengths": {"latin": len(word), "gurmukhi": None},
            "acceptedGuess": True,
            "solutionEligible": (zipf >= policy["minimumAnswerZipf"] or word in exceptions)
                                and word not in answer_holds,
            "reviewStatus": "machineChecked",
            "sources": [SOURCE_PREFIX + f"https://simple.wiktionary.org/wiki/{word}"],
            "evidence": {"sourceGloss": sense["gloss"], "partOfSpeech": sense["pos"],
                         "senseIndex": sense["senseIndex"], "frequencyZipf": zipf,
                         "frequencySource": "wordfreq 3.1.1 (CC BY-SA 4.0)",
                         "answerHold": answer_holds.get(word),
                         "method": "source-linked machine paraphrase" if override else "mechanical first-sense cleanup",
                         "sourceSnapshotSha256": snapshot["rawSha256"]},
        })
    entries.sort(key=lambda e: e["id"])
    report = {
        "schemaVersion": 2, "status": "machineChecked; no human review claimed",
        "policy": policy, "source": {k: v for k, v in snapshot.items() if k != "entries"},
        "counts": dict(sorted(counts.items())), "released": len(entries),
        "answers": sum(e["solutionEligible"] for e in entries),
        "lengthCounts": dict(sorted(Counter(len(e["latin"]) for e in entries).items())),
        "answerLengthCounts": dict(sorted(Counter(len(e["latin"]) for e in entries if e["solutionEligible"]).items())),
        "frequencyCounts": dict(sorted(Counter(str(int(e["evidence"]["frequencyZipf"])) for e in entries).items())),
        "holds": holds,
        "answerHoldCounts": dict(sorted(Counter(
            e["evidence"]["answerHold"] for e in entries if e["evidence"]["answerHold"]).items())),
        "answerHolds": [{"word": e["latin"], "reason": e["evidence"]["answerHold"],
                         "definition": e["definitions"]["en"][0],
                         "frequencyZipf": e["evidence"]["frequencyZipf"]}
                        for e in entries if e["evidence"]["answerHold"]],
        "sample": [{"word": e["latin"], "definition": e["definitions"]["en"][0],
                    "zipf": e["evidence"]["frequencyZipf"]}
                   for e in entries if e["latin"] in {"APPLE", "BOOK", "BREAD", "CHAIR", "DOOR", "HOME", "HAPPY", "MILK", "RAIN", "SCHOOL", "ELEPHANT", "BUTTERFLY", "MOUNTAIN", "WORD"}],
    }
    return entries, report


def main():
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    lock = read_json(Path("tool/content/english_v2_source_lock.json"))
    source = Path(lock["path"]).read_bytes()
    if hashlib.sha256(source).hexdigest() != lock["sha256"]:
        raise ValueError("English source snapshot does not match its lock.")
    snapshot = json.loads(gzip.decompress(source))
    entries, report = build(snapshot, read_json(POLICY_PATH))
    stale = []
    for path, data in [(OUTPUT_PATH, entries), (REPORT_PATH, report)]:
        encoded = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
        current = path.read_text(encoding="utf-8") if path.exists() else ""
        if current.replace("\r\n", "\n") != encoded:
            stale.append(str(path))
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(encoded, encoding="utf-8", newline="\n")
    print(json.dumps({k: report[k] for k in ["released", "answers", "answerLengthCounts", "counts", "sample"]}))
    if args.check and stale:
        raise ValueError("Stale English v2 files: " + ", ".join(stale))


if __name__ == "__main__":
    main()
