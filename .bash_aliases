alias ll="ls -la --color=auto"

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