#!/bin/sh
set -eu
[ "$(uname -s)" = Darwin ] && [ "$(uname -m)" = arm64 ] || {
  echo "Run this script on an Apple Silicon Mac." >&2
  exit 1
}
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
cmake -S . -B build/macos-arm64 \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DBUILD_TESTING=OFF -DBTOP_ZH_CHECKS=ON -DBTOP_GPU=ON -DBTOP_LTO=OFF
cmake --build build/macos-arm64 -j 4
ctest --test-dir build/macos-arm64 --output-on-failure
file build/macos-arm64/btop-zh
build/macos-arm64/btop-zh --version
sh scripts/package-macos-arm64.sh
sh scripts/package-macos-dmg.sh
