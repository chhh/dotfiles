if [ $# -eq 0 ]
  then
    echo "No arguments supplied, provide path to home dir"
    exit
fi

echo "Args to [$0]=[$#], Destination: [$1]"

# Reminder how to read output of a command to an array in bash
# paths=()
readarray -d $'\0' paths < <(find . -maxdepth 1 -name "\.*" -type f -print0)
for p in ${paths[@]}; do
	echo "To copy: [$p]"
done

dest="$1"
find . -maxdepth 1 -type f -name "\.*" | xargs -I{} cp {} $dest


