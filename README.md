# Moodle peer review helper

This guide shows how Moodle developers can run peer reviews locally in their dev site using GitHub Copilot in PhpStorm or VS Code.

The reviewer instructions come from the `moodle-peer-reviewer` skill:

- https://github.com/lameze/moodle-skills/blob/main/SKILL.md

## 1) Install the skill locally

Install the skill into your local skills setup first:

```bash
npx skills add lameze/moodle-skills --skill moodle-peer-reviewer
```

This makes the `moodle-peer-reviewer` skill available locally.

## 2) Open your Moodle branch in PhpStorm or VS Code

Make sure you are on the branch you want to review, for example:

- `MDL-85498-main`

The helper script will automatically compare your current branch against `origin/main`.

## 3) Run the peer review helper

From the Moodle repository root, run:

```bash
curl -fsSL https://raw.githubusercontent.com/lameze/moodle-skills/main/tools/moodle-peer-review.sh | bash
```

The script will:

- detect the merge base with `origin/main`
- collect the commits in the current branch
- build the diff to review
- load the `moodle-peer-reviewer` skill instructions

If you prefer, you can also copy that script into your own `PATH` and run it locally from there.

## 4) Use GitHub Copilot in PhpStorm or VS Code

Open GitHub Copilot chat or the agent/review UI in your editor.

Then ask Copilot to perform the review using the Moodle peer reviewer skill and the diff that the helper script produced.

A good prompt is:

- review this patch using the `moodle-peer-reviewer` skill
- follow the Moodle checklist exactly
- report findings using the required format

### Sample prompt

You can paste something like this into Copilot:

> Review the current branch patch using the `moodle-peer-reviewer` skill. Follow the Moodle peer review checklist exactly. Focus on security, access control, sesskey usage, correct parameter validation, UI/output safety, database performance, and whether bug fixes include PHPUnit or Behat tests. Return your answer in the required format with:
> 1. Executive Summary
> 2. The Checklist
> 3. Detailed Findings
> 4. Proposed Fixes
>
> Treat the branch diff as the only input. If you find a problem, explain why it matters in Moodle and suggest a concrete fix.

## 5) For automated local runs, connect a wrapper command

If you want the helper to send the assembled review input automatically, set:

```bash
export MOODLE_PEER_REVIEW_COMMAND=/path/to/your-review-wrapper
```

Your wrapper command should read stdin and call your local review tool or Copilot-based workflow.

Example wrapper pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
# Replace this with your local model, CLI, or agent call.
printf '%s\n' "$input"
```

Save that as `my-local-reviewer`, make it executable, and put it on your `PATH`.

## 6) Example for a branch with two commits

If your branch is `MDL-85498-main` and it has two commits on top of `origin/main`, the helper will automatically show exactly those two commits and the full patch.

## What the helper does

The helper:

- finds the merge base between your branch and `origin/main`
- lists the commits included in the review
- prints the diff summary
- sends the assembled review payload to your local review command when configured

## Notes

- The helper is intentionally simple so it works in a plain Moodle git clone.
- For large branches, you may want to review file-by-file by adding a path to `git diff` manually.
- You can limit very large reviews with `MOODLE_PEER_REVIEW_MAX_FILES` if needed.
- If no review command is configured, the helper falls back to payload-only mode instead of failing hard.
