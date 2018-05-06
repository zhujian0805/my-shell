# Tcp probe testing

# Success:

timeout 2 bash -c "</dev/tcp/www.baidu.com/80"; echo $? 

# Failure:
timeout 2 bash -c "</dev/tcp/canyouseeme.org/81"; echo $?
#124

# If you must preserve the exit status of bash,
timeout --preserve-status 2 bash -c "</dev/tcp/canyouseeme.org/81"; echo $?
#143
