#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export XDG_DATA_HOME="$PWD/.runtime/gui-data"
export XDG_CONFIG_HOME="$PWD/.runtime/gui-config"
export XDG_CACHE_HOME="$PWD/.runtime/gui-cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec godot --path "$PWD" --rendering-method gl_compatibility --resolution 1180x738 "$@"
