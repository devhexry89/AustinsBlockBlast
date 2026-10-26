#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc AustinsBlockBlast/Core/GameCore.swift Tests/EngineSmoke.swift -o .build/engine-smoke
.build/engine-smoke
