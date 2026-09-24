#!/bin/sh
# Builds hollow/hollow.z3 and copies it into the web player (docs/).
# Needs ZILF 1.9 (https://zilf.io). Set ZILF_BIN to its bin folder.
set -e
cd "$(dirname "$0")/.."
ZILF_BIN="${ZILF_BIN:-/d/Tools/zilf/bin}"
PY="${PYTHON:-python}"
"$PY" tools/make_engine.py
cd hollow
"$ZILF_BIN/zilf.exe" hollow.zil 2>&1 | grep -v "warning" || true

cd ..
mkdir -p docs
cp hollow/hollow.z3 docs/hollow.z3
echo "built docs/hollow.z3"
