#!/bin/sh
# chkconfig: - 99 01
# description: Oxidized - Network Device Configuration Backup Tool
# processname: /opt/ruby-2.1/bin/oxidized

# Source function library
. /etc/rc.d/init.d/functions

name="oxidized"
desc="Oxidized"
cmd=oxidized
args="--daemonize"
lockfile=/var/lock/subsys/$name
pidfile=/etc/oxidized/pid

export OXIDIZED_HOME=/etc/oxidized

# Source sysconfig configuration
[ -r /etc/sysconfig/$name ] && . /etc/sysconfig/$name

start() {
    echo -n $"Starting $desc: "
    daemon ${cmd} ${args}
    retval=$?
    if [ $retval = 0 ]
    then
        echo_success
        touch $lockfile
    else
        echo_failure
    fi
    echo
    return $retval
}

stop() {
    echo -n $"Stopping $desc: "
    killproc -p $pidfile
    retval=$?
    [ $retval -eq 0 ] && rm -f $lockfile
    rm -f $pidfile
    echo
    return $retval
}

restart() {
    stop
    start
}

reload() {
  echo -n $"Reloading config..."
  curl -s http://localhost:8888/reload?format=json -O /dev/null
  echo
}

rh_status() {
    status -p $pidfile $cmd
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart)
        $1
        ;;
    reload)
        rh_status_q || exit 0
        $1
        ;;
    status)
        rh_status
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart|reload|status}"
        exit 2
esac
