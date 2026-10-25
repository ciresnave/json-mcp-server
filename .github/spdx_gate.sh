#!/usr/bin/env bash
# SPDX-License-Identifier: MIT OR Apache-2.0
# Every tracked source file declares the licence in its first 10 lines.
#
#   bash .github/spdx_gate.sh              # check
#   bash .github/spdx_gate.sh --self-test  # prove the check can fail, and can see files
#
# Enumerates from the index (`git ls-files`), never the disk. Never writes. Refuses an empty
# population: "0 of 0 files declare it" is true of a glob that matched nothing.
set -euo pipefail

LICENCE="MIT OR Apache-2.0"
# Source extensions checked. A tracked file of any of these without the header fails the gate.
EXTENSIONS=('*.rs' '*.sh' '*.py' '*.ts' '*.tsx' '*.js' '*.mjs' '*.cjs' '*.go' '*.c' '*.h' '*.cc' '*.cpp' '*.hpp' '*.ps1' '*.sql')
MINIMUM_FILES=38  # 37 tracked source files + this script; raise as the tree grows

check_tree() { # $1 = repo root; prints missing files, one per line; returns count via stdout
    local root=$1 file hits missing=0 total=0
    while IFS= read -r -d '' file; do
        total=$((total + 1))
        # grep -c, not -q: -q exits early and can SIGPIPE `head`, which pipefail reports as a miss.
        hits=$(head -n 10 "$root/$file" | grep -cF "SPDX-License-Identifier: $LICENCE" || true)
        if [ "$hits" -lt 1 ]; then
            echo "MISSING: $file" >&2
            missing=$((missing + 1))
        fi
    done < <(git -C "$root" ls-files -z -- "${EXTENSIONS[@]}")
    echo "$total $missing"
}

if [ "${1:-}" = "--self-test" ]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    git -C "$tmp" init -q
    printf '// SPDX-License-Identifier: %s\nfn a() {}\n' "$LICENCE" >"$tmp/good.rs"
    printf 'fn b() {}\n' >"$tmp/bad.rs"
    git -C "$tmp" add good.rs bad.rs
    read -r total missing < <(check_tree "$tmp" 2>/dev/null)
    [ "$total" = 2 ] && [ "$missing" = 1 ] || { echo "self-test FAILED: total=$total missing=$missing (want 2, 1)" >&2; exit 1; }
    echo "self-test ok: saw 2 files, flagged exactly the 1 undeclared one"
    exit 0
fi

root=$(git rev-parse --show-toplevel)
read -r total missing < <(check_tree "$root")
echo "source files: $total, undeclared: $missing"
[ "$total" -ge "$MINIMUM_FILES" ] || { echo "population $total < floor $MINIMUM_FILES: the query is broken" >&2; exit 1; }
[ "$missing" = 0 ]
