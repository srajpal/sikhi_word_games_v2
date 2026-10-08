"""Query OSV for the public package versions in pubspec.lock (Python stdlib)."""
import datetime
import hashlib
import json
from pathlib import Path
import re
import urllib.request


def main():
    root = Path(__file__).resolve().parents[2]
    lock = root / "app/pubspec.lock"
    content = lock.read_bytes()
    packages = []
    for match in re.finditer(r"^  ([a-zA-Z0-9_]+):\n(.*?)(?=^  [a-zA-Z0-9_]+:|\Z)",
                             content.decode().replace("\r\n", "\n"), re.M | re.S):
        name, block = match.groups()
        if not re.search(r"^    source: hosted$", block, re.M):
            continue
        version = re.search(r'^    version: "([^"\n]+)"$', block, re.M)
        if not version:
            raise ValueError(f"Missing hosted version for {name}")
        packages.append({"package": {"name": name, "ecosystem": "Pub"},
                         "version": version.group(1)})
    if not packages:
        raise ValueError("No hosted packages found; audit is incomplete.")
    findings = [[] for _ in packages]
    pending = list(enumerate(packages))
    while pending:
        request = urllib.request.Request(
            "https://api.osv.dev/v1/querybatch",
            data=json.dumps({"queries": [query for _, query in pending]}).encode(),
            headers={"Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(request, timeout=60) as response:
            results = json.load(response)["results"]
        if len(results) != len(pending):
            raise ValueError("OSV response count does not match the query.")
        next_pending = []
        for (index, query), result in zip(pending, results):
            findings[index].extend(result.get("vulns", []))
            if result.get("next_page_token"):
                next_pending.append((index, {**query, "page_token": result["next_page_token"]}))
        pending = next_pending
    report = {
        "checkedAtUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "source": "https://api.osv.dev/v1/querybatch",
        "lockfileSha256": hashlib.sha256(content).hexdigest(),
        "packageCount": len(packages),
        "vulnerabilityCount": sum(map(len, findings)),
        "scope": "Hosted Pub packages only. Flutter SDK, native SDKs and unpublished issues are not covered.",
        "packages": [{**query, "vulnerabilities": found}
                     for query, found in zip(packages, findings)],
    }
    destination = root / "reports/security/dependency_audit.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"OSV: {len(packages)} hosted packages, {report['vulnerabilityCount']} known advisories.")
    if report["vulnerabilityCount"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
