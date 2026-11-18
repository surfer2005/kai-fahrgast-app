"""Wählt einen iPhone-Simulator auf dem Mac der GitHub-Prüfung: neueste iOS-Version, am liebsten „iPhone 16“ (6,1 Zoll)."""
import json
import re
import subprocess
import sys

daten = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))["devices"]
def version(laufzeit):
    m = re.search(r"iOS-(\d+)-(\d+)", laufzeit)
    return (int(m.group(1)), int(m.group(2))) if m else (0, 0)
for laufzeit in sorted((k for k in daten if "iOS" in k), key=version, reverse=True):
    iphones = [g for g in daten[laufzeit] if g["name"].startswith("iPhone")]
    if not iphones:
        continue
    bevorzugt = [g for g in iphones if g["name"] in ("iPhone 16", "iPhone 16 Pro", "iPhone 15")]
    wahl = (bevorzugt or iphones)[0]
    print(wahl["udid"])
    print(f"{wahl['name']} · {laufzeit.split('.')[-1]}", file=sys.stderr)
    sys.exit(0)
sys.exit("Kein iPhone-Simulator gefunden.")
