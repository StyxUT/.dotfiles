#
# ~/.bashrc
#

export HOME=/home/styxut
export KUBECONFIG=~/.kube/k3s.yaml
export EDITOR=/usr/bin/vim

# ollama
export OLLAMA_HOST=0.0.0.0
export HIP_VISIBLE_DEVICES=0
export CUDA_VISIBLE_DEVICES=-1  # hide NVIDIA devices
export OLLAMA_LLAMA_EXTRA_ARGS="--flash-attn"  #use Flash Attention
# gaming
export DRI_PRIME=1
export WLR_RENDERER=vulkan

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias kc='kubectl'
alias rm='rm -I'
alias rider='/home/styxut/.local/share/JetBrains\ Rider-2024.3.4/bin/rider.sh &' 

# bash parameter completion for the dotnet CLI
function _dotnet_bash_complete()
{
  local cur="${COMP_WORDS[COMP_CWORD]}" IFS=$'\n' # On Windows you may need to use use IFS=$'\r\n'
  local candidates

  read -d '' -ra candidates < <(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)

  read -d '' -ra COMPREPLY < <(compgen -W "${candidates[*]:-}" -- "$cur")
}
complete -f -F _dotnet_bash_complete dotnet

# have vim call nvim, and sudo vim call sudo -E nvim
vim() {
    if [ "$EUID" -eq 0 ]; then
        sudo -E nvim "$@"
    else
        nvim "$@"
    fi
}
export -f vim

source ~/git-prompt.sh
#PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
PS1='\[\e]0;\u@\h:\w\a\]\n${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[05;34m\]\w\[\033[03;33m\]$(__git_ps1) \$ ' 

source <(kubectl completion bash)

complete -o default -F __start_kubectl kc

# Created by `pipx` on 2024-12-11 02:33:37
export PATH="$PATH:/home/styxut/.local/bin"
export PATH="$PATH:/home/styxut/go/bin"
neofetch

# opencode
export PATH=/home/styxut/.opencode/bin:$PATH
