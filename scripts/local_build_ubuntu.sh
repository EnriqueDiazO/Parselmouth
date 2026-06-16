#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "pyproject.toml" || ! -f "CMakeLists.txt" || ! -d "src" ]]; then
  echo "Run this script from the Parselmouth repository root." >&2
  exit 1
fi

missing=0
for required in \
  "extern/fmt/CMakeLists.txt" \
  "pybind11/CMakeLists.txt" \
  "praat/CMakeLists.txt"; do
  if [[ ! -f "$required" ]]; then
    echo "Missing required source file: $required" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "Try: git submodule update --init --recursive" >&2
  exit 1
fi

if [[ ! -d ".venv" ]]; then
  python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate

python -m pip install --upgrade pip setuptools wheel
python -m pip install -v .

python - <<'PY'
import parselmouth

print("parselmouth file:", parselmouth.__file__)
print("Parselmouth version:", parselmouth.VERSION)
print("Praat version:", parselmouth.PRAAT_VERSION)
PY
