# source this: tools for building C deps (OpenSSL, FFmpeg...) for the PS4 from Git Bash
P=/c/nxorbis/repo/tools/msys-perl/usr
export PERL5LIB=$P/share/perl5/core_perl:$P/lib/perl5/core_perl
export PATH="/c/nxorbis/repo/tools/bin:$P/bin:/c/nxorbis/repo/tools/usr/bin:/c/nxorbis/tools/llvm/bin:/c/nxorbis/tools/cmake-4.4.3-windows-x86_64/bin:/c/nxorbis/tools/ninja:/c/nxorbis/tools/glslang/bin:$PATH"
export PS4_SDK=C:/nxorbis/repo/sdk-dl/orbis-sdk-v1/sdk
export PS4_COMPAT=C:/nxorbis/repo/sdk-dl/orbis-sdk-v1/orbis-compat
export PS4_OVERLAY=C:/nxorbis/repo/toolchain/include-overlay
export PS4_PREFIX=C:/nxorbis/repo/prefix
export PS4_CFLAGS="--target=x86_64-pc-freebsd12-elf -O2 -fPIC -funwind-tables -D__PS4__ -D__ORBIS__ -D_BSD_SOURCE=1 -U__FreeBSD__ -isysroot $PS4_SDK -isystem $PS4_OVERLAY -isystem $PS4_COMPAT/include -isystem $PS4_SDK/include -include orbis_prefix.h"
