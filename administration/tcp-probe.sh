LOG=${0}.log
exec 6>&1
exec >> ${LOG} 2>&1

while true
do
    if timeout 1 bash -c 'echo > /dev/tcp/10.113.192.11/22' 
    then
        echo -n $(date) tcp socket made succesfully to 10.113.192.11 22
        echo
    else
        echo -n $(date) tcp socket made failed to 10.113.192.11 22
        echo
    fi
    sleep 1
done

exec 1>&6
exec 6>&-
