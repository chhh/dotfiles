if status is-interactive
    # Commands to run in interactive sessions can go here
    #any-nix-shell fish --info-right | source # should in theory allow my fish shell in nix-shell
end


#source ~/.aliases

alias ls="eza $argv"
alias ll="eza -ll $argv"

