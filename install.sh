#!/usr/bin/env bash
#
# Install the Claude Idea Council into ~/.claude/
#
# Copies four read-only advisor agents and the /idea-council skill.
# Never touches ~/.claude/settings.json — it only inspects it and reports.

set -euo pipefail

# Resolve this script's own directory, so the repo can live anywhere.
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

CLAUDE_DIR="${HOME}/.claude"
AGENTS_DIR="${CLAUDE_DIR}/agents"
SKILLS_DIR="${CLAUDE_DIR}/skills"
SKILL_DIR="${SKILLS_DIR}/idea-council"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

AGENTS=(pragmatist skeptic idealist connector)

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; }

bold "Claude Idea Council — installer"
echo "Source: ${REPO_DIR}"
echo "Target: ${CLAUDE_DIR}"
echo

# ---------------------------------------------------------------- preflight --
bold "Checking source files"
missing=0
for a in "${AGENTS[@]}"; do
  if [[ -f "${REPO_DIR}/agents/${a}.md" ]]; then
    ok "agents/${a}.md"
  else
    fail "agents/${a}.md is missing from the repository"
    missing=1
  fi
done
if [[ -f "${REPO_DIR}/skills/idea-council/SKILL.md" ]]; then
  ok "skills/idea-council/SKILL.md"
else
  fail "skills/idea-council/SKILL.md is missing from the repository"
  missing=1
fi
if [[ "${missing}" -ne 0 ]]; then
  echo
  fail "Installation aborted — the repository is incomplete."
  echo "    Try: git pull, or re-clone the repository."
  exit 1
fi
echo

# ------------------------------------------------------------------ install --
bold "Installing"
mkdir -p "${AGENTS_DIR}" "${SKILLS_DIR}" "${SKILL_DIR}"

for a in "${AGENTS[@]}"; do
  cp "${REPO_DIR}/agents/${a}.md" "${AGENTS_DIR}/${a}.md"
  ok "${AGENTS_DIR}/${a}.md"
done

cp "${REPO_DIR}/skills/idea-council/SKILL.md" "${SKILL_DIR}/SKILL.md"
ok "${SKILL_DIR}/SKILL.md"
echo

# --------------------------------------------------------- verify installed --
bold "Verifying installation"
verify_failed=0
for a in "${AGENTS[@]}"; do
  if [[ -f "${AGENTS_DIR}/${a}.md" ]]; then
    ok "${AGENTS_DIR}/${a}.md exists"
  else
    fail "${AGENTS_DIR}/${a}.md is missing"
    verify_failed=1
  fi
done
if [[ -f "${SKILL_DIR}/SKILL.md" ]]; then
  ok "${SKILL_DIR}/SKILL.md exists"
else
  fail "${SKILL_DIR}/SKILL.md is missing"
  verify_failed=1
fi

# Byte-for-byte comparison against the repository copies.
for a in "${AGENTS[@]}"; do
  if ! cmp -s "${REPO_DIR}/agents/${a}.md" "${AGENTS_DIR}/${a}.md"; then
    fail "${a}.md differs from the repository copy"
    verify_failed=1
  fi
done
if ! cmp -s "${REPO_DIR}/skills/idea-council/SKILL.md" "${SKILL_DIR}/SKILL.md"; then
  fail "SKILL.md differs from the repository copy"
  verify_failed=1
fi

if [[ "${verify_failed}" -ne 0 ]]; then
  echo
  fail "Installation finished with errors — see above."
  exit 1
fi
ok "all five files match the repository byte-for-byte"
echo

# -------------------------------------------------------- settings.json check --
# This section NEVER writes. It inspects and reports only.
bold "Checking Agent Teams setting (read-only check)"

teams_enabled=""
if [[ -f "${SETTINGS_FILE}" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    teams_enabled="$(python3 - "${SETTINGS_FILE}" <<'PY' || true
import json, sys
try:
    with open(sys.argv[1]) as f:
        cfg = json.load(f)
except Exception:
    print("unreadable"); raise SystemExit(0)
val = (cfg.get("env") or {}).get("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS")
print("yes" if str(val) == "1" else "no")
PY
)"
  else
    # Fallback when python3 is unavailable: conservative textual check.
    if grep -q 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "${SETTINGS_FILE}"; then
      teams_enabled="probably"
    else
      teams_enabled="no"
    fi
  fi
else
  teams_enabled="nofile"
fi

case "${teams_enabled}" in
  yes)
    ok "Agent Teams is already enabled in ${SETTINGS_FILE}"
    ;;
  probably)
    warn "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS appears in ${SETTINGS_FILE}"
    warn "python3 was not available to confirm its value is \"1\" — please check by hand."
    ;;
  no|unreadable|nofile)
    if [[ "${teams_enabled}" == "nofile" ]]; then
      warn "No ${SETTINGS_FILE} found."
    elif [[ "${teams_enabled}" == "unreadable" ]]; then
      warn "${SETTINGS_FILE} exists but could not be parsed as JSON."
    else
      warn "Agent Teams is NOT enabled in ${SETTINGS_FILE}."
    fi
    cat <<'MSG'

    The Idea Council needs Agent Teams. Add this to ~/.claude/settings.json:

        "env": {
          "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
        }

    MERGE it into the existing file — do not replace the file. For example, if
    your settings.json currently reads:

        {
          "model": "opus[1m]",
          "tui": "fullscreen"
        }

    the merged result should be:

        {
          "model": "opus[1m]",
          "tui": "fullscreen",
          "env": {
            "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
          }
        }

    If an "env" block already exists, add the key inside it rather than adding
    a second "env" block.

    This installer deliberately does not edit settings.json for you: it holds
    machine-specific preferences and permissions that should not be overwritten.

MSG
    ;;
esac
echo

# ------------------------------------------------------------------- summary --
bold "Installed"
echo "  4 agents  ->  ${AGENTS_DIR}/"
for a in "${AGENTS[@]}"; do echo "                ${a}.md"; done
echo "  1 skill   ->  ${SKILL_DIR}/SKILL.md"
echo
bold "Done."
echo
echo "  Restart Claude Code for the agents and skill to be picked up."
echo "  Then try:  /idea-council Should I add Redis to my application from day one?"
echo
