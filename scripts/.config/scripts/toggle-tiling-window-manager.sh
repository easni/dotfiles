#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Tiling Window Manager
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.description Toggle Aerospace, Jankyborders, and Sketchybar

STATE_FILE="/tmp/aerospace_disabled_flag"

if [ -f "$STATE_FILE" ]; then
  # --- TURN EVERYTHING ON ---
  aerospace enable on

  # Pre-emptively kill any ghost border processes
  # pkill -x borders
  # pkill -x sketchybar

  # Start borders (adjust path if 'borders' isn't in your $PATH)
  # borders active_color=0xffeb212e inactive_color=0x00000000 width=5.0 &
  # borders &
  sketchybar &

  rm "$STATE_FILE"
  echo "AeroSpace & Sketchybar: ON"
else
  # --- TURN EVERYTHING OFF ---
  aerospace enable off
  # pkill -x borders
  pkill -x sketchybar
  touch "$STATE_FILE"
  echo "AeroSpace & Sketchybar: OFF"
fi
