#!/usr/bin/env bash
# Host packages and free disk space.
set -euo pipefail
source "$(dirname "$0")/common.sh"
step "free disk space"
df -h / | tail -1
sudo rm -rf /usr/local/lib/android /opt/ghc /usr/share/swift /opt/hostedtoolcache/CodeQL /usr/local/share/boost || true
df -h / | tail -1
step "packages"
sudo apt-get update -q
sudo apt-get install -y -q ninja-build cmake clang-18 lld-18 llvm-18 llvm-18-dev glslang-tools \
    spirv-tools python3-pil p7zip-full unzip perl make pkg-config nasm ccache libssl-dev zlib1g-dev
clang --version | head -1
cmake --version | head -1
dotnet --info | head -3 || echo "dotnet not found (needed only by PkgTool.Core)"
