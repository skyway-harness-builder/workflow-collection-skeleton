#!/usr/bin/env bash
# configure.sh — one-time skeleton setup.
# Run once after using this template; deletes itself when done.
set -euo pipefail

# ── colour helpers ────────────────────────────────────────────────────────────
_ansi_ok=1
[ -t 1 ] || _ansi_ok=0
[ "${NO_COLOR:-}" ] && _ansi_ok=0

_c() { [ "$_ansi_ok" -eq 1 ] && printf "\033[%sm" "$1" || true; }
RESET="$(_c 0)"; BOLD="$(_c 1)"; DIM="$(_c 2)"
GREEN="$(_c 32)"; YELLOW="$(_c 33)"; CYAN="$(_c 36)"

say()  { printf "%s\n" "$*"; }
dim()  { printf "%s%s%s" "$DIM" "$*" "$RESET"; }
bold() { printf "%s%s%s" "$BOLD" "$*" "$RESET"; }
ok()   { say "  ${GREEN}✓${RESET} $*"; }
warn() { say "  ${YELLOW}!${RESET} $*"; }

ask() {
  local label="$1" default="$2" val
  printf "  %s%s%s %s: " "$CYAN" "$label" "$RESET" "$(dim "(${default})")"
  IFS= read -r val
  printf "%s" "${val:-$default}"
}

confirm() {
  local label="$1" default="${2:-Y}" ans
  local hint; [ "$default" = "Y" ] && hint="Y/n" || hint="y/N"
  printf "  %s%s%s %s: " "$CYAN" "$label" "$RESET" "$(dim "(${hint})")"
  IFS= read -r ans
  ans="${ans:-$default}"
  [[ "$ans" =~ ^[yY] ]]
}

# ── banner ────────────────────────────────────────────────────────────────────
say ""
say "$(bold '  ███████ ██   ██ ██    ██')"
say "$(bold '  ██      ██  ██  ██  ██ ')"
say "$(bold '  ███████ █████    ████  ')"
say "$(bold '       ██ ██  ██    ██   ')"
say "$(bold '  ███████ ██   ██   ██   ')"
say ""
say "  $(bold 'Skylence Workflow Library Skeleton')"
say "  $(dim 'Let'\''s get your library configured.')"
say ""

# ── infer defaults from git ───────────────────────────────────────────────────
_remote=$(git config remote.origin.url 2>/dev/null || true)
_inferred_org=$(echo "$_remote" | sed -E 's|.*(github\.com)[:/]([^/]+)/.*|\2|')
_inferred_repo=$(echo "$_remote" | sed -E 's|.*github\.com[:/][^/]+/([^/.]+)(\.git)?$|\1|')
_git_name=$(git config user.name 2>/dev/null || true)
_git_email=$(git config user.email 2>/dev/null || true)
_git_username=$(gh api user --jq '.login' 2>/dev/null || echo "$_inferred_org")

# ── author ────────────────────────────────────────────────────────────────────
say "  $(bold 'Author')"
say "  $(dim 'Used for README credits and the manifest.')"
say ""
AUTHOR_NAME=$(ask    "Author name"     "${_git_name:-Your Name}")
AUTHOR_EMAIL=$(ask   "Author email"    "${_git_email:-you@example.com}")
AUTHOR_USERNAME=$(ask "Author username (GitHub)" "${_git_username:-your-username}")

say ""

# ── library ───────────────────────────────────────────────────────────────────
say "  $(bold 'Library')"
say "  $(dim 'The vendor slug is used in workflow paths and manifest tags.')"
say ""
VENDOR=$(ask       "Vendor slug  $(dim '(kebab-case)')"  "${_inferred_org:-my-vendor}")
VENDOR_NAME=$(ask  "Vendor name  $(dim '(display label)')" "${VENDOR}")
REPO_NAME=$(ask    "GitHub repo name"                      "${_inferred_repo:-my-workflows}")
GITHUB_ORG=$(ask   "GitHub org / user"                     "${_inferred_org:-my-org}")
DESCRIPTION=$(ask  "Library description"                   "A collection of .sky workflows by ${VENDOR_NAME}")

