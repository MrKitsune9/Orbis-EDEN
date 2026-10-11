# Shared setup for the CI scripts (source this).
export ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export TOOLS="$ROOT/tools-host"
export PATH="/usr/lib/llvm-18/bin:$PATH"
export DOTNET_ROLL_FORWARD=LatestMajor
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export SDK_ROOT="$ROOT/sdk-dl/orbis-sdk-v1"
mkdir -p "$ROOT/logs" "$TOOLS"
step() { echo; echo "=============== $* ==============="; }
