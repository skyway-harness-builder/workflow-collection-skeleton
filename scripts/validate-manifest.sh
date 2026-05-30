#!/usr/bin/env bash
# validate-manifest.sh — validate manifest.yaml against the on-disk tree.
#
# Checks:
#   - apiVersion is skylence.io/v1
#   - path values in entries exist on disk
#   - kind values are workflow / skill / command
#   - scripts paths (if declared) exist on disk
#   - no drift: workflow.sky and SKILL.md counts match manifest
#
# Zero external dependencies (bash, grep, find, awk).
# Exit 0 on success, 1 on any failure.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$REPO_ROOT/manifest.yaml"
ERRORS=0

err() { echo "  ERROR $*" >&2; ERRORS=$((ERRORS + 1)); }

# ── apiVersion ────────────────────────────────────────────────────────────────
if ! grep -q "^apiVersion: skylence\.be/v1$" "$MANIFEST"; then
  err "apiVersion must be 'skylence.be/v1'"
fi

# ── path values exist on disk ─────────────────────────────────────────────────
while IFS= read -r line; do
  path="${line#*path: }"
  path="${path//\"/}"
  path="$(echo "$path" | tr -d '[:space:]')"
  [ -z "$path" ] && continue
  if [ ! -f "$REPO_ROOT/$path" ]; then
    err "path not found on disk: $path"
  fi
done < <(grep -E "^    path:" "$MANIFEST")

# ── kind values are valid ─────────────────────────────────────────────────────
while IFS= read -r line; do
  kind="${line#*kind: }"
  kind="$(echo "$kind" | tr -d '[:space:]"')"
  [ -z "$kind" ] && continue
  case "$kind" in
    workflow|skill|command) ;;
    *) err "invalid kind: '$kind' (must be workflow, skill, or command)" ;;
  esac
done < <(grep -E "^\s+-\s+kind:" "$MANIFEST")

# ── scripts paths exist on disk ───────────────────────────────────────────────
in_scripts=0
while IFS= read -r line; do
  if echo "$line" | grep -qE "^    scripts:"; then
    in_scripts=1
    continue
  fi
  if [ "$in_scripts" -eq 1 ]; then
    if echo "$line" | grep -qE "^      -"; then
      script_path="${line#*- }"
      script_path="${script_path//\"/}"
      script_path="$(echo "$script_path" | tr -d '[:space:]')"
      [ -z "$script_path" ] && continue
      if [ ! -f "$REPO_ROOT/$script_path" ]; then
        err "scripts path not found: $script_path"
      fi
    else
      in_scripts=0
    fi
  fi
done < "$MANIFEST"

# ── drift check ───────────────────────────────────────────────────────────────
manifest_workflows=$(grep -c "kind: workflow" "$MANIFEST" || true)
manifest_skills=$(grep -c "kind: skill" "$MANIFEST" || true)

disk_workflows=$(find "$REPO_ROOT" -name "workflow.sky" | wc -l | tr -d ' ')
disk_skills=$(find "$REPO_ROOT" -name "SKILL.md" | wc -l | tr -d ' ')

if [ "$manifest_workflows" -ne "$disk_workflows" ]; then
  err "workflow drift: manifest=$manifest_workflows disk=$disk_workflows (workflow.sky files)"
fi
if [ "$manifest_skills" -ne "$disk_skills" ]; then
  err "skill drift: manifest=$manifest_skills disk=$disk_skills (SKILL.md files)"
fi

# ── summary ───────────────────────────────────────────────────────────────────
total=$((manifest_workflows + manifest_skills))
echo "manifest.yaml: $total entries ($manifest_workflows workflows, $manifest_skills skills)"

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "$ERRORS error(s) — validation FAILED" >&2
  exit 1
fi

echo "  OK  manifest valid"
