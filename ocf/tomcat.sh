#!/bin/bash
#
#  Copyright LINBIT, 2008
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation; either version 2, or (at your option) any
#  later version.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; see the file COPYING.  If not, write to the
#  Free Software Foundation, Inc.,  675 Mass Ave, Cambridge, 
#  MA 02139, USA.
#

#
# Tomcat resource management using the tomcatadm utility.
#

LC_ALL=C
LANG=C
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export LC_ALL LANG PATH

. $(dirname $0)/ocf-shellfuncs

tomcat_verify_all()
{
    if [ ! -d $OCF_RESKEY_startfile ];
    then
       return $OCF_ERR_GENERIC
    fi
    return 0
}

tomcat_status() {

    nc -zv localhost $OCF_RESKEY_portnum >/dev/null 2>&1
    case $? in
    0)
        return $OCF_SUCCESS
        ;;
    *)
        return $OCF_NOT_RUNNING
        ;;

    esac
    return $OCF_ERR_GENERIC
}

tomcat_start() {
    sh $OCF_RESKEY_startfile; 
}

tomcat_stop() {
    sh $OCF_RESKEY_stopfile;
}


if [ -z "$OCF_CHECK_LEVEL" ]; then
    OCF_CHECK_LEVEL=0
fi

# This one doesn't need to pass the verify check
case $1 in
    meta-data)
    cat `echo $0 | sed 's/^\(.*\)\.sh$/\1.metadata/'` && exit 0
    exit $OCF_ERR_GENERIC
    ;;
esac

# Everything else does
tomcat_verify_all || exit $?
case $1 in
    start)
    if tomcat_status; then
        ocf_log debug "Tomcat resource ${OCF_RESKEY_name} is already running"
        exit 0
    fi
    tomcat_start
    if [ $? -ne 0 ]; then
        exit $OCF_ERR_GENERIC
    fi

    exit $?
    ;;
    stop)
    if tomcat_status; then
        tomcat_stop
        if [ $? -ne 0 ]; then
        exit $OCF_ERR_GENERIC
        fi
    else
        ocf_log debug "Tomcat resource ${OCF_RESKEY_name} was already stoped"
    fi
    exit 0
    ;;
    status|monitor)
    tomcat_status
    exit $?
    ;;
    restart)
    $0 stop || exit $OCF_ERR_GENERIC
    $0 start || exit $OCF_ERR_GENERIC
    exit 0
    ;;
    verify-all)
        exit 0
        ;;
    *)
    echo "usage: $0 {start|stop|status|monitor|restart|meta-data|verify-all}"
    exit $OCF_ERR_GENERIC
    ;;
esac