# Topic that gets a published collection discovered and listed on skylence.be.
# Not a prompt: the value has to match what the site searches for.
DISCOVERY_TOPIC="sky-workflow"

say ""

# ── tooling ───────────────────────────────────────────────────────────────────
say "  $(bold 'Tooling')"
say "  $(dim 'Optional extras — you can always add them back later.')"
say ""

say "  $(dim 'Pre-commit hooks that lint .sky files and validate the manifest before each commit.')"
USE_LEFTHOOK=y; confirm "Enable lefthook?" "Y" && USE_LEFTHOOK=y || USE_LEFTHOOK=n
say ""

say "  $(dim 'Runs shellcheck on .sh files in CI for deeper static analysis beyond bash -n.')"
USE_SHELLCHECK=y; confirm "Enable shellcheck in CI?" "Y" && USE_SHELLCHECK=y || USE_SHELLCHECK=n
say ""

say "  $(dim 'Runs yamllint on .yaml/.yml files in CI (pre-installed on ubuntu-latest).')"
USE_YAMLLINT=y; confirm "Enable yamllint in CI?" "Y" && USE_YAMLLINT=y || USE_YAMLLINT=n

say ""

# ── summary ───────────────────────────────────────────────────────────────────
say "  $(bold 'Summary')"
say ""
say "  Author       ${AUTHOR_NAME} (${AUTHOR_USERNAME}, ${AUTHOR_EMAIL})"
say "  Vendor       ${VENDOR_NAME} (${VENDOR})"
say "  Repo         ${GITHUB_ORG}/${REPO_NAME}"
say "  Description  ${DESCRIPTION}"
say ""
_yn() { [ "$1" = "y" ] && printf '%s' "${GREEN}yes${RESET}" || printf '%s' "$(dim 'no')"; }
say "  Tooling"
say "  Lefthook     $(_yn "$USE_LEFTHOOK")"
say "  Shellcheck   $(_yn "$USE_SHELLCHECK")"
say "  Yamllint     $(_yn "$USE_YAMLLINT")"
say ""

confirm "Modify files?" "Y" || { say "Aborted."; exit 0; }
say ""

TODAY=$(date +%Y-%m-%d)

# ── export for python ─────────────────────────────────────────────────────────
export SKY_VENDOR="$VENDOR"
export SKY_VENDOR_NAME="$VENDOR_NAME"
export SKY_AUTHOR_NAME="$AUTHOR_NAME"
export SKY_AUTHOR_EMAIL="$AUTHOR_EMAIL"
export SKY_AUTHOR_USERNAME="$AUTHOR_USERNAME"
export SKY_REPO_NAME="$REPO_NAME"
export SKY_GITHUB_ORG="$GITHUB_ORG"
export SKY_DESCRIPTION="$DESCRIPTION"
export SKY_TODAY="$TODAY"

# ── find-replace all text files ───────────────────────────────────────────────
find . -type f \
  -not -path './.git/*' \
  -not -name 'configure.sh' \
  | python3 -c "
import os, sys

tokens = [
  ('__vendor__',          os.environ['SKY_VENDOR']),
  ('__vendor_name__',     os.environ['SKY_VENDOR_NAME']),
  ('__author_name__',     os.environ['SKY_AUTHOR_NAME']),
  ('__author_email__',    os.environ['SKY_AUTHOR_EMAIL']),
  ('__author_username__', os.environ['SKY_AUTHOR_USERNAME']),
  ('__repo_name__',       os.environ['SKY_REPO_NAME']),
  ('__github_org__',      os.environ['SKY_GITHUB_ORG']),
  ('__package_description__', os.environ['SKY_DESCRIPTION']),
  ('__today__',           os.environ['SKY_TODAY']),
]

for line in sys.stdin:
  path = line.rstrip('\n')
  try:
    with open(path, encoding='utf-8', errors='ignore') as fh:
      content = fh.read()
    for old, new in tokens:
      content = content.replace(old, new)
    with open(path, 'w', encoding='utf-8') as fh:
      fh.write(content)
  except (OSError, IOError):
    pass
"

ok "Replaced tokens in files."

