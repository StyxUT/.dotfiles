#
# ~/.bashrc
#

export KUBECONFIG=~/.kube/k3s.yaml

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias kc='kubectl'
alias vim='nvim'

source ~/git-prompt.sh
#PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
PS1='\[\e]0;\u@\h:\w\a\]\n${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[05;34m\]\w\[\033[03;33m\]$(__git_ps1) \$ ' 

source <(kubectl completion bash)

complete -o default -F __start_kubectl kc

# Created by `pipx` on 2024-12-11 02:33:37
export PATH="$PATH:/home/styxut/.local/bin"

neofetch
