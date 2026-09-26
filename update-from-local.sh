#!/usr/bin/env bash
#
# Copy the live Idea Council from ~/.claude/ back into this repository.
#
# Run this on the machine where the canonical, working Council lives, after
# making improvements to the agents or the skill.
#
# This script never commits and never pushes. It stages nothing. You review
# the diff and decide.

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

CLAUDE_DIR="${HOME}/.claude"
AGENTS_SRC="${CLAUDE_DIR}/agents"
SKILL_SRC="${CLAUDE_DIR}/skills/idea-council"

AGENTS=(pragmatist skeptic idealist connector)

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; }

bold "Claude Idea Council — update repository from local ~/.claude"
echo "Source: ${CLAUDE_DIR}"
echo "Target: ${REPO_DIR}"
echo

# ---------------------------------------------------------------- preflight --
# Verify ALL five sources before copying ANY of them, so a missing file can
# never produce a half-updated backup.
bold "Checking all five source files"
missing=0
for a in "${AGENTS[@]}"; do
  if [[ -f "${AGENTS_SRC}/${a}.md" ]]; then
    ok "${AGENTS_SRC}/${a}.md"
  else
    fail "${AGENTS_SRC}/${a}.md is MISSING"
    missing=1
  fi
done
if [[ -f "${SKILL_SRC}/SKILL.md" ]]; then
  ok "${SKILL_SRC}/SKILL.md"
else
  fail "${SKILL_SRC}/SKILL.md is MISSING"
  missing=1
fi

if [[ "${missing}" -ne 0 ]]; then
  echo
  fail "Aborted — nothing was copied."
  echo "    One or more source files are missing, and a partial backup is worse"
  echo "    than none. Restore the missing file, or run ./install.sh first if this"
  echo "    machine has never had the Council installed."
  exit 1
fi
echo

# --------------------------------------------------------------------- copy --
bold "Copying into the repository"
mkdir -p "${REPO_DIR}/agents" "${REPO_DIR}/skills/idea-council"
for a in "${AGENTS[@]}"; do
  cp "${AGENTS_SRC}/${a}.md" "${REPO_DIR}/agents/${a}.md"
  ok "agents/${a}.md"
done
cp "${SKILL_SRC}/SKILL.md" "${REPO_DIR}/skills/idea-council/SKILL.md"
ok "skills/idea-council/SKILL.md"
echo

# --------------------------------------------------------------- git status --
bold "Changes according to Git"
if ! command -v git >/dev/null 2>&1; then
  fail "git is not installed — cannot show changes."
  exit 0
fi
if ! git -C "${REPO_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
  fail "${REPO_DIR} is not a Git repository — cannot show changes."
  exit 0
fi

if [[ -z "$(git -C "${REPO_DIR}" status --porcelain)" ]]; then
  echo "  No changes — the repository already matches ~/.claude."
  echo
  bold "Done."
  exit 0
fi

git -C "${REPO_DIR}" status --short
echo
echo "  Line counts:"
git -C "${REPO_DIR}" diff --stat || true
echo

bold "Done. Nothing has been committed or pushed."
cat <<'MSG'

  Review, then commit yourself:

      cd ~/claude-idea-council
      git diff
      git add .
      git commit -m "Update Idea Council"
      git push

MSG
