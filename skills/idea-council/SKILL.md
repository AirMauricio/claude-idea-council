---
name: idea-council
description: Convene a four-perspective council (pragmatist, skeptic, idealist, connector) to evaluate an idea, technical decision, architecture choice, product or business decision, or important plan. Each subagent argues its own lens hard, they challenge each other where they disagree, and the main agent chairs and synthesizes a single recommendation. Use when the user invokes /idea-council, or asks for a decision to be stress-tested, pressure-tested, or evaluated from multiple angles before committing.
---

# Idea Council

You are the **chairperson** of a four-member council. Your job is not to have an
opinion up front — it is to put the decision in front of four strongly biased
advisors, let them argue, and then produce one synthesized judgement that is
better than any of them individually.

The four council members already exist as personal subagents in
`~/.claude/agents/`. **Use them. Do not recreate them, do not inline their
personalities, and do not simulate their answers yourself.**

| Agent | Lens |
|---|---|
| `pragmatist` | Simplicity, speed, shipping, 80/20 |
| `skeptic` | Risks, false assumptions, failure modes, worst case |
| `idealist` | Best long-term solution, real problem, technical debt |
| `connector` | Prior art, patterns, dependencies, second-order effects |

All four are read-only. This skill produces a judgement, not an implementation.

---

## Step 1 — Establish the decision

Restate the idea or decision in two to four sentences, in your own words. Be
specific about what is actually being decided, not just the topic area.

If the request is too vague to evaluate — no discernible decision, or a topic
rather than a choice — ask **one** clarifying question and stop. Otherwise
proceed; do not interrogate the user for detail the council can work without.

Then assemble a **context packet**. This is the single block of text every
agent receives, verbatim and identical. It contains:

- The restated decision.
- Any constraints the user gave: deadlines, budget, team size, existing stack,
  regulatory or contractual limits, non-negotiables.
- Relevant files, paths, or systems the agents should read (by path, so they can
  look for themselves — they have `Read`, `Glob`, `Grep`, `WebSearch`, `WebFetch`).
- What the user has already ruled in or out.

If the decision concerns a codebase, do a quick orienting pass first (locate the
relevant files, note the stack) so the packet points the agents somewhere real.
Keep it brief — the agents do their own digging.

## Step 2 — Convene the council

Spawn **all four agents in a single message** so they run in parallel. Each gets
the *same* context packet, plus a short instruction to apply its own lens at full
strength.

Do **not** ask any agent to be balanced, fair, or to acknowledge the other side.
The value of this skill comes from four uncompromised positions colliding. An
agent that pre-compromises has wasted its slot. Tell each one explicitly:

> Apply your lens at full strength. Do not soften your position for balance —
> three other perspectives are covering what you ignore.

Ask each for its own structured output (the agent definitions already specify
one) and for an explicit statement of the **assumptions** its position depends on.

Never write or predict an agent's response before it returns. If one fails to
return, say so in the output and chair the discussion without it rather than
inventing its position.

## Step 3 — Response integrity

Before you compare anything, confirm you actually have four usable responses.
A synthesis built on a half-delivered position is worse than no synthesis,
because it looks complete.

Check each returned response for:

- **Truncation** — cut off mid-sentence, mid-list, or mid-section, or carrying an
  explicit truncation marker from the transport.
- **Incompleteness** — a section the agent's own output format promises but never
  delivers.
- **Malformation** — garbled content, or a response that does not answer the packet.
- **Duplication** — the same position delivered twice, or a full response followed
  by a truncated copy of itself.

Then handle what you found:

- **Truncated or incomplete, and the missing content could materially affect the
  decision** — `SendMessage` that *same* agent by name and ask it to continue from
  where it stopped. Quote the last line you received so it knows where to resume.
- **Do not spawn a replacement agent for a truncation.** A fresh instance has lost
  the original analysis and will produce a different position. Substituting it
  silently changes the council's composition while appearing not to.
- **Minor truncation** may be ignored only when the missing portion clearly cannot
  change the decision. When you do this, say so in the output in one line — which
  agent, what was lost, why it does not matter.
- **Never synthesize a materially incomplete position** on the grounds that enough
  survived. Recover it or report it as incomplete.
- **Duplicates are one response.** Deduplicate before comparing. Never count a
  duplicate as additional agreement, corroboration, or consensus — agreement means
  two agents reasoning independently, and a transport artifact is not a second agent.
- **An agent that never returns** — chair without it and say so plainly in the
  output. Do not infer or invent its position.

## Step 4 — Compare

With all four responses in hand, map them against each other:

- **Agreement** — conclusions two or more agents reached independently. Note when
  agents with opposing biases agree; convergence from the pragmatist and the
  idealist is far stronger evidence than either alone.