# ── strip <!--delete--> sections from README ─────────────────────────────────
python3 - README.md << 'PYEOF'
import re, sys
path = sys.argv[1]
content = open(path).read()
content = re.sub(r'\n*<!--delete-->.*?<!--/delete-->\n*', '\n\n', content, flags=re.DOTALL)
open(path, 'w').write(content)
PYEOF
ok "Removed skeleton instructions from README.md."

# ── rename placeholder workflow directory ─────────────────────────────────────
if [ -d "workflows/__vendor__" ]; then
  mv "workflows/__vendor__" "workflows/${VENDOR}"
  ok "Renamed workflows/__vendor__/ → workflows/${VENDOR}/."
fi

# ── apply tooling opt-outs ───────────────────────────────────────────────────
if [ "$USE_LEFTHOOK" = "n" ]; then
  rm -f lefthook.yml
  ok "Removed lefthook.yml."
fi

if [ "$USE_SHELLCHECK" = "n" ]; then
  # Strip the shellcheck step, leaving only bash -n
  python3 - .github/workflows/bash-check.yml << 'PYEOF'
import sys, re
path = sys.argv[1]
content = open(path).read()
# Remove the shellcheck job step (the indented block starting with "      # Layer 2")
content = re.sub(r'\n      # Layer 2.*', '', content, flags=re.DOTALL)
open(path, 'w').write(content)
PYEOF
  ok "Removed shellcheck from bash-check.yml (bash -n syntax check remains)."
fi

if [ "$USE_YAMLLINT" = "n" ]; then
  python3 - scripts/yaml-check.sh << 'PYEOF'
import sys, re
path = sys.argv[1]
content = open(path).read()
# Remove the yamllint block but preserve the result block that follows it
content = re.sub(r'\n# ── layer 2: lint.*?(?=\n# ── result)', '', content, flags=re.DOTALL)
open(path, 'w').write(content)
PYEOF
  ok "Removed yamllint from yaml-check.sh (python yaml.safe_load remains)."
fi

# ── lefthook install ─────────────────────────────────────────────────────────
if [ "$USE_LEFTHOOK" = "y" ]; then
  if command -v lefthook &>/dev/null; then
    lefthook install
    ok "Installed lefthook git hooks."
  else
    warn "lefthook not found — run 'lefthook install' after installing it."
    warn "Install: https://github.com/evilmartians/lefthook"
  fi
fi

# ── discovery topic ──────────────────────────────────────────────────────────
# skylence.be lists collections it can find, and its cheapest discovery path is
# a GitHub topic search. Topics are NOT copied from a template repo (GitHub
# copies files, not settings), so a fresh collection carries none until someone
# sets this one. Best effort: the remote may not exist yet at this point.
if command -v gh &>/dev/null && git remote get-url origin &>/dev/null; then
  if gh repo edit --add-topic "$DISCOVERY_TOPIC" &>/dev/null; then
    ok "Tagged the repo '${DISCOVERY_TOPIC}' so skylence.be can list it."
  else
    warn "Could not tag the repo — after pushing, run: gh repo edit --add-topic ${DISCOVERY_TOPIC}"
  fi
else
  warn "No gh CLI or no remote yet — after pushing, run: gh repo edit --add-topic ${DISCOVERY_TOPIC}"
fi

say ""
say "  $(bold 'Next steps')"
say ""
say "  1. $(bold "git add -A && git commit -m 'chore: configure skeleton'")"
say "  2. Push to ${CYAN}https://github.com/${GITHUB_ORG}/${REPO_NAME}${RESET}"
say "  3. Tag it for discovery: $(bold "gh repo edit --add-topic ${DISCOVERY_TOPIC}")"
say "  4. Add workflows under $(bold "workflows/${VENDOR}/<name>/")"
say "  5. Register each in $(bold 'manifest.yaml')"
say "  6. Run $(bold "sky library add ${GITHUB_ORG}/${REPO_NAME}") to use them locally"
say ""

confirm "Let this script delete itself?" "Y" && rm -- "$0" && ok "configure.sh deleted." || true

say ""
say "  ${GREEN}$(bold '✨ You'\''re all set! Happy automating.')${RESET}"
say ""
