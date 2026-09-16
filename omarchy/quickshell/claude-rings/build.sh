#!/usr/bin/env bash
# Compile ring.frag into the blob quickshell loads.
#
# The blob is in the repository because the shell has to run on a host that may
# not carry Qt's shader tools, and because nothing else here needs a build step.
# Run this after every change to ring.frag, on a host that has Qt 6, and commit
# both files together: a stale blob is a change that quietly does nothing.
set -euo pipefail

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

qsb="${QSB:-/usr/lib/qt6/bin/qsb}"
if [[ ! -x $qsb ]]; then
  qsb="$(command -v qsb || true)"
fi
if [[ -z $qsb ]]; then
  printf 'build.sh: no qsb. It ships with Qt 6; on Omarchy that is qt6-shadertools.\n' >&2
  exit 1
fi

"$qsb" --glsl "150,330,300 es" -o ring.frag.qsb ring.frag
printf 'Compiled ring.frag.qsb with %s\n' "$qsb"
