#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
rive_bin="${RIVE_BIN:-$(command -v rive || true)}"
if [[ -z "$rive_bin" && -x "$HOME/.rive/bin/rive" ]]; then
    rive_bin="$HOME/.rive/bin/rive"
fi
if [[ -z "$rive_bin" ]]; then
    echo 'Install the Rive CLI from https://rive.app/cli first.' >&2
    exit 1
fi

source_dir="$repo_root/Rive/TravelOnboarding"
"$rive_bin" "$source_dir" --verify
"$rive_bin" inspect "$source_dir" --summary
"$rive_bin" "$source_dir" --once
cp "$source_dir/build/TravelOnboarding.riv" \
   "$repo_root/UI-Experiments/RiveOnboarding/Resources/TravelOnboarding.riv"
echo 'Updated the bundled TravelOnboarding.riv.'
