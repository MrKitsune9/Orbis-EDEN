#!/usr/bin/env bash
# LLVM 18.1.8 libc++/libc++abi built for the PS4 into libcxx18/ (docs/BUILDING.md section 3).
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$ROOT"
if [ -f libcxx18/lib/libc++.a ] && [ -f libcxx18/include/c++/v1/__config_site ]; then echo "libcxx18 cached"; exit 0; fi
step "fetch llvm-project llvmorg-18.1.8 (sparse)"
if [ ! -d deps/llvm-project ]; then
    git clone --depth 1 --branch llvmorg-18.1.8 --filter=blob:none --sparse https://github.com/llvm/llvm-project.git deps/llvm-project
    git -C deps/llvm-project sparse-checkout set runtimes libcxx libcxxabi libunwind cmake llvm/cmake third-party
fi
step "patch libcxx/src/filesystem/operations.cpp (sendfile is FreeBSD's here)"
F=deps/llvm-project/libcxx/src/filesystem/operations.cpp
sed -n 25,60p "$F"
if ! grep -q "__ORBIS__" "$F"; then
    # the Linux sendfile condition near the top of the file
    ln=$(awk 'NR<120 && /__linux__/ {print NR; exit}' "$F")
    [ -n "$ln" ] || { echo "ERROR: could not find the __linux__ sendfile condition"; exit 1; }
    sed -i "${ln}s/defined(__linux__)/(defined(__linux__) \&\& !defined(__ORBIS__))/" "$F"
    sed -n "$((ln-2)),$((ln+3))p" "$F"
    grep -q "__ORBIS__" "$F" || { echo "ERROR: sendfile patch did not apply; edit $F by hand"; exit 1; }
fi
step "configure + build"
cmake -S deps/llvm-project/runtimes -B build-libcxx -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ROOT/toolchain/runtimes-ps4.cmake" -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
  -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXX_HAS_MUSL_LIBC=ON \
  -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=OFF \
  -DLIBCXXABI_USE_LLVM_UNWINDER=OFF -DLIBCXX_ENABLE_TIME_ZONE_DATABASE=OFF \
  -DLIBCXX_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_TESTS=OFF -DLIBCXX_INCLUDE_TESTS=OFF \
  -DLIBCXXABI_INCLUDE_TESTS=OFF -DCMAKE_INSTALL_PREFIX="$ROOT/libcxx18"
ninja -C build-libcxx install
echo '#undef __FreeBSD__' >> libcxx18/include/c++/v1/__config_site
ls libcxx18/lib
