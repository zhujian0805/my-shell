#!/bin/sh
#set -o xtrace

date

if [ $# -eq 0 ]; then
    echo "Not enough arguments, at least one of pull, status, push"
    exit 0
fi
ACTION=$1


do_me (){
    ACT=$1
    shift
    DIR=$1
    echo "+++++++++++++++++++++++ Start doing $ACT on repo $dir +++++++++++++++++++++++++"

    cd "$DIR" || exit
    if [ x"$ACT" = x'push' ]
    then
        CHANGES=$(git status -s)
		git add .
		git commit -m "changes on $CHANGES"
		git push -u
    else
        git "$ACT"
    fi
    cd || exit
    echo "+++++++++++++++++++++++ Finished doing $ACT on repo $DIR +++++++++++++++++++++++++"

    cd || exit
}

for dir in *
do
    if [ -d "$dir/.git" ]; then

        case "$ACTION" in
            'pull') 
                    do_me "$ACTION" "$dir";;
            'push')
                    do_me "$ACTION" "$dir";;
            'status')
                    do_me "$ACTION" "$dir";;
            'checkout')
                    do_me "$ACTION" "$dir";;
            *)
                    echo "You must supply one push, status, pull"
                    break;;      
        esac           
        cd || exit
    fi
done
date
#set +o xtrace
