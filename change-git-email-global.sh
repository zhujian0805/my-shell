#!/bin/sh

OLD_EMAIL=shift
CORRECT_NAME=shift
CORRECT_EMAIL=shift

echo $OLD_EMAIL

git filter-branch -f --env-filter "

if [ $GIT_COMMITTER_EMAIL = $OLD_EMAIL ]
then
    export GIT_COMMITTER_NAME=$CORRECT_NAME
    export GIT_COMMITTER_EMAIL=$CORRECT_EMAIL
fi
if [ $GIT_AUTHOR_EMAIL = $OLD_EMAIL ]
then
    export GIT_AUTHOR_NAME=$CORRECT_NAME
    export GIT_AUTHOR_EMAIL=$CORRECT_EMAIL
fi
" --tag-name-filter cat -- --branches --tags
