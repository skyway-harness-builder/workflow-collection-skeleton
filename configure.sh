#!/usr/bin/env bash
# configure.sh — one-time setup for the workflow-skeleton.
# Run once after cloning or using this template; deletes itself when done.
set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'

say()  { echo -e "$*"; }
ask()  { local prompt="$1" default="$2" val; read -rp "$(say "  ${CYAN}${prompt}${RESET} [${default}]: ")" val; echo "${val:-$default}"; }
warn() { say "  ${YELLOW}!${RESET} $*"; }
ok()   { say "  ${GREEN}✓${RESET} $*"; }

say ""
say "${BOLD}Skylence workflow skeleton — configure${RESET}"
say "--------------------------------------"
say ""

# ── detect GitHub remote context ────────────────────────────────────────────
_remote_url=$(git config remote.origin.url 2>/dev/null || echo "")
_inferred_org=$(echo "$_remote_url" | sed -E 's|.*(github\.com)[:/]([^/]+)/.*|\2|' || echo "")
_inferred_repo=$(echo "$_remote_url" | sed -E 's|.*github\.com[:/][^/]+/([^/.]+)(\.git)?$|\1|' || echo "")
_git_name=$(git config user.name 2>/dev/null || echo "")
_git_email=$(git config user.email 2>/dev/null || echo "")

# ── prompts ─────────────────────────────────────────────────────────────────
VENDOR=$(ask       "Vendor slug  (kebab-case, used in paths and tags)" "${_inferred_org:-my-vendor}")
VENDOR_NAME=$(ask  "Vendor name  (display label, e.g. Acme Corp)"       "${VENDOR}")
AUTHOR_NAME=$(ask  "Author name"                                         "${_git_name:-Your Name}")
AUTHOR_EMAIL=$(ask "Author email"                                        "${_git_email:-you@example.com}")
REPO_NAME=$(ask    "GitHub repo name  (this repo's slug)"               "${_inferred_repo:-my-workflows}")
GITHUB_ORG=$(ask   "GitHub org / user  (owner of this repo)"            "${_inferred_org:-my-org}")

TODAY=$(date +%Y-%m-%d)

say ""
say "${BOLD}Will configure:${RESET}"
say "  vendor slug  : ${CYAN}${VENDOR}${RESET}"
say "  vendor name  : ${VENDOR_NAME}"
say "  author       : ${AUTHOR_NAME} <${AUTHOR_EMAIL}>"
say "  repo         : ${GITHUB_ORG}/${REPO_NAME}"
say "  date         : ${TODAY}"
say ""
read -rp "$(say "  Proceed? [y/N] ")" _confirm
[[ "$_confirm" =~ ^[yY] ]] || { say "Aborted."; exit 0; }
say ""

# ── export tokens so python can read them from env ───────────────────────────
export SKY_VENDOR="$VENDOR"
export SKY_VENDOR_NAME="$VENDOR_NAME"
export SKY_AUTHOR_NAME="$AUTHOR_NAME"
export SKY_AUTHOR_EMAIL="$AUTHOR_EMAIL"
export SKY_REPO_NAME="$REPO_NAME"
export SKY_GITHUB_ORG="$GITHUB_ORG"
export SKY_TODAY="$TODAY"

# ── find-replace all text files ──────────────────────────────────────────────
say "  Replacing tokens in files..."

find . -type f \
  -not -path './.git/*' \
  -not -name 'configure.sh' \
  | python3 -c "
import os, sys

tokens = [
  ('__vendor__',       os.environ['SKY_VENDOR']),
  ('__vendor_name__',  os.environ['SKY_VENDOR_NAME']),
  ('__author_name__',  os.environ['SKY_AUTHOR_NAME']),
  ('__author_email__', os.environ['SKY_AUTHOR_EMAIL']),
  ('__repo_name__',    os.environ['SKY_REPO_NAME']),
  ('__github_org__',   os.environ['SKY_GITHUB_ORG']),
  ('__today__',        os.environ['SKY_TODAY']),
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
    pass  # skip unreadable / binary files
"

ok "Tokens replaced."

# ── rename placeholder workflow directory ────────────────────────────────────
if [ -d "workflows/__vendor__" ]; then
  say "  Renaming workflows/__vendor__/ → workflows/${VENDOR}/"
  mv "workflows/__vendor__" "workflows/${VENDOR}"
  ok "Directory renamed."
fi

# ── lefthook install ─────────────────────────────────────────────────────────
if command -v lefthook &>/dev/null; then
  say "  Installing lefthook git hooks..."
  lefthook install
  ok "Lefthook hooks installed."
else
  warn "lefthook not found — run 'lefthook install' after installing it."
  warn "Install: https://github.com/evilmartians/lefthook"
fi

# ── initial commit hint ──────────────────────────────────────────────────────
say ""
say "${GREEN}${BOLD}Done!${RESET}"
say ""
say "Next steps:"
say "  1. ${BOLD}git add -A && git commit -m 'chore: configure skeleton'${RESET}"
say "  2. Push to GitHub — ${CYAN}https://github.com/${GITHUB_ORG}/${REPO_NAME}${RESET}"
say "  3. Add workflows under  ${BOLD}workflows/${VENDOR}/<name>/${RESET}"
say "  4. Register each one in ${BOLD}manifest.yaml${RESET}"
say "  5. Run ${BOLD}sky library add ${GITHUB_ORG}/${REPO_NAME}${RESET} to use them locally"
say ""

# ── self-delete ──────────────────────────────────────────────────────────────
rm -- "$0"
