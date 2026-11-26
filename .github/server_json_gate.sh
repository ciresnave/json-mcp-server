#!/usr/bin/env bash
# SPDX-License-Identifier: MIT OR Apache-2.0
# Fails unless server.json's "version" and packages[0] "version" both equal Cargo.toml's package version.
# Usage: server_json_gate.sh [Cargo.toml] [server.json]   |   server_json_gate.sh --self-test
set -euo pipefail

check() {
  local cargo="$1" sj="$2" want got n
  want=$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' "$cargo" | head -n1)
  [ -n "$want" ] || { echo "no version found in $cargo" >&2; return 2; }
  n=$(grep -c '^ *"version": *"' "$sj" || true)
  [ "$n" = 2 ] || { echo "expected 2 version fields in $sj, found $n" >&2; return 2; }
  local bad=0
  while IFS= read -r got; do
    if [ "$got" != "$want" ]; then
      echo "server.json version $got != Cargo.toml $want" >&2; bad=1
    fi
  done < <(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$sj")
  [ "$bad" = 0 ] && echo "server.json versions == Cargo.toml $want"
  return "$bad"
}

if [ "${1:-}" = "--self-test" ]; then
  d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
  printf '[package]\nversion = "1.2.3"\n' > "$d/Cargo.toml"
  printf '{\n  "version": "1.2.3",\n  "packages": [\n    {\n      "version": "1.2.3"\n    }\n  ]\n}\n' > "$d/ok.json"
  printf '{\n  "version": "1.2.3",\n  "packages": [\n    {\n      "version": "1.2.2"\n    }\n  ]\n}\n' > "$d/bad.json"
  check "$d/Cargo.toml" "$d/ok.json" >/dev/null || { echo "self-test: match must pass" >&2; exit 1; }
  if check "$d/Cargo.toml" "$d/bad.json" 2>/dev/null; then echo "self-test: mismatch must fail" >&2; exit 1; fi
  echo "self-test ok (match passes, mismatch fails)"; exit 0
fi
check "${1:-Cargo.toml}" "${2:-server.json}"
