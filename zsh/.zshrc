# oh my zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell" # set by `omz`
plugins=(
  # git
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# History
# setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# bindkey '^[[A' history-search-backward
# bindkey '^[[B' history-search-forward

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

alias ls="eza --icons=always"

# google cloud project key for gemini-cli
export GOOGLE_CLOUD_PROJECT="fabric-443000"


# sessionizer
# bindkey -s ^t "~/tmux-sessionizer.sh\n"
alias t="~/.config/scripts/tmux-sessionizer.sh"

# custom syncing script alias
alias syncpush="~/.config/scripts/sync-push.sh"
alias syncpull="~/.config/scripts/sync-pull.sh"

alias larp="fastfetch"


# Autocomplete for jj
autoload -U compinit
compinit
source <(jj util completion zsh)

# auto suggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Open buffer line in editor
export VISUAL=nvim
export EDITOR="$VISUAL"

# Edit prompt in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line


# Fix ssh terminal stuff acting weird for Ghostty
alias ssh="env TERM=xterm-256color ssh"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
conda() {
    __conda_setup="$('/home/easonni/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/home/easonni/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/home/easonni/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="/home/easonni/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<
}

function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

# >>> Codex installer >>>
export PATH="/home/easonni/.local/bin:$PATH"
# <<< Codex installer <<<
