alias ll="ls -la --color=auto"
alias la="ls -lA --color=auto"

alias wd='echo ${PWD##*/}'

nas-create-repo() {
    USERNAME=dima
    HOSTS="192.168.1.191"
    PORT=12022

    REPO=$1

    if [[ -z "${REPO}" ]]; then
        echo "Empty repo name, stopping"
        return 1
    fi

    SCRIPT="cd /volume1/git; mkdir ${REPO}; cd ${REPO}; git init --bare;"
    for HOSTNAME in ${HOSTS} ; do
        ssh -l ${USERNAME} -p ${PORT} ${HOSTNAME} "${SCRIPT}"
    done

}

git-add-nas() {
    dir=$1
    cmd="git remote add nas ssh://dima@192.168.1.191:12022/volume1/git/${dir}"
    echo "Cmd: ${cmd}"
    ask-and-run "${cmd}"
    #$(ask-and-stop) && return 0
    #echo "Got throuhgh!"
}

ask-and-stop() {
    read -n 1 -p "Stop now? (y/n)" and;
    printf "\n"
    case $and in
        y|Y)
            echo "Stopping."
            sExit && return 0 
            ;;
        *)
            ;;
    esac
    printf "Proceeding...\n"
}

function die() {
    set -e
    /bin/false
}

function sExit() {
    [ "X$(basename $0 2>/dev/null)" = "X$(basename $BASH_SOURCE)" ] && exit 0 || return 0
}

ask-and-run() {
echo "Command to run:"
echo $1
read -n 1 -p "Would you like to proceed? (y/n/c)" ans;
printf "\n"
case $ans in
    y|Y)
        eval $1
        ;;
    *)
        printf "\nNot running, exiting.\n"
        ;;
esac
}

gka() {
    gitk --all
}

gkaw() {
    gitk --all --since="$1".weeks
}

gkam() {
    gitk --all --since="$1".months
}

gkgw() {
    gitk --glob="$1" --since="$2".weeks
}

gkgm() {
    gitk --glob="$1" --since="$2".months
}

git_leafs_local() {
        echo "** Below is list of tip branches a.k.a. final nodes."
        echo "** These aren't reachable from any other branches."
        echo "** Removing them is potentially DANGEROUS: it would make some commit unreachable."
        TIPS=$( git rev-list --branches --children | grep -v ' ' | sort )
        { while read branchname commitid message
                do grep $commitid < <(echo $TIPS) -q && echo $branchname
                done
        } < <(git branch -v --no-abbrev | sed 's/\*//' )
        echo "** end of list"
}

git_leafs_origin() {
        echo "** Below is list of tip branches a.k.a. final nodes."
        echo "** These aren't reachable from any other branches."
        echo "** Removing them is potentially DANGEROUS: it would make some commit unreachable."
        TIPS=$( git rev-list --remotes=origin --children | grep -v ' ' | sort )
        { while read branchname commitid message
                do grep $commitid < <(echo $TIPS) -q && echo $branchname
                done
        } < <(git branch -v --no-abbrev | sed 's/\*//' )
        echo "** end of list"
}
