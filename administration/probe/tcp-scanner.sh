# Scripts
# http://www.catonmat.net/blog/tcp-port-scanner-in-bash/
for port in {1..65535}; do
    echo >/dev/tcp/baidu.com/$port &&
    echo "port $port is open" || echo "port $port is closed"
done
