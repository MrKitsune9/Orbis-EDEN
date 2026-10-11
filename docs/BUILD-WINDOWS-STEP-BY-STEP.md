# Build the NX on Orbis PKG on Windows, step by step (v2)

Use the project in **`nx-on-orbis-continued.zip`**. It already contains everything: the original
v0.1.0 sources, patches 0028 (color experiment) and 0029 (stability), the updated `frontend/`
(color switch `a2b10=sample|write`, base-PS4 hardware log), the build scripts and the docs.
You do **not** need to copy or merge any other patch or file from earlier zips.

(Resumo em português: este guia compila o `.pkg` no Windows usando o Git Bash. Todos os
caminhos usam a mesma estrutura de pastas, então basta copiar e colar os comandos.)

**Honest note:** this guide is written from the project's own `docs/BUILDING.md` and scripts. Its
author could not run the build, so a step may need a small fix. If something fails, copy the
**exact error and the step number** and send it back: most problems are a wrong path or a tool in
the wrong folder. A first full build takes roughly 1-3 hours, mostly unattended.

Needs: Windows 10/11, ~40 GB free disk, internet. 16 GB RAM is recommended; see **Low RAM** below if
the PC has less. All commands are for **Git Bash** (comes with "Git for Windows", https://git-scm.com).

**Do not have time or RAM?** The same project builds on GitHub's servers with no installs on your PC:
see **Alternative: build on GitHub** at the end.

---

## Step 0 - folder layout (everything lives under `C:\nxorbis`)

```
C:\nxorbis\repo     <- unzip nx-on-orbis-continued.zip HERE, so C:\nxorbis\repo\README.md exists
C:\nxorbis\tools    <- the host tools below
```

Check that the zip did not create an extra folder level: `C:\nxorbis\repo\patches\eden` must exist.

```bash
mkdir -p /c/nxorbis/tools
ls /c/nxorbis/repo/patches/eden | tail -3     # must end with 0028-... and 0029-...
```

## Step 1 - get the tools into `C:\nxorbis\tools`

Put each one in exactly this folder name (the scripts look for these paths):

| Tool | Download | Final location |
|---|---|---|
| LLVM 18.1.8 (Windows x64) | https://github.com/llvm/llvm-project/releases/tag/llvmorg-18.1.8 (`LLVM-18.1.8-win64.exe`; install it to the folder on the right, or 7-Zip-extract the .exe) | `C:\nxorbis\tools\llvm\bin\clang.exe` must exist |
| CMake 4.x (Windows x64 zip) | https://cmake.org/download/ | `C:\nxorbis\tools\cmake-4.4.3-windows-x86_64\bin\cmake.exe` (rename the extracted folder to exactly this) |
| Ninja (the build runner) | https://github.com/ninja-build/ninja/releases (`ninja-win.zip`) | `C:\nxorbis\tools\ninja\ninja.exe` |
| glslang | https://github.com/KhronosGroup/glslang/releases (main-tot windows zip) | `C:\nxorbis\tools\glslang\bin\glslangValidator.exe` |
| OpenOrbis PS4 Toolchain **0.5.4** | https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain/releases | `C:\nxorbis\tools\OpenOrbis\OpenOrbis\PS4Toolchain\` (it must contain `samples\piglet` and `bin\windows`) |
| llvm-mingw (ucrt, x86_64) | https://github.com/mstorsjo/llvm-mingw/releases | `C:\nxorbis\tools\llvm-mingw\bin\x86_64-w64-mingw32-clang.exe` |
| MSYS2 (for `make` and `perl`) | https://www.msys2.org | see below |
| Python 3 + Pillow | https://python.org, then `pip install pillow` | normal install, `python` in PATH |

MSYS2 `make` and `perl` (used only to build OpenSSL/FFmpeg): install MSYS2, open its shell and run
`pacman -S make perl diffutils`. Then in Git Bash:

```bash
mkdir -p /c/nxorbis/repo/tools/msys-perl
cp -r /c/msys64/usr /c/nxorbis/repo/tools/msys-perl/usr
mkdir -p /c/nxorbis/repo/tools/bin
cp /c/nxorbis/tools/glslang/bin/glslangValidator.exe /c/nxorbis/repo/tools/bin/
```

Quick check before going on (all four must print a path):

```bash
ls /c/nxorbis/tools/llvm/bin/clang.exe
ls /c/nxorbis/tools/ninja/ninja.exe
ls /c/nxorbis/tools/OpenOrbis/OpenOrbis/PS4Toolchain/samples/piglet/sce_module/libc.prx
ls /c/nxorbis/tools/cmake-4.4.3-windows-x86_64/bin/cmake.exe
```

## Step 2 - point the scripts at your folders

The scripts have the original author's paths hard-coded. Replace them (the `ci/` and `.github`
folders are for the GitHub build and are skipped):

```bash
cd /c/nxorbis/repo
grep -rlE "(C:|/c)/Users/alejo/(eden-ps4|soh-ps4/tools)" --include=*.sh --include=*.cmake . \
  | grep -v '^./ci/' \
  | xargs sed -i -e "s#C:/Users/alejo/eden-ps4#C:/nxorbis/repo#g" \
                 -e "s#/c/Users/alejo/eden-ps4#/c/nxorbis/repo#g" \
                 -e "s#C:/Users/alejo/soh-ps4/tools#C:/nxorbis/tools#g" \
                 -e "s#/c/Users/alejo/soh-ps4/tools#/c/nxorbis/tools#g"
grep -rn "alejo" --include=*.sh --include=*.cmake . | grep -v '^./ci/'   # should print nothing
```

## Step 3 - the PS4 SDK (`orbis-sdk-v1`)

1. Download the release asset(s) from
   https://github.com/orbis-ports/orbis-porting-kit/releases/tag/orbis-sdk-v1
2. Unpack so this file exists: `C:\nxorbis\repo\sdk-dl\orbis-sdk-v1\toolchain\orbis-sdk.cmake`
   (folders `sdk`, `orbis-compat`, `toolchain` must sit directly inside `orbis-sdk-v1`).
3. Two local changes for Windows:
   - Copy the Windows tools of OpenOrbis 0.5.4 (`create-fself.exe`, `create-gp4.exe`,
     `PkgTool.Core.exe` and its `.dll` files) from
     `C:\nxorbis\tools\OpenOrbis\OpenOrbis\PS4Toolchain\bin\windows\` into
     `C:\nxorbis\repo\sdk-dl\orbis-sdk-v1\sdk\bin\windows\` (create the folder if missing).
   - Open `C:\nxorbis\repo\sdk-dl\orbis-sdk-v1\orbis-compat\cmake\ps4-openorbis.cmake`. Next to the
     macOS branch that sets `OO_PS4_BINDIR`, add:
     ```
     elseif(CMAKE_HOST_WIN32)
       set(OO_PS4_BINDIR "${OO_PS4_TOOLCHAIN}/bin/windows")
     ```
     (inside the same `if/elseif/endif` chain).

## Step 4 - libc++ 18 for the PS4

```bash
cd /c/nxorbis/repo
export PATH="/c/nxorbis/tools/llvm/bin:/c/nxorbis/tools/cmake-4.4.3-windows-x86_64/bin:/c/nxorbis/tools/ninja:$PATH"
mkdir -p deps && cd deps
git clone --depth 1 --branch llvmorg-18.1.8 --filter=blob:none --sparse https://github.com/llvm/llvm-project.git
cd llvm-project
git sparse-checkout set runtimes libcxx libcxxabi libunwind cmake llvm/cmake third-party
```

**Patch one line** in `C:\nxorbis\repo\deps\llvm-project\libcxx\src\filesystem\operations.cpp`
(near line 40): find the condition that enables `sendfile` for Linux
(`defined(__linux__)`), and change it to `(defined(__linux__) && !defined(__ORBIS__))`.

Then:

```bash
cd /c/nxorbis/repo
cmake -S deps/llvm-project/runtimes -B build-libcxx -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=C:/nxorbis/repo/toolchain/runtimes-ps4.cmake -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
  -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXX_HAS_MUSL_LIBC=ON \
  -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=OFF \
  -DLIBCXXABI_USE_LLVM_UNWINDER=OFF -DLIBCXX_ENABLE_TIME_ZONE_DATABASE=OFF \
  -DLIBCXX_INCLUDE_BENCHMARKS=OFF -DCMAKE_INSTALL_PREFIX=C:/nxorbis/repo/libcxx18
ninja -C build-libcxx install
echo '#undef __FreeBSD__' >> libcxx18/include/c++/v1/__config_site
ls libcxx18/lib          # libc++.a and libc++abi.a must be there
```

## Step 5 - OpenSSL and FFmpeg for the PS4

(Use `-j2` instead of `-j8` if the PC has little RAM.)

```bash
cd /c/nxorbis/repo
source tools/env-build.sh
mkdir -p prefix tmp deps && export TMPDIR=/c/nxorbis/repo/tmp

# OpenSSL 3.6.2
cd deps
curl -L -o openssl.tgz https://github.com/openssl/openssl/releases/download/openssl-3.6.2/openssl-3.6.2.tar.gz
tar -xzf openssl.tgz && cd openssl-3.6.2
CFLAGS="$PS4_CFLAGS" CC=clang AR=llvm-ar RANLIB=llvm-ranlib perl Configure linux-x86_64-clang \
  no-shared no-tests no-apps no-docs no-dso no-async no-afalgeng no-engine no-ui-console \
  no-secure-memory no-module --with-rand-seed=devrandom --prefix=/c/nxorbis/repo/prefix \
  --libdir=lib --openssldir=/app0/ssl
make -j8 build_libs && make install_dev
cd /c/nxorbis/repo

# FFmpeg
cd deps
git clone --filter=blob:none https://github.com/FFmpeg/FFmpeg.git ffmpeg
git -C ffmpeg checkout c7b5f1537d
mkdir -p build-ffmpeg && cd build-ffmpeg
../ffmpeg/configure --prefix=/c/nxorbis/repo/prefix --enable-cross-compile --arch=x86_64 --target-os=freebsd \
  --host-cc=/c/nxorbis/tools/llvm-mingw/bin/x86_64-w64-mingw32-clang \
  --host-ld=/c/nxorbis/tools/llvm-mingw/bin/x86_64-w64-mingw32-clang \
  --cc='bash /c/nxorbis/repo/tools/ps4-cc.sh' --ld='bash /c/nxorbis/repo/tools/ps4-cc.sh' \
  --ar=llvm-ar --ranlib=llvm-ranlib --nm=llvm-nm --disable-x86asm --disable-autodetect \
  --disable-everything --disable-programs --disable-doc --disable-avdevice --disable-avformat \
  --disable-network --disable-swresample --enable-decoder='h264,vp8,vp9' \
  --enable-filter='yadif,scale' --enable-pic --enable-pthreads --disable-shared --enable-static
make -j8 && make install
ls /c/nxorbis/repo/prefix/lib   # libssl.a libcrypto.a libavcodec.a ... must be there
```

## Step 6 - build Eden (patches and frontend are already in the project)

Nothing to copy: `patches/eden/` already ends with 0028 and 0029 and `frontend/` is already updated.
Do **not** add another patch file there (a combined 0028+0029 patch would fail on top of these two).

```bash
cd /c/nxorbis/repo
bash scripts/fetch-eden.sh          # downloads Eden and applies ALL 29 patches, in order
bash configure-eden.sh              # ~10 min the first time
source tools/env-build.sh && unset OO_PS4_TOOLCHAIN
cmake --build build-eden --target eden-ps4          # the long step (1-3 h)
```

If `fetch-eden.sh` stops with a patch error, send the last lines it printed.
Low RAM? Use `cmake --build build-eden --target eden-ps4 -j2` (see below).

## Step 7 - make the .pkg

```bash
cd /c/nxorbis/repo
bash package-eden.sh
ls -la out-eden/          # the .pkg is here
ls -la elf/               # KEEP the .elf too: crash logs can only be read with it
```

Send back the `.pkg` **and** the `.elf`.

---

## Low RAM (less than 16 GB)

- Run builds with fewer parallel jobs: `-j2` (or `-j1` if the PC freezes or the build dies with an
  out-of-memory error). Every `make -j8` above can become `make -j2`.
- Raise Windows' virtual memory (page file) to 16-32 GB on an SSD: Settings > System > About >
  Advanced system settings > Performance > Advanced > Virtual memory.
- Close the browser and other programs, especially during the final link of Eden.
- If the build stops, run the same command again: Ninja resumes where it left off.
- About 8 GB should work but slowly (hours). With 4 GB, expect failures; use the GitHub build below.

## Alternative: build on GitHub (no installs, 16 GB RAM server)

The project contains `.github/workflows/build-pkg.yml`. Put the project in a **public** GitHub
repository, open its **Actions** tab, choose **Compilar PKG (NX on Orbis)** and press **Run
workflow**. When it finishes, the **Artifacts** section has `PKG-e-ELF`. If it fails, download the
`logs` artifact. This path was also written without being able to run it, so the first run may need a fix.

## After you have the .pkg

1. Install it like `docs/INSTALL.md` explains (FTP in **binary** mode, GoldHEN package installer).
2. Color experiment (see `docs/COLOR-EXPERIMENTS.md`): create `/data/edenps4/settings.txt` with
   ONE line, run MK8D, and note how the video, the 3D models and the UI look; then change the line
   and repeat:

       a2b10=write

       a2b10=sample

3. Send back `/data/edenps4/boot.log` (its first lines include a `hardware:` line; useful on any
   console model), `boot.old.log`, `mesa.log` and `log/eden_log.txt`, plus what you saw on screen.
4. Base PS4 (Fat/Slim) tests are very welcome: see `docs/BASE-PS4.md` for what to report.

## If something fails

Send: (1) the step number, (2) the last ~40 lines printed, (3) the output of `ls` of the folder the
step was working in. Please do not report anything about this port to the Eden project: it prohibits
AI-assisted contributions and this port is not affiliated with it (the patches here were written with
Claude, Anthropic; see the README credits).
