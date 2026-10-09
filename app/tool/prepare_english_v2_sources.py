"""Prepare the small, attributed source snapshot used by the offline importer.

Deliberate source refresh only: requires wordfreq==3.1.1 and the locked raw
Kaikki Simple English JSONL gzip. The normal build needs only Python stdlib.
"""
import argparse
import gzip
import hashlib
import importlib.metadata
import json
from pathlib import Path
import re


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    args = parser.parse_args()
    from wordfreq import zipf_frequency
    if importlib.metadata.version("wordfreq") != "3.1.1":
        raise ValueError("Use the pinned wordfreq==3.1.1")
    raw_hash = hashlib.sha256(args.source.read_bytes()).hexdigest()
    if raw_hash != "ea4342525a35eb32e70f5d9945398f06d4f6160af25b0c340fc84662d27efcdf":
        raise ValueError("Source changed. Review the new dump and update the pin deliberately.")
    words = {}
    with gzip.open(args.source, "rt", encoding="utf-8") as source:
        for line in source:
            record = json.loads(line)
            word = record.get("word", "")
            if (not re.fullmatch(r"[a-z]{3,12}", word)
                    or record.get("pos") not in {"noun", "verb", "adj", "adv"}):
                continue
            item = words.setdefault(word, {
                "word": word, "zipf": zipf_frequency(word, "en"), "senses": []})
            for index, sense in enumerate(record.get("senses", [])):
                for gloss in sense.get("glosses", []):
                    item["senses"].append({
                        "pos": record["pos"], "senseIndex": index, "gloss": gloss,
                        "tags": sorted(set(sense.get("tags", []) + sense.get("raw_tags", []))),
                    })
    snapshot = {
        "schemaVersion": 2,
        "license": "CC BY-SA 4.0",
        "licenseUrl": "https://creativecommons.org/licenses/by-sa/4.0/",
        "dictionary": "Simple English Wiktionary contributors; Kaikki/Wiktextract extraction",
        "sourceUrl": "https://kaikki.org/simplewiktionary/raw-wiktextract-data.jsonl.gz",
        "dumpDate": "2026-09-01", "extractionDate": "2026-10-02", "rawSha256": raw_hash,
        "frequency": "wordfreq 3.1.1, Robyn Speer; English large word list; CC BY-SA 4.0",
        "frequencyUrl": "https://github.com/rspeer/wordfreq",
        "attribution": "See app/THIRD_PARTY_NOTICES.txt for the full retained source credits.",
        "changes": "Lowercase 3-12 letter noun/verb/adjective/adverb senses extracted; examples omitted; wordfreq Zipf scores added.",
        "entries": [words[word] for word in sorted(words)],
    }
    output = Path("tool/content/sources/english_v2_source.json.gz")
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(snapshot, ensure_ascii=False, separators=(",", ":")).encode()
    output.write_bytes(gzip.compress(payload, mtime=0))
    lock = {"path": str(output).replace("\\", "/"),
            "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
            "rawSha256": raw_hash, "sourceUrl": snapshot["sourceUrl"],
            "license": snapshot["license"], "frequencyVersion": "3.1.1"}
    Path("tool/content/english_v2_source_lock.json").write_text(
        json.dumps(lock, indent=2) + "\n", encoding="utf-8")
    print(f"Prepared {len(words)} source words, {output.stat().st_size} bytes.")


if __name__ == "__main__":
    main()
