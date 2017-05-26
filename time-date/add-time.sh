time2=$((1*60*60+20*60))
time1=$(($time1 + $time2));
time1=$(date +%Y-%m-%d\ %H:%M:%S -d "1970-01-01 UTC $time1 seconds");
echo $time1
