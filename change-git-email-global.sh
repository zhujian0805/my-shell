#!/bin/sh

if [ $# -ne 3 ]
then
    echo "You must specify 3 parameters!!!"
    echo USAGE:
    echo "./$0 OLD_EMAIL CORRECT_EMAIL CORRECT_EMAIL"
    echo "This script is used to change the email address in the commit history"
    echo
    exit
fi

OLD_EMAIL=$1
CORRECT_NAME=$2
CORRECT_EMAIL=$3

SCRIPT_NAME=/tmp/fuckyou.sh

echo '#!/bin/sh' >$SCRIPT_NAME
echo >>$SCRIPT_NAME
echo "git filter-branch -f --env-filter '" >>$SCRIPT_NAME
echo 'if [ $GIT_COMMITTER_EMAIL =' "$OLD_EMAIL ]" >>$SCRIPT_NAME
echo then >>$SCRIPT_NAME
echo "    export GIT_COMMITTER_NAME=$CORRECT_NAME" >>$SCRIPT_NAME
echo "    export GIT_COMMITTER_EMAIL=$CORRECT_EMAIL" >>$SCRIPT_NAME
echo fi >>$SCRIPT_NAME
echo >>$SCRIPT_NAME
echo 'if [ $GIT_AUTHOR_EMAIL = '"$OLD_EMAIL ]" >>$SCRIPT_NAME
echo then >>$SCRIPT_NAME
echo '    export GIT_AUTHOR_NAME='"$CORRECT_NAME" >>$SCRIPT_NAME
echo '    export GIT_AUTHOR_EMAIL='"$CORRECT_EMAIL" >>$SCRIPT_NAME
echo fi >>$SCRIPT_NAME
echo "' --tag-name-filter cat -- --branches --tags" >>$SCRIPT_NAME

echo "Executing script $SCRIPT_NAME"
cat $SCRIPT_NAME
sh $SCRIPT_NAME
