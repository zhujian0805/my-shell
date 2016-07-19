#!/bin/bash

Lines=0

#Using descriptor 3 as input, so the shell doesn't read from STDIN, which avoid subshell

exec 3< test.txt
while read line <&3
do {
  let "Lines++"
}
done
exec 3>&-

echo "Number of lines read = $Lines"     # 8

echo

read line

echo You inputed $line

exit 0
