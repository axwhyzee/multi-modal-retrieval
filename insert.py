from pathlib import Path

import requests


ASSERT_DIR = Path("assets")
USER = "axwhyzee"

for path in ASSERT_DIR.iterdir():
    print(f"Inserting {path}")
    with open(path, "rb") as f:
        r = requests.post(
            "http://localhost:5001/add",
            files={"file": f},
            data={"user": USER},
        )
        print(r.text)
