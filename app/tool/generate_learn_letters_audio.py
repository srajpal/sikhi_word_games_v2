"""Generate review-only Punjabi letter-name WAVs with local eSpeak NG 1.52.0.

Usage: python tool/generate_learn_letters_audio.py --espeak /path/to/espeak-ng
The data directory is assumed beside the executable. No runtime/network TTS.
"""
import argparse
from array import array
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import wave


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--espeak", type=Path, required=True)
    args = parser.parse_args()
    executable = args.espeak.resolve()
    app = Path(__file__).resolve().parents[1]
    source = app / "lib/features/learn_letters/domain/letter_entry.dart"
    content = source.read_text(encoding="utf-8")
    names_section = content.split("const _nativeNames = {", 1)[1].split("};", 1)[0]
    names = dict(re.findall(r"'([^']+)':\s*'([^']+)'", names_section))
    entries = re.findall(r"LetterEntry\('([^']+)',\s*'([^']+)',\s*'([^']+)'\)", content)
    if len(entries) != 35 or set(names) != {item[0] for item in entries}:
        raise ValueError("Expected 35 matching letter and native-name entries")
    destination = app / "assets/audio/learn_letters"
    destination.mkdir(parents=True, exist_ok=True)
    clips = []
    for letter_id, glyph, romanized in entries:
        output = destination / f"{letter_id}.wav"
        with tempfile.TemporaryDirectory() as temporary:
            text = Path(temporary) / "letter.txt"
            text.write_text(names[letter_id], encoding="utf-8")
            subprocess.run([
                str(executable), f"--path={executable.parent}",
                "-v", "pa", "-s", "125", "-p", "45", "-a", "100",
                "-f", str(text), "-w", str(output),
            ], cwd=executable.parent, check=True)
        with wave.open(str(output), "rb") as wav:
            duration = wav.getnframes() / wav.getframerate()
            if duration <= 0.1 or wav.getnchannels() != 1 or wav.getsampwidth() != 2:
                raise ValueError(f"Invalid audio for {letter_id}")
            peak = max(abs(value) for value in array("h", wav.readframes(wav.getnframes())))
            if peak < 100 or peak >= 32767:
                raise ValueError(f"Silent or clipped audio for {letter_id}")
        clips.append({"id": letter_id, "letter": glyph, "romanized": romanized,
                      "spokenText": names[letter_id], "file": f"assets/audio/learn_letters/{letter_id}.wav",
                      "durationSeconds": round(duration, 3),
                      "peakAmplitude16Bit": peak,
                      "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
                      "reviewStatus": "unreviewed_generated_preview"})
    manifest = {
        "purpose": "User pronunciation review; not human-approved teaching audio",
        "generator": "eSpeak NG", "generatorVersion": "1.52.0", "voice": "pa",
        "voiceLanguage": "Punjabi", "rateWordsPerMinute": 125, "pitch": 45,
        "generatorSource": "https://github.com/espeak-ng/espeak-ng/releases/tag/1.52.0",
        "generatorLicense": "GPL-3.0-or-later; generator binary is not distributed with app",
        "generatorLicenseSource": "https://github.com/espeak-ng/espeak-ng/blob/1.52.0/COPYING",
        "outputLicenseNote": "GPLv3 section 2 distinguishes output from the program itself; this is not a blanket assertion of audio rights clearance.",
        "audioRightsStatus": "Generated from project letter-name text; publication review pending",
        "letterNameReference": "https://www.learnpunjabi.org/intro1.asp",
        "notes": "Synthetic robotic previews. No audio copied from the teaching reference. Fluent Punjabi review required for every clip before claiming verified pronunciation.",
        "clips": clips,
    }
    (app / "tool/learn_letters_audio_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated {len(clips)} Punjabi preview WAVs ({sum((destination / (c['id'] + '.wav')).stat().st_size for c in clips)} bytes)")


if __name__ == "__main__":
    main()
