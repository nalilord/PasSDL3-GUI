#!/usr/bin/env bash
set -euo pipefail

task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$task_root"
node Tools/check-unit-dependencies.js --self-test
node Tools/check-unit-dependencies.js
