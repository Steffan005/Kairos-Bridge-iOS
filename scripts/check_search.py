#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 Steffan Douglas Haskins
"""Synthetic native full-history, query and cancellation checks."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
sources = ['Models.swift', 'SessionVault.swift', 'KairosAPI.swift', 'JournalSearchModel.swift']
with tempfile.TemporaryDirectory(prefix='kairos-search-checks-') as directory:
    binary = Path(directory) / 'search-checks'
    subprocess.run(['swiftc', '-swift-version', '5', *[str(root/'Kairos'/n) for n in sources],
                    str(root/'checks/SearchChecks.swift'), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
