#!/usr/bin/env bash
# The scripts were written for one Windows/Git Bash machine; point them at this Linux checkout.
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$ROOT"
step "rewrite Windows paths"
mkdir -p "$TOOLS/llvm" "$TOOLS/OpenOrbis/OpenOrbis"
ln -sfn /usr/lib/llvm-18/bin "$TOOLS/llvm/bin"
files=$(grep -rlE "(C:|/c)/Users/alejo" --include=*.sh --include=*.cmake . | grep -v '^./ci/' || true)
for f in $files; do
    sed -i 's/\r$//' "$f"
    sed -i -e "s#C:/Users/alejo/eden-ps4#$ROOT#g" -e "s#/c/Users/alejo/eden-ps4#$ROOT#g" \
           -e "s#C:/Users/alejo/soh-ps4/tools#$TOOLS#g" -e "s#/c/Users/alejo/soh-ps4/tools#$TOOLS#g" "$f"
    echo "patched $f"
done
sed -i 's/\.exe"/"/g' toolchain/runtimes-ps4.cmake
grep -n "clang\|llvm-ar\|llvm-ranlib" toolchain/runtimes-ps4.cmake | head
find . -name '*.sh' -exec sed -i 's/\r$//' {} +
