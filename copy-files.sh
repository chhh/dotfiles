if [ $# -eq 0 ]
  then
    echo "No arguments supplied, provide path to home dir"
    exit
fi

dest="$1"
echo "Args to [$0]=[$#], Destination: [$dest]"

# Reminder how to read output of a command to an array in bash
# paths=()
readarray -d $'\0' paths < <(find . -maxdepth 1 -name "\.*" -type f -print0)
for p in ${paths[@]}; do
	echo "To copy: [$p] -> $dest"
done

read -p "Are you sure (y/n)? " -n 1 -r SURE
echo
#case "$SURE" in
#    y|Y ) echo "Copying...";;
#    n|N ) echo "Cancelled";;
#    * ) echo "Invalid choice, cancelled";;
#esac

if [[ $SURE =~ ^[Yy]$ ]]
then
    # do dangerous stuff
    echo "Copying..."
    find . -maxdepth 1 -type f -name "\.*" | xargs -I{} cp {} $dest
else
    echo "Cancelled"
fi

