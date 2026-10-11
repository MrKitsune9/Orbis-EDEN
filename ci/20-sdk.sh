#!/usr/bin/env bash
# orbis-sdk-v1 (Mesa RADV for the PS4, orbis-compat) and the OpenOrbis toolchain.
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$ROOT"
mkdir -p sdk-dl/dl deps

step "orbis-sdk-v1"
if [ ! -f "$SDK_ROOT/toolchain/orbis-sdk.cmake" ]; then
    gh release view orbis-sdk-v1 -R orbis-ports/orbis-porting-kit --json assets -q '.assets[] | "\(.name)  \(.size)"'
    gh release download orbis-sdk-v1 -R orbis-ports/orbis-porting-kit -D sdk-dl/dl --clobber
    ls -la sdk-dl/dl
    cd sdk-dl/dl
    for a in *; do
        case "$a" in
            *.zip) unzip -q -o "$a" -d ../x ;;
            *.tar.gz|*.tgz|*.tar.xz|*.tar.zst|*.tar) tar -xf "$a" -C ../x 2>/dev/null || { mkdir -p ../x; tar -xf "$a" -C ../x; } ;;
            *.7z) 7z x -y -o../x "$a" >/dev/null ;;
            *) echo "skipping $a" ;;
        esac
    done
    cd "$ROOT"
    cmake_file=$(find sdk-dl/x -path '*/toolchain/orbis-sdk.cmake' | head -1)
    [ -n "$cmake_file" ] || { echo "ERROR: orbis-sdk.cmake not found in the SDK download"; find sdk-dl/x -maxdepth 3 | head -50; exit 1; }
    found=$(cd "$(dirname "$cmake_file")/.." && pwd)
    ln -sfn "$found" "$SDK_ROOT"
fi
echo "SDK at $(readlink -f "$SDK_ROOT")"
ls "$SDK_ROOT"
for p in sdk/lib/crt1.o orbis-compat/cmake/orbis-tls.ld toolchain/orbis-sdk.cmake; do
    [ -e "$SDK_ROOT/$p" ] || { echo "ERROR: SDK is missing $p"; exit 1; }
done
ls "$SDK_ROOT/orbis-compat/build/liborbis-compat.a" || echo "WARNING: liborbis-compat.a is not prebuilt (tools/ps4-cc.sh needs it)"
echo "--- host tool dirs in the SDK:"; find "$SDK_ROOT/sdk/bin" -maxdepth 2 | head -30
echo "--- Linux handling in ps4-openorbis.cmake:"; grep -n -i "linux\|WIN32\|APPLE\|BINDIR" "$SDK_ROOT/orbis-compat/cmake/ps4-openorbis.cmake" | head -20 || true

step "OpenOrbis toolchain 0.5.4 (samples + host tools)"
if [ ! -d deps/OpenOrbis ]; then
    git clone --depth 1 --branch v0.5.4 https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain.git deps/OpenOrbis \
      || git clone --depth 1 https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain.git deps/OpenOrbis
fi
mkdir -p deps/oo-release
gh release download v0.5.4 -R OpenOrbis/OpenOrbis-PS4-Toolchain -D deps/oo-release --clobber \
  || gh release download -R OpenOrbis/OpenOrbis-PS4-Toolchain -D deps/oo-release --clobber || echo "no OpenOrbis release assets"
ls -la deps/oo-release || true
for a in deps/oo-release/*; do
    case "$a" in
        *.zip) unzip -q -o "$a" -d deps/oo-release/x ;;
        *.tar.gz|*.tgz) mkdir -p deps/oo-release/x; tar -xf "$a" -C deps/oo-release/x ;;
    esac
done
ln -sfn "$ROOT/deps/OpenOrbis" "$TOOLS/OpenOrbis/OpenOrbis/PS4Toolchain"
ls deps/OpenOrbis/samples/piglet/sce_module/ || { echo "ERROR: samples/piglet modules not found"; exit 1; }
