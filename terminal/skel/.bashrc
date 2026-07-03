export TERM=xterm-256color
export EDITOR=vim
export PATH="$HOME/.local/bin:$PATH"

G='\[\033[1;32m\]'; W='\[\033[1;37m\]'; R='\[\033[0m\]'
# Use CTF_HOSTNAME env var (set per-container); fallback to kernel hostname
PS1="${G}[${W}\u@\${CTF_HOSTNAME:-\h}${G}:${W}\w${G}]\$${R} "

alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias grep='grep --color=auto'
