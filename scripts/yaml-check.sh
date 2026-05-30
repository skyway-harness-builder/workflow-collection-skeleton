#!/usr/bin/env bash
# yaml-check.sh — validate YAML files in two layers.
#
# Layer 1: python3 yaml.safe_load — syntax, zero deps, runs everywhere
# Layer 2: yamllint             — style and structure (pre-installed on ubuntu-latest;
#                                 skipped with a warning when absent locally)
#
# Usage:
#   bash scripts/yaml-check.sh              # scan all *.yaml / *.yml in the repo
#   bash scripts/yaml-check.sh a.yml b.yaml # check specific files (e.g. from lefthook)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

# ── collect files ─────────────────────────────────────────────────────────────
if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  FILES=()
  while IFS= read -r f; do FILES+=("$f"); done < <(
    find "$REPO_ROOT" \( -name '*.yaml' -o -name '*.yml' \) -not -path '*/.git/*'
  )
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No YAML files found."
  exit 0
fi

# ── layer 1: syntax ───────────────────────────────────────────────────────────
echo "Layer 1: YAML syntax (yaml.safe_load)"
for f in "${FILES[@]}"; do
  if ! python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$f" 2>/dev/null; then
    echo "  FAIL: $f"
    ERRORS=$((ERRORS + 1))
  fi
done

# ── layer 2: lint ─────────────────────────────────────────────────────────────
if command -v yamllint &>/dev/null; then
  echo "Layer 2: yamllint"
  if [ -f "$REPO_ROOT/.yamllint.yml" ]; then
    CONFIG_ARG="-c $REPO_ROOT/.yamllint.yml"
  else
    CONFIG_ARG="-d relaxed"
  fi
  # shellcheck disable=SC2086
  yamllint $CONFIG_ARG "${FILES[@]}" || ERRORS=$((ERRORS + 1))
else
  echo "Layer 2: yamllint not installed — skipping (runs in CI)"
fi

# ── result ────────────────────────────────────────────────────────────────────
if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "$ERRORS error(s) — YAML check FAILED" >&2
  exit 1
fi
echo "YAML check passed."
