#!/usr/bin/env bash
# OpenSSL 3.6.2 and FFmpeg c7b5f1537d for the PS4 into prefix/ (docs/BUILDING.md section 4).
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$ROOT"
source tools/env-build.sh
mkdir -p deps prefix tmp
export TMPDIR="$ROOT/tmp"
if [ ! -f prefix/lib/libcrypto.a ]; then
    step "OpenSSL 3.6.2"
    [ -d deps/openssl-3.6.2 ] || { curl -fL -o deps/openssl.tgz https://github.com/openssl/openssl/releases/download/openssl-3.6.2/openssl-3.6.2.tar.gz; tar -xzf deps/openssl.tgz -C deps; }
    cd deps/openssl-3.6.2
    CFLAGS="$PS4_CFLAGS" CC=clang AR=llvm-ar RANLIB=llvm-ranlib perl Configure linux-x86_64-clang \
      no-shared no-tests no-apps no-docs no-dso no-async no-afalgeng no-engine no-ui-console \
      no-secure-memory no-module --with-rand-seed=devrandom --prefix="$ROOT/prefix" --libdir=lib \
      --openssldir=/app0/ssl
    make -j"$(nproc)" build_libs
    make install_dev
    cd "$ROOT"
fi
if [ ! -f prefix/lib/libavcodec.a ]; then
    step "FFmpeg"
    if [ ! -d deps/ffmpeg ]; then
        git clone --filter=blob:none https://github.com/FFmpeg/FFmpeg.git deps/ffmpeg
        git -C deps/ffmpeg checkout c7b5f1537d
    fi
    mkdir -p deps/build-ffmpeg && cd deps/build-ffmpeg
    ../ffmpeg/configure --prefix="$ROOT/prefix" --enable-cross-compile --arch=x86_64 --target-os=freebsd \
      --host-cc=gcc --host-ld=gcc \
      --cc="bash $ROOT/tools/ps4-cc.sh" --ld="bash $ROOT/tools/ps4-cc.sh" --ar=llvm-ar --ranlib=llvm-ranlib \
      --nm=llvm-nm --disable-x86asm --disable-autodetect --disable-everything --disable-programs --disable-doc \
      --disable-avdevice --disable-avformat --disable-network --disable-swresample \
      --enable-decoder='h264,vp8,vp9' --enable-filter='yadif,scale' --enable-pic --enable-pthreads \
      --disable-shared --enable-static
    make -j"$(nproc)"
    make install
    cd "$ROOT"
fi
ls prefix/lib
