#!/usr/bin/env python3

import json
import yaml
import sys

docs = []
for doc in yaml.safe_load_all(sys.stdin.read()):
    if doc:
        docs.append(doc)

print(json.dumps(docs, indent=4, sort_keys=True))

