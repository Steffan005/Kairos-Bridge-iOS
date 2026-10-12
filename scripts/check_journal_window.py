#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 Steffan Douglas Haskins
"""Check the actual display model against a private existing journal snapshot."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
if len(sys.argv) != 2:
    raise SystemExit("Supply a private journal snapshot path")
with tempfile.TemporaryDirectory(prefix="kairos-window-checks-") as directory:
    binary = Path(directory) / "window-checks"
    subprocess.run(["swiftc", "-swift-version", "5", str(root / "Kairos/Models.swift"),
                    str(root / "checks/JournalWindowChecks.swift"), "-o", str(binary)], check=True)
    subprocess.run([str(binary), sys.argv[1]], check=True)
