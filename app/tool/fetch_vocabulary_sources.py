"""Fetch only the locked public source bytes into the ignored tool cache."""

import hashlib
import io
import json
from pathlib import Path
from urllib.request import urlopen
from zipfile import ZipFile


def fetch_sources():
    app = Path(__file__).resolve().parent.parent
    cache = (app / ".dart_tool/vocabulary_sources").resolve()
    lock = json.loads((app / "tool/content/source_lock.json").read_text("utf-8-sig"))
    expected = lock["files"]
    if all((app / path).is_file() and
           hashlib.sha256((app / path).read_bytes()).hexdigest() == digest
           for path, digest in expected.items()):
        print("Pinned vocabulary source cache already verified.")
        return
    pending = {}
    for source in lock["sources"]:
        with urlopen(source["url"], timeout=90) as response:
            data = response.read()
        if "archivePrefix" in source:
            if hashlib.sha256(data).hexdigest() != source["sha256"]:
                raise ValueError("Source archive checksum mismatch: " + source["name"])
            with ZipFile(io.BytesIO(data)) as archive:
                for name in archive.namelist():
                    if name.endswith("/"):
                        continue
                    path = source["archivePrefix"] + name
                    if path not in expected:
                        raise ValueError("Unexpected source archive member: " + name)
                    pending[path] = archive.read(name)
        else:
            pending[source["path"]] = data
    if set(pending) != set(expected):
        raise ValueError("Incomplete source download")
    # Verify every byte and destination before writing any cache file.
    for path, data in pending.items():
        if not (app / path).resolve().is_relative_to(cache):
            raise ValueError("Source path leaves the tool cache")
        if hashlib.sha256(data).hexdigest() != expected[path]:
            raise ValueError("Source file checksum mismatch: " + path)
    for path, data in pending.items():
        target = app / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    print(f"Fetched and verified {len(pending)} pinned vocabulary source files.")


if __name__ == "__main__":
    fetch_sources()
