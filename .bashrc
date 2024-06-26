# Taken from: https://github.com/bobthecow/git-flow-completion/blob/master/git-flow-completion.bash
#source ~/git-flow-completion.bash


if [[ -n "${ConEmuPID}" ]]; then
  PS1="$PS1\[\e]9;9;\"\w\"\007\e]9;12\007\]"
fi

if [ -e $HOME/.aliases ]; then
    source $HOME/.aliases
fi
if [ -e $HOME/.aliases-bash ]; then
    source $HOME/.aliases-bash
fi

# This is used to start ssh-agent once when git-bash is started.
# Saves typing the ssh key password every time you interact with
# a remote repo.

# Usage of USERPROFILE variable requires an extra Env Var to be set:
#   WSLENV=USERPROFILE/up
#
#key_file=~/.ssh/dmtavt-home-desktop_rsa
key_file=$USERPROFILE/.ssh/id_rsa
env=~/.ssh/agent.env

agent_load_env () { test -f "$env" && . "$env" >| /dev/null ; }

agent_start () {
    (umask 077; ssh-agent >| "$env")
    . "$env" >| /dev/null ; }

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    ssh-add $key_file
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    ssh-add $key_file
fi

unset env

