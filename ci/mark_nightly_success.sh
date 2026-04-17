#!/usr/bin/env bash
set -euo pipefail

# Marks the current HEAD as the last successful nightly run by force-updating a git tag.
# CircleCI must have push permission (SSH key recommended).

TAG_NAME="${NIGHTLY_LAST_SUCCESS_TAG:-nightly-last-success}"
CURRENT_SHA="$(git rev-parse HEAD)"

echo "[nightly-mark] Updating ${TAG_NAME} -> ${CURRENT_SHA}"

git tag -f "${TAG_NAME}" "${CURRENT_SHA}"

git push -f origin "refs/tags/${TAG_NAME}"