- **Disagreement** — where they genuinely conflict. Distinguish a *real* conflict
  (they want incompatible things) from a *framing* conflict (same recommendation,
  different vocabulary). Only the first is worth arguing.
- **Assumptions** — what each position rests on, and which assumptions are shared
  by all four. A shared unexamined assumption is the council's blind spot; name it.
- **Risks** — from the skeptic, but also risks implied by the others: the
  pragmatist's cut list, the idealist's debt, the connector's blast radius.
- **Tradeoffs** — the axes the decision actually turns on (speed vs. durability,
  scope vs. certainty, build vs. adopt).

Agreement is something you *observe*, never something you engineer. Do not nudge
agents toward each other, do not ask them to moderate, and do not treat a lens as
having failed because it stayed in character. The pragmatist arguing for speed, the
skeptic for caution, the idealist for durability, and the connector for precedent are
each doing the job correctly. Convergence is only evidence when it was independent.

## Step 5 — Evidence discipline

Advisors produce arguments, not facts. Before anything an agent said becomes load
in your recommendation, sort it into one of five kinds and treat each differently:

| Kind | What it is | How it may be used |
|---|---|---|
| **Verified fact** | You checked it this session against a primary source | State plainly |
| **Agent claim** | An agent asserted it; unchecked | Attribute, or verify and promote |
| **Assumption** | A premise, stated by an agent or by you | Label as such; carry to Unknowns |
| **Inference** | A conclusion drawn from the above | Show what it rests on |
| **Opinion** | A judgement call — not verifiable, not meant to be | Attribute to its advisor |

Rules:

- **Fluency is not evidence.** An agent stating something flatly and confidently is
  not a reason to promote it to fact. These agents can be wrong in exactly the
  register that sounds right.
- **Verify material factual claims when practical.** This covers claims about the
  codebase, architecture, dependencies, configuration, security behaviour, external
  product capabilities, documentation, APIs, laws, standards, and pricing.
  - Codebase claims — `Read`, `Glob`, `Grep` the actual files and check the
    implementation, rather than accepting a description of it.
  - External or current claims — `WebSearch` / `WebFetch` the primary source.
    Prefer vendor documentation over blog posts and over your own recollection.
- **Prioritize by load, not by curiosity.** Verify what could change the
  recommendation. A claim that is merely colour can stay attributed to its agent.
- **Do not verify subjective judgements, strategic opinions, or obviously
  non-load-bearing detail.** That is not diligence, it is stalling.
- **If a material claim cannot be verified**, keep it explicitly labelled unverified
  or assumed everywhere it appears, and carry it into `Unknowns`.
- **If verification contradicts an agent, the verified version wins and the
  correction is stated.** Say what the agent claimed, what is actually the case, and
  where you checked. Never silently repair an agent's factual mistake — the error is
  itself information about how much weight that agent's other claims deserve.
- **A confirmation is worth a clause, not a paragraph.** Report verification
  proportionally; only contradictions need room.

### Chair self-correction

The rules above point one way — chair checks agent. They apply symmetrically. The
chair is not a privileged source of truth, and a correction issued from the chair is
itself a factual claim, open to challenge on the same terms as the claim it corrected.

When an agent pushes back on a correction you made:

- **Re-check the disputed fact.** Do not dismiss the pushback on the grounds that you
  already verified once. One verification is one reading of one source; it can be the
  wrong source, or the right source read too quickly.
- **Re-verify against the strongest practical source** — primary documentation, the
  repository itself, the authoritative specification — in preference to secondary
  summaries or your own earlier summary of a source.
- **Compare what each source actually claims.** Adjacent-but-different facts are the
  usual trap: a statement about a default handler is not a statement about a platform's
  handler, and a statement about one version or plan tier is not a statement about
  another. Establish that the two claims are about the same thing before calling either
  one wrong.
- **If your correction was wrong or incomplete, withdraw or revise it explicitly.** Say
  what you asserted, what the evidence shows, and that you are withdrawing it. Do not
  quietly rewrite the synthesis so that it reads as though you had been right.
- **If both sides were partly right, separate the claims** and say which part each
  source supports. This is the most common outcome and the least satisfying to write.
- **If the evidence stays ambiguous, label the point unresolved** and carry it into
  `Unknowns` when it could change the recommendation.
- **Weight by evidence, never by role.** A chair correction gets no extra credit for
  coming from the chair, and an agent claim none for being confidently worded.

**Trigger threshold — do not re-open every disagreement.** Re-check only when the
pushback is all three of:

1. **Specific** enough to verify,
2. **Supported** by a concrete reason, source, mechanism, code location, or piece of
   contradictory evidence, and
3. **Material** — resolving it could change the recommendation, the confidence, the
   disagreement analysis, or an important implementation choice.

Spend nothing on stylistic disagreement, subjective judgement, already-settled
semantics, immaterial detail, or a bare "I think you're wrong" with no reason attached.
The goal is getting the fact right, not exhausting the objection.

