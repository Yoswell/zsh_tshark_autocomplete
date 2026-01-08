#!/usr/bin/env python3

from pathlib import Path

BASE_DIR = Path("tshark")
HEADINGS_FILE = BASE_DIR / "headings.txt"
FIELDS_FILE = BASE_DIR / "fields.txt"
OUTPUT_DIR = BASE_DIR / "fields"

OUTPUT_DIR.mkdir(exist_ok=True)

# Read all fields
with FIELDS_FILE.open() as f:
    fields = [line.strip() for line in f if line.strip()]

# Process headings one by one
with HEADINGS_FILE.open() as f:
    for line in f:
        heading = line.strip()
        if not heading:
            continue

        matched = [
            field for field in fields
            if field.startswith(heading + ".")
        ]

        # Create file only if there are fields
        if matched:
            output_file = OUTPUT_DIR / f"{heading}.txt"
            with output_file.open("w") as out:
                out.write("\n".join(matched) + "\n")

            print(f"✔ {heading}: {len(matched)} fields")
        else:
            print(f"✘ {heading}: no fields")
