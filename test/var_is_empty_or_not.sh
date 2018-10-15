if [ -z "$var" ]
then
      echo "\$var is empty"
else
      echo "\$var is NOT empty"
fi

if test -z "$var" 
then
      echo "\$var is empty"
else
      echo "\$var is NOT empty"
fi

[ -z "$var" ] && echo "Empty"
[ -z "$var" ] && echo "Empty" || echo "Not empty"

[[ -z "$var" ]] && echo "Empty"
[[ -z "$var" ]] && echo "Empty" || echo "Not empty"

## Check if $var is set using ! i.e. check if expr is false ##
[ ! -z "$var" ] || echo "Empty"
[ ! -z "$var" ] && echo "Not empty" || echo "Empty"

[[ ! -z "$var" ]] || echo "Empty"
[[ ! -z "$var" ]] && echo "Not empty" || echo "Empty"

go(){
   local empty
   local empty2=""
   [[ -z $empty ]] && echo "empty is null"
   [[ -z $empty2 ]] && echo "empty2 is null"
   [[ $empty == $empty2 ]] && echo "They are the same"
}

go
