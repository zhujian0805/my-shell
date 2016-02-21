declare -A l
for p in $(ps -ef|grep pytho[n]|awk '{print $9}')
do
	proc=`echo $p|awk -F'/' '{print $NF}'`
	l[$proc]=$p
done


for i in "${!l[@]}"
do
	echo "Key: " $i
    echo "Values: " ${l[$i]}
done
