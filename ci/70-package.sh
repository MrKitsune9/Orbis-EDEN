#!/usr/bin/env bash
# build-eden/bin/eden-ps4 (ELF) -> out-eden/*.pkg. Linux version of package-eden.sh.
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$ROOT"
SDK="$SDK_ROOT/sdk"
OO="$ROOT/deps/OpenOrbis"
TITLE="NX on Orbis"; TITLE_ID="EDPS00001"
CID="IV0000-${TITLE_ID}_00-EDENPS4000000000"
ELF="${ELF:-$ROOT/build-eden/bin/eden-ps4}"
[ -f "$ELF" ] || ELF=$(find build-eden -name 'eden-ps4' -type f | head -1)
[ -f "$ELF" ] || { echo "ERROR: eden-ps4 ELF not found"; exit 1; }
ST="$ROOT/stage-eden"; OUT="$ROOT/out-eden"

# Host tools: the SDK's own, then OpenOrbis release assets.
find_tool() { find "$SDK_ROOT" "$ROOT/deps/oo-release" "$OO" -type f -iname "$1" 2>/dev/null | grep -i -v '\.exe$' | grep -i -E 'linux|/bin/' | head -1; }
FSELF=$(find_tool 'create-fself'); GP4=$(find_tool 'create-gp4'); PKGEXE=$(find_tool 'PkgTool.Core')
PKGDLL=$(find "$SDK_ROOT" "$ROOT/deps/oo-release" -type f -iname 'PkgTool.Core.dll' 2>/dev/null | head -1)
echo "create-fself: ${FSELF:-MISSING}"; echo "create-gp4:   ${GP4:-MISSING}"; echo "PkgTool:      ${PKGEXE:-${PKGDLL:-MISSING}}"
[ -n "$FSELF" ] && [ -n "$GP4" ] && { [ -n "$PKGEXE" ] || [ -n "$PKGDLL" ]; } \
  || { echo "ERROR: missing host tools; listing candidates"; find "$SDK_ROOT/sdk/bin" "$ROOT/deps/oo-release" -maxdepth 3 | head -60; exit 1; }
chmod +x "$FSELF" "$GP4" ${PKGEXE:+"$PKGEXE"} || true
pkgtool() { if [ -n "$PKGEXE" ]; then "$PKGEXE" "$@"; else dotnet "$PKGDLL" "$@"; fi; }

rm -rf "$ST"; mkdir -p "$ST/sce_sys/about" "$ST/sce_module" "$OUT"
python3 "$ROOT/probe/make-icon.py" "$ST/sce_sys/icon0.png" "NX"
"$FSELF" -in="$ELF" -out="$ST/x.oelf" --eboot "$ST/eboot.bin" --paid 0x3800000000000011
rm -f "$ST/x.oelf"
cp "$OO/samples/piglet/sce_sys/about/right.sprx" "$ST/sce_sys/about/"
cp "$OO/samples/piglet/sce_module/libc.prx" "$OO/samples/piglet/sce_module/libSceFios2.prx" "$ST/sce_module/"
mkdir -p "$ST/assets/misc"
cp "$ROOT/testroms/hbmenu.nro" "$ROOT/testroms/hbmenu-LICENSE.txt" "$ST/assets/misc/"
FILES="eboot.bin sce_sys/param.sfo sce_sys/icon0.png sce_sys/about/right.sprx sce_module/libc.prx sce_module/libSceFios2.prx assets/misc/hbmenu.nro assets/misc/hbmenu-LICENSE.txt"
(
    cd "$ST"
    SFO=sce_sys/param.sfo
    pkgtool sfo_new $SFO
    s() { pkgtool sfo_setentry $SFO "$1" --type "$2" --maxsize "$3" --value "$4"; }
    s APP_TYPE Integer 4 1; s APP_VER Utf8 8 "01.00"; s ATTRIBUTE Integer 4 0; s CATEGORY Utf8 4 gd
    s SYSTEM_VER Integer 4 0; s CONTENT_ID Utf8 48 "$CID"; s DOWNLOAD_DATA_SIZE Integer 4 0
    s TITLE Utf8 128 "$TITLE"; s TITLE_ID Utf8 12 "$TITLE_ID"; s VERSION Utf8 8 "01.00"
    "$GP4" -out pkg.gp4 --content-id="$CID" --files "$FILES"
    pkgtool pkg_build pkg.gp4 "$OUT"
)
mkdir -p "$ROOT/elf"
cp "$ELF" "$ROOT/elf/eden-ps4-$(date +%Y%m%d-%H%M).elf"
cp build-eden/eden-ps4-build-id.txt "$OUT/" 2>/dev/null || true
ls -la "$OUT"
