#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PREFIX="${BRANCH_PREFIX:-cambio}"
MAX_BRANCHES="${MAX_CHANGE_BRANCHES:-4}"
REMOTE="${GIT_REMOTE:-origin}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: ESTE DIRECTORIO NO ES UN REPOSITORIO GIT." >&2
  exit 1
fi

if ! [[ "${MAX_BRANCHES}" =~ ^[0-9]+$ ]] || [[ "${MAX_BRANCHES}" -lt 1 ]]; then
  echo "ERROR: MAX_CHANGE_BRANCHES DEBE SER UN ENTERO >= 1." >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%d-%H%M%S)"
new_branch="${PREFIX}/${timestamp}"
suffix=1
while git show-ref --verify --quiet "refs/heads/${new_branch}"; do
  new_branch="${PREFIX}/${timestamp}-${suffix}"
  suffix=$((suffix + 1))
done

git checkout -b "${new_branch}"

mapfile -t managed_branches < <(
  git for-each-ref --format='%(refname:short)' "refs/heads/${PREFIX}/" | sort
)

if [[ "${#managed_branches[@]}" -le "${MAX_BRANCHES}" ]]; then
  echo "OK: RAMA CREADA ${new_branch}."
  echo "RAMAS ${PREFIX}/ ACTIVAS: ${#managed_branches[@]} (MÁXIMO ${MAX_BRANCHES})."
  exit 0
fi

to_remove=$(( ${#managed_branches[@]} - MAX_BRANCHES ))
removed=0

for old_branch in "${managed_branches[@]}"; do
  if [[ "${removed}" -ge "${to_remove}" ]]; then
    break
  fi
  if [[ "${old_branch}" == "${new_branch}" ]]; then
    continue
  fi

  git branch -D "${old_branch}"
  if git ls-remote --exit-code --heads "${REMOTE}" "${old_branch}" >/dev/null 2>&1; then
    git push "${REMOTE}" --delete "${old_branch}"
  fi
  removed=$((removed + 1))
done

echo "OK: RAMA CREADA ${new_branch}."
echo "RAMAS ELIMINADAS: ${removed}."
echo "RAMAS ${PREFIX}/ ACTIVAS: ${MAX_BRANCHES}."
