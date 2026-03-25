#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-origin/main}"
branch_ref="${2:-HEAD}"
review_command="${MOODLE_PEER_REVIEW_COMMAND:-}"
max_files="${MOODLE_PEER_REVIEW_MAX_FILES:-0}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run inside a git repository." >&2
  exit 1
fi

if ! git show-ref --verify --quiet "refs/remotes/${base_ref}" && ! git rev-parse --verify --quiet "${base_ref}" >/dev/null; then
  echo "Base ref '${base_ref}' was not found. Try 'origin/main' or another valid ref." >&2
  exit 1
fi

base_commit="$(git merge-base "${base_ref}" "${branch_ref}")"
commit_list="$(git log --format='%h %s' "${base_commit}..${branch_ref}")"
diff_stat="$(git diff --stat "${base_commit}..${branch_ref}")"
diff_text="$(git diff --no-ext-diff --unified=3 "${base_commit}..${branch_ref}")"
skill_path=".agents/skills/moodle-peer-reviewer/SKILL.md"
skill_text=""

if [[ -f "${skill_path}" ]]; then
  skill_text="$(cat "${skill_path}")"
fi

if [[ -n "${max_files}" && "${max_files}" != "0" ]]; then
  file_count="$(printf '%s\n' "${diff_text}" | grep -c '^diff --git ' || true)"
  if [[ "${file_count}" -gt "${max_files}" ]]; then
    echo "This branch changes ${file_count} files, which is above MOODLE_PEER_REVIEW_MAX_FILES=${max_files}." >&2
    echo "Run with a higher limit or review the diff in chunks." >&2
    exit 1
  fi
fi

cat <<EOF
=== Moodle peer review runner ===
Base ref:   ${base_ref}
Branch ref: ${branch_ref}
Merge base: ${base_commit}

Commits included in this review:
${commit_list}

Diff summary:
${diff_stat}
EOF

if [[ -z "${review_command}" ]] || ! command -v "${review_command}" >/dev/null 2>&1; then
  if [[ -n "${review_command}" ]]; then
    echo
    echo "Configured review command '${review_command}' was not found on PATH."
    echo "Falling back to payload-only mode."
  else
    echo
    echo "No review command configured."
    echo "Falling back to payload-only mode."
  fi

  cat <<'EOF'

To make this run the review automatically, point MOODLE_PEER_REVIEW_COMMAND at a local command that reads the skill instructions and diff from standard input.

EOF
  echo "--- skill instructions ---"
  if [[ -n "${skill_text}" ]]; then
    printf '%s\n' "${skill_text}"
  else
    echo "Skill file not found at ${skill_path}."
  fi
  echo "--- diff to review ---"
  printf '%s\n' "${diff_text}"
  exit 0
fi

{
  printf '%s\n' "${skill_text}"
  printf '\n--- DIFF START ---\n'
  printf '%s\n' "${diff_text}"
} | "${review_command}"
