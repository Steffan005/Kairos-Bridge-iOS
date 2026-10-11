#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 Steffan Douglas Haskins
"""Run synthetic model checks on macOS; not iOS SDK or physical-device acceptance."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
sources = ["Models.swift", "SessionVault.swift", "KairosAPI.swift", "KairosModel.swift"]
with tempfile.TemporaryDirectory(prefix="kairos-native-model-checks-") as directory:
    binary = Path(directory) / "model-checks"
    subprocess.run(["swiftc", "-swift-version", "5",
                    *[str(root / "Kairos" / name) for name in sources],
                    str(root / "checks/ModelChecks.swift"), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
