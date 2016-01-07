#!/bin/bash
#

VERSION="$0"
ARCHIVE="http://www.eu.apache.org/dist/cassandra/$VERSION/apache-cassandra-$VERSION-bin.tar.gz"

sudo mkdir -m 777 /tmp/cassandra
cd /tmp/cassandra
sudo wget -c -O "apache-cassandra-$VERSION-bin.tar.gz" "$ARCHIVE"
sudo tar -zxvf "apache-cassandra-$VERSION-bin.tar.gz"
sudo mv "apache-cassandra-$VERSION" /opt/cassandra

sudo useradd cassandra
sudo install -d -o cassandra -m 755 /opt/cassandra/data
sudo install -d -o cassandra -m 755 /opt/cassandra/logs

sudo chown -R cassandra /opt/cassandra

# export PATH=$PATH:/opt/cassandra/bin
# source ~/.profile

echo '#!/bin/sh
# chkconfig: 2345 80 45 
# description: Starts and stops Cassandra 
# update deamon path to point to the cassandra executable 

CASS_HOME=/opt/cassandra
CASS_BIN="$CASS_HOME/bin/cassandra"
CASS_PID="$CASS_HOME/cassandra.pid"

start() { 
    if [ -f $CASS_PID ]; then 
        echo "Cassandra is already running." 
        exit 0 
    fi 

    echo -n "Starting Cassandra... "
    
    start-stop-daemon -S -c cassandra -a "$CASS_BIN" -q -p "$CASS_PID" -t
    start-stop-daemon -S -c cassandra -a "$CASS_BIN" -b -p "$CASS_PID" -- -p "$CASS_PID"
    
    echo "OK"
    return 0
}

stop() { 
    if [ ! -f $CASS_PID ]; then
        echo "Cassandra is already stopped."
        exit 0
    fi

    echo -n "Stopping Cassandra... " 

    #kill $(cat $CASS_PID) 
    start-stop-daemon -K -p "$CASS_PID" -R TERM/30/KILL/5 >/dev/null
    RET=$?
    rm -f "$CASS_PID"
    return $RET
}

status_fn() { 
    if [ -f $CASS_PID ]; then 
        echo "Cassandra is running." 
        exit 0 
    else 
        echo "Cassandra is stopped." 
        exit 1 
    fi
}

case "$1" in 
    start) 
        start 
        ;; 
    stop) 
        stop 
        ;; 
    status) 
        status_fn 
        ;; 
    restart) 
        stop 
        start 
        ;; 
    *) 
        echo $"Usage: $prog {start|stop|restart|status}" 
        exit 1 
esac 

exit $?
' | sudo tee /etc/init.d/cassandra

sudo chmod +x /etc/init.d/cassandra
sudo update-rc.d cassandra defaults
