#!/usr/bin/env bash

NOTES_DIR="$HOME/Documents/Notes"
OPEN_NOTES_ON_EXISTING_SESSION="false"

if [[ $# -eq 1 ]]; then
  selected=$1
else
  selected=$(
    {
      echo "$HOME/dotfiles"

      find "$HOME/" \
        -mindepth 1 -maxdepth 1 -type d
    } | fzf
  )
fi

# If nothing selected
if [[ -z $selected ]]; then
  exit 0
fi

# Make a safe tmux session name
# Keep letters, numbers, underscores, hyphens
selected_base=$(basename -- "$selected")
selected_name=$(printf '%s' "$selected_base" | tr -c 'a-zA-Z0-9_-' '_')

# Check if tmux is running
tmux_running=$(pgrep tmux)

# If session does not exist, create it detached. Also, track if we are creating a brand new session right now
session_existed=true
if ! tmux has-session -t "$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected"
  session_existed=false
fi

# --- NOTES SPECIFIC LOGIC ---
if [[ "$selected" == "$NOTES_DIR" ]]; then
  # The command to find/create and open the note
  cmd="selection=\$(find . -type f -name '*.md' | sed 's|^\./||; s/\.md$//' | fzf --bind 'ctrl-y:print-query' --print-query --header 'Select or Type New Note Path | Ctrl-y: Create New' | tail -1) && \
         if [[ -n \"\$selection\" ]]; then \
            mkdir -p \"\$(dirname \"\$selection\")\" && \
            vim \"\$selection.md\"; \
         fi"

  # Check if the session is "busy" (running nvim, fzf, or something else)
  # If the session was JUST created, it's obviously not busy.
  is_busy=false
  if [[ "$session_existed" == "true" ]]; then
    # Check the current command in the active pane
    current_cmd=$(tmux list-panes -t "$selected_name" -F '#{pane_current_command}')
    if [[ ! "$current_cmd" =~ ^(zsh|bash|sh|fish)$ ]]; then
      is_busy=true
    fi
  fi

  # Old Logic
  # if [[ "$is_busy" == "true" ]]; then
  #   # Create a new window specifically for this note
  #   tmux new-window -t "$selected_name" -n "Note" -c "$selected"
  #   tmux send-keys -t "$selected_name" "$cmd" Enter
  # else
  #   # Run it in the existing (idle) window
  #   tmux send-keys -t "$selected_name" "$cmd" Enter
  # fi

  if [[ "$is_busy" == "false" ]]; then
    # Run it in the existing (idle) window
    tmux send-keys -t "$selected_name" "$cmd" Enter
  fi
fi

# Switch to the session (or attach if outside tmux)
if [[ -n $TMUX ]]; then
  # Inside tmux: switch client
  tmux switch-client -t "$selected_name"
else
  # Outside tmux: attach to session
  tmux attach-session -t "$selected_name"
fi
