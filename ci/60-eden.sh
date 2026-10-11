#!/usr/bin/env bash
# Eden + patches, configure, build the eden-ps4 target (docs/BUILDING.md section 5).
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$ROOT"
STAMP=$(cat patches/eden/*.patch | sha256sum | cut -d' ' -f1)
if [ -d deps/eden ] && [ "$(cat deps/eden/.ps4-patch-stamp 2>/dev/null)" != "$STAMP" ]; then
    echo "patches changed since the cached Eden tree was made: refetching (ccache keeps unchanged objects)"
    rm -rf deps/eden build-eden
fi
if [ ! -d deps/eden ]; then
    step "fetch Eden and apply patches/eden/*.patch"
    bash scripts/fetch-eden.sh
    echo "$STAMP" > deps/eden/.ps4-patch-stamp
    git -C deps/eden log --oneline | head -5
fi
step "configure"
export CCACHE_DIR="$ROOT/.ccache" CCACHE_MAXSIZE=3G
ccache -z || true
if [ ! -f build-eden/build.ninja ]; then
    bash configure-eden.sh -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
fi
step "build (this is the long step)"
source tools/env-build.sh
unset OO_PS4_TOOLCHAIN
cmake --build build-eden --target eden-ps4 -j"$(nproc)"
ccache -s || true
ls -la build-eden/bin/ build-eden/eden-ps4* 2>/dev/null || find build-eden -maxdepth 2 -name 'eden-ps4*'
