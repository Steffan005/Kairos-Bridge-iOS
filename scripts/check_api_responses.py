#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 Steffan Douglas Haskins
"""Check the real API client with synthetic HTTP callbacks and injected storage."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
sources = ["Models.swift", "SessionVault.swift", "KairosAPI.swift", "KairosModel.swift", "JournalSearchModel.swift"]
with tempfile.TemporaryDirectory(prefix="kairos-api-response-checks-") as directory:
    binary = Path(directory) / "api-response-checks"
    subprocess.run(["swiftc", "-swift-version", "5",
                    *[str(root / "Kairos" / name) for name in sources],
                    str(root / "checks/APIResponseChecks.swift"), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
