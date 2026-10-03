#!/usr/bin/env bash
set -euo pipefail

hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'

# Work around Hyprland 0.56's stale frame on resume until pointer activity.
# cursor.move invokes simulateMouseMovement even at the current position.
# Retry briefly while the GPU resumes; never click, type, or unlock.
for delay in 0.2 0.5 1; do
    sleep "$delay"
    pgrep -x -u "$UID" hyprlock >/dev/null || exit 0
    position=$(hyprctl -j cursorpos | jq -er '
        select((.x | type) == "number" and (.y | type) == "number")
        | "{ x = \(.x), y = \(.y) }"')
    hyprctl dispatch "hl.dsp.cursor.move($position)"
done
