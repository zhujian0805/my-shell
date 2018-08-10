#!/bin/bash
#
# Cachewall init file to control the Varnish Cache logging daemon
#
# chkconfig: - 90 10
# description: Varnish Cache logging daemon
# processname: varnishlog
# config:
# pidfile: /var/run/varnishlog-${name:-debug}.pid

### BEGIN INIT INFO
# Provides: varnishlog
# Required-Start: $network $local_fs $remote_fs
# Required-Stop: $network $local_fs $remote_fs
# Default-Start:
# Default-Stop:
# Short-Description: start and stop varnishlog
# Description: Varnish Cache logging daemon
### END INIT INFO

. /etc/init.d/functions

action=$1 && shift

while getopts ":n:g:q:w:h:" opt; do
    case "$opt" in
    n)  name=${OPTARG//[^[:alnum:]]/}
        ;;
    g)  group=$OPTARG
        ;;
    q)  query=$OPTARG
        ;;
    h)  host=$OPTARG
        ;;
    w)  logfile=$OPTARG
        ;;
    *)
        action=""
        ;;
    esac
done

if [ -n "$host" ]; then
    name=${name:-${host//[^[:alnum:]]/}}
    query="ReqHeader ~ 'Host: (.*\.)?${host}'${query:+" and $query"}"
fi

query=${query:-"(VCL_Error,Error,VSL,FetchError or RespStatus == 503)"}
group=session

RETVAL=0
binary=/usr/bin/varnishlog
prog=varnishlog${name:+"-$name"}
lockfile=/var/lock/subsys/$prog
logfile=/var/log/$prog.bin
options="-D -P /var/run/$prog.pid -w $logfile -a -t off -g $group -q \"$query\""

start() {
    echo -n "Starting $prog: "

    if [ $UID -ne 0 ]; then
        RETVAL=1
        failure
    elif ! [ -x $binary ]; then
        RETVAL=1
        failure
    else
        daemon --pidfile=/var/run/$prog.pid $binary $options
        RETVAL=$?
        [ $RETVAL -eq 0 ] && touch $lockfile
    fi

    echo
    return $RETVAL
}

stop() {
    echo -n $"Stopping $prog: "

    if [ $UID -ne 0 ]; then
        RETVAL=1
        failure
    else
        killproc -p /var/run/$prog.pid $binary
        RETVAL=$?
        [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/$prog
    fi

    echo
    return $RETVAL
}

_status() {
    status -p /var/run/$prog.pid $prog || RETVAL=$?

    return $RETVAL
}

status_q() {
    _status &>/dev/null
}

case "$action" in
start)
    ! status_q && { start||: ; } || _status
    ;;
stop)
    status_q && { stop||: ; } || _status
    ;;
restart)
    status_q && { stop||: ; } || _status
    ! status_q && start
    ;;
status)
    _status
    ;;
list)
    lockfile=(/var/lock/subsys/varnishlog*)
    for lockfile in ${lockfile[@]%\*}; do
        prog=${lockfile##*/}
        if _status; then
            echo -en "\t"
            xargs -0 < /proc/$(cat /var/run/$prog.pid)/cmdline
            echo
        fi
    done
    ;;
stop-all)
    lockfile=(/var/lock/subsys/varnishlog*)
    for lockfile in ${lockfile[@]%\*}; do
        prog=${lockfile##*/}
        status_q && { stop||: ; } || _status
    done
    ;;
*)
    echo "Usage: $0 {start|stop|restart|status|list|stop-all} [-n NAME] [-h HOST] [-g GROUP] [-w LOGFILE] [-q QUERY]"
    RETVAL=2
    ;;
esac

exit $RETVAL

