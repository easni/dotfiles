# oh my zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell" # set by `omz`
plugins=(
  # git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# export PATH="/opt/homebrew/anaconda3/bin:$PATH"  # commented out by conda initialize

# For zoxide
eval "$(zoxide init --cmd cd zsh)"

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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
conda() {
  __conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  else
      if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
          . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
      else
          export PATH="/opt/homebrew/anaconda3/bin:$PATH"
      fi
  fi
  unset __conda_setup
}
# <<< conda initialize <<<

# google cloud project key for gemini-cli
export GOOGLE_CLOUD_PROJECT="fabric-443000"


# sessionizer
# bindkey -s ^t "~/tmux-sessionizer.sh\n"
alias t="~/.config/scripts/tmux-sessionizer.sh"

alias lvim='NVIM_APPNAME=nvim-lazy nvim'
alias cvim='NVIM_APPNAME=nvim-custom nvim'
alias kvim='NVIM_APPNAME=nvim-kickstart nvim'

alias vim='NVIM_APPNAME=nvim-kickstart nvim'

# Autocomplete for jj
autoload -U compinit
compinit
source <(jj util completion zsh)

# Open buffer line in editor
export VISUAL=vim
export EDITOR="$VISUAL"

# Edit prompt in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line


# Fix ssh terminal stuff acting weird for Ghostty
alias ssh="env TERM=xterm-256color ssh"
