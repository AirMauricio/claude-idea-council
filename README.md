# Claude Idea Council

A Claude Code decision-analysis system: four independent, read-only advisors that
each argue one lens at full strength, plus one skill that runs them, makes them
challenge each other where it matters, and synthesizes a single recommendation.

Built for ideas, technical decisions, architecture choices, product and business
calls — anything worth stress-testing before you commit to it.

## The four advisors

| Advisor | Lens |
|---|---|
| **Pragmatist** | Simplicity, speed, execution |
| **Skeptic** | Risks, false assumptions, failure modes |
| **Idealist** | Long-term correctness and the underlying problem |
| **Connector** | Prior art, patterns, dependencies and second-order effects |

None of them is asked to be balanced. Each one's bias is the point — the other
three cover what it deliberately ignores.

## The skill

    /idea-council

Claude acts as chairperson. The skill:

- gives all four agents the **same** context packet, verbatim
- runs them **independently**, in parallel
- **checks response integrity** — detects truncated, incomplete, malformed or
  duplicated responses, requests a continuation from the *same* agent rather than
  spawning a replacement, and never counts a duplicate as extra agreement
- **compares** their positions — agreement, disagreement, shared assumptions,
  risks, tradeoffs
- **verifies material factual claims** against primary sources rather than
  accepting them because an agent stated them confidently
- **conditionally runs one round of cross-examination**, only when a disagreement
  could actually change the decision
- supports **chair self-correction** — a correction made by the chair is itself a
  claim, and a specific, material challenge from an agent forces a re-check, with
  the chair withdrawing its correction openly if it turns out to be wrong
- **synthesizes without majority voting** — three-to-one means nothing; the lone
  dissenter is often the one who found the thing that matters

Output is fixed: decision, each advisor's position, agreement, disagreement,
recommendation, confidence, unknowns, next step.

## Requirements

- **Claude Code** installed
- **Agent Teams enabled** (see below)
- **Git**, for cloning and updating

### Enabling Agent Teams

The Council spawns subagents, which requires:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**Merge this into your existing `~/.claude/settings.json`. Do not replace the
file.** It holds your own machine-specific preferences and permissions.

If your settings currently look like this:

```json
{
  "model": "opus[1m]",
  "tui": "fullscreen"
}
```

the merged result should be:

```json
{
  "model": "opus[1m]",
  "tui": "fullscreen",
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

If you already have an `"env"` block, add the key *inside* it rather than adding a
second `"env"` block — JSON allows only one.

`install.sh` checks this setting and tells you what to do, but never edits the
file itself.

## Installation on another computer

```bash
git clone https://github.com/AirMauricio/claude-idea-council.git
cd claude-idea-council
./install.sh
```

Then **restart Claude Code**.

### Testing it

Invoke with no argument to be prompted for a decision:

```
/idea-council
```

Or pass the decision directly:

```
/idea-council Should I add Redis to my application from day one?
```

A good test gives the Council something with a real tradeoff. If you hand it a
question with an obvious answer, all four will agree and you will learn nothing.

## Updating another computer

```bash
cd ~/claude-idea-council
git pull
./install.sh
```

## Saving improvements made on the main computer

The canonical Council lives in `~/.claude/`. When you improve an agent or the
skill there, copy the changes back into the repository:

```bash
cd ~/claude-idea-council
./update-from-local.sh
git diff
```

Then, once you have reviewed the diff:

```bash
git add .
git commit -m "Update Idea Council"
git push
```

`update-from-local.sh` never commits or pushes. Reviewing the diff is the point —
these files are prompts, and a careless overwrite is easy to miss.

## Files

| Path | Purpose |
|---|---|
| `agents/` | The four advisor definitions. Each is a Markdown file with YAML frontmatter declaring its name, its delegation description, and its allowed tools. Installed to `~/.claude/agents/`. |
| `skills/idea-council/SKILL.md` | The chairperson workflow — context packet, integrity checks, comparison, evidence discipline, cross-examination, synthesis, output format. Installed to `~/.claude/skills/idea-council/`. |
| `install.sh` | Installs the agents and skill into `~/.claude/`. Verifies every file afterwards, byte-for-byte. Inspects `settings.json` read-only and reports on Agent Teams. |
| `update-from-local.sh` | The reverse: copies the live `~/.claude/` versions back into this repository so they can be committed. Refuses to run if any of the five source files is missing. |

## Safety

**The four advisors are read-only**, and not merely by instruction. Each agent's
own definition restricts its tools to `Read`, `Glob`, `Grep`, `WebSearch` and
`WebFetch` — no `Write`, no `Edit`, no `Bash`. They cannot modify your files even
if a prompt tells them to. The Council produces a judgement, not an
implementation.

**`~/.claude/settings.json` is deliberately not stored in this repository.** It
holds machine-specific preferences, permission grants and environment settings
that differ between computers and should never be overwritten by a checkout.
`install.sh` only reads it, to tell you whether Agent Teams is enabled and what
to add if it is not. Nothing in this repository writes to it.

No credentials or tokens belong in this repository. Git authentication is handled
by your own existing setup.
