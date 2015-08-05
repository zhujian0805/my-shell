#!/bin/bash

Lines=0

exec 3<> test.txt
while read line <&3
do {
  let "Lines++"
}
done
exec 3>&-

echo "Number of lines read = $Lines"     # 8

echo

exit 0
