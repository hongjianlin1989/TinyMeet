#!/usr/bin/env bash
set -euo pipefail

# Exit codes:
#  0 => SHOULD run nightly build (new commits since last successful nightly)
#  1 => SKIP nightly build (no changes)
#
# This uses a movable git tag on origin to remember the last successful nightly SHA.
# CircleCI must have push permission to update the tag.

TAG_NAME="${NIGHTLY_LAST_SUCCESS_TAG:-nightly-last-success}"

# Ensure we have tags.
git fetch --tags --force

CURRENT_SHA="$(git rev-parse HEAD)"

LAST_SHA=""
if git rev-parse -q --verify "refs/tags/${TAG_NAME}" >/dev/null; then
  LAST_SHA="$(git rev-list -n 1 "${TAG_NAME}")"
fi

echo "[nightly-gate] tag=${TAG_NAME} last=${LAST_SHA:-<none>} current=${CURRENT_SHA}"

if [[ -n "${LAST_SHA}" && "${LAST_SHA}" == "${CURRENT_SHA}" ]]; then
  echo "[nightly-gate] No new commits since last nightly. Skipping."
  exit 1
fi

echo "[nightly-gate] New commits detected (or first run). Proceeding."
exit 0