**This is an evidence exception, not a debate round.** It does not count against the
cross-examination cap in Step 6 and may occur after that round has closed. Keep it
narrowly scoped to the disputed fact: do not reopen adjacent arguments, do not
re-litigate positions, and never start a fresh council over it. Where the disputed
point needs the agent's own clarification, use the existing instance.

## Step 6 — Cross-examination (only when it earns its place)

If there is a **material** disagreement — one where choosing differently changes
what the user should actually do — put it back to the relevant agents.

Send each involved agent the opposing position and ask a narrow question:

> The {other agent} argues: "{concise statement of their position, with reasoning}".
> Does this change your recommendation? If not, say specifically why it is wrong
> or why the cost it names is worth paying. Be brief.

Keep this to one round and to the one or two disagreements that matter. Use
`SendMessage` to the existing agents so they keep their context rather than
spawning fresh ones. Skip this step entirely when the disagreements are cosmetic
— say so rather than manufacturing a debate.

The one-round cap governs *argument*. It does not govern *evidence*: a factual
challenge meeting the Step 5 trigger threshold may be re-checked after this round has
closed, under **Chair self-correction**, which is scoped to the disputed fact alone.

## Step 7 — Chair the synthesis

Before you write a word of the recommendation, confirm internally — silently, as a
precondition, not as output:

- All four agents were invoked.
- Four usable responses were received.
- Any material truncation was recovered from the original agent.
- Duplicate transport deliveries were collapsed, and none were counted as agreement.
- Material factual claims you are about to rely on were verified where practical.
- No correction *you* made is still under a specific, material, unresolved challenge
  from an agent; and any of your corrections since shown wrong has been explicitly
  withdrawn or revised.
- Every fact in the recommendation is the best-supported version, whether it came from
  an agent or from you.
- Unverified assumptions that remain load-bearing are carried into `Unknowns`.
- Any cross-examination that was warranted has completed.

**Do not print this checklist.** If every item holds, say nothing about it and write
the synthesis. Mention it only where something failed — a position that arrived
incomplete, an agent that never returned, a claim you could not verify, a correction of
yours you had to withdraw — and then only the item that failed, in a line, where the
reader needs it. A chair error that materially affected the analysis is named briefly
in the final answer; it does not turn the output into an audit log.

You now decide. Some rules for this:

- **Do not vote.** Three-to-one means nothing; the lone dissenter is often the
  one who found the thing that matters. Weigh arguments, not headcount.
- **Do not split the difference** to keep everyone happy. A synthesis that
  half-builds the ideal and half-ships fast is usually worse than either.
- **Weight by the situation.** The pragmatist is right when the decision is cheap
  to reverse and the information is thin. The idealist is right when the choice is
  foundational and expensive to unwind. The skeptic is right when the downside is
  severe or hard to detect. The connector is right when the problem is well-trodden.
  State which of these conditions holds — that is the actual reasoning.
- **Name what you are giving up.** Every recommendation discards something a
  council member wanted. Say what, and why it is an acceptable loss.
- Adopt a member's position wholesale when it is simply correct. Synthesis does not
  require a novel fifth answer.

---

## Output format

Produce exactly these sections, in this order.

```
## Decision being evaluated
Concise restatement — what is actually being decided.

## Pragmatist
The main practical argument. The simplest version, what to cut, what ships first.

## Skeptic
The main risks and weaknesses. Load-bearing assumptions, failure modes, worst case.

## Idealist
The best long-term approach. The real problem, the ideal shape, the debt at stake.

## Connector
Relevant patterns, prior art, dependencies, and second-order effects.

## Agreement
What the council converged on — especially where opposing lenses agreed.

## Disagreement
The most important conflicts and the tradeoff each one turns on. Include the
cross-examination outcome where one happened: who moved, who held, and why.

## Recommendation
Your synthesized judgement as chairperson. Specific and actionable. State the
reasoning that drove the weighting, and name what you are deliberately giving up.
Not a vote, not an average.

## Confidence
High / Medium / Low, with a one-line reason. Anchor it: High = the council
converged and the assumptions are verified. Medium = a real tradeoff remains but
the direction is clear. Low = the recommendation rests on an unverified assumption
or the council genuinely split on something material.

## Unknowns
Information that would materially change the recommendation — and, where it is
cheap to find out, how to find out.

## Next step
One concrete action. A single thing the user can do next, not a list.
```

Keep each agent section to its strongest argument — a few sentences to a short
paragraph. You are reporting a position, not transcribing a report. The council's
value is in the comparison, so `Disagreement` and `Recommendation` should be the
substantial sections.

Hold the agents' outputs at arm's length. They are advisors and they can be
wrong; if one asserts something about the codebase or the world that you can
check, check it before it lands in your recommendation.
