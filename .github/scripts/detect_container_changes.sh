#!/usr/bin/bash

set -euo pipefail

git cat-file -e "${BASE_SHA}^{commit}"
git cat-file -e "${HEAD_SHA}^{commit}"

changed_files="$(git diff --name-only "$BASE_SHA...$HEAD_SHA")"



echo "change files"
printf "%s\n" "$changed_files"

matrix="$(printf '%s\n' "$changed_files" | python3 .github/scripts/select_container_builds.py)"

count=$(printf '%s' "$matrix" | jq '.include | length')

selected_services=$(printf '%s' "$matrix" | jq -r '.include | map(.service) | join(",")')

echo "matrix=${matrix}" >> "${GITHUB_OUTPUT}"
echo "selected_services=$selected_services" >> "${GITHUB_OUTPUT}"

if [ $count -gt 0 ]; then
    echo "has_change=true" >> "${GITHUB_OUTPUT}"
else
    echo "has_change=false" >> "${GITHUB_OUTPUT}"
fi

{
  echo "### Container change detection"
  echo
  echo "- Base SHA: \`${BASE_SHA}\`"
  echo "- Head SHA: \`${HEAD_SHA}\`"
  echo "- Selected services: \`${selected_services:-none}\`"
} >> "${GITHUB_STEP_SUMMARY}"
