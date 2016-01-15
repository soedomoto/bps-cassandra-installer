#!/bin/bash
#

PRIVIP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
PUBIP=$(wget ident.me -qO-)

if [ ! "$PUBIP" ]; then
    PUBIP="$PRIVIP"
fi

clear
read -e -p "Enter the Cluster Name: " -i "BPS Cluster" CLUSTER
clear
read -e -p "Enter the DataCenter Name: " -i "DCHQ" DCNAME
clear
read -e -p "Enter the Rack Name: " -i "RAC1" RACKNAME
clear
read -e -p "Enter Data Directory (Different Disk is Recommended): " -i "/opt/cassandra/data" DATADIR
clear
read -e -p "Enter Listen Address (Use System IP Addr if Possible): " -i "$PRIVIP" IPADDR
clear
read -e -p "Enter Broadcast Address (Use System IP Addr if Possible): " -i "$PUBIP" BRADDR
clear
read -e -p "Enter Seeds Address (If more than one, use comma-delimited): " -i "$PUBIP" SEEDS
clear
read -e -p "Enter Endpoint Snitch (Options : SimpleSnitch, GossipingPropertyFileSnitch, PropertyFileSnitch, Ec2Snitch, Ec2MultiRegionSnitch, RackInferringSnitch): " -i "Ec2MultiRegionSnitch" SNITCH

VERSION="2.2.4"
ARCHIVE="http://www.eu.apache.org/dist/cassandra/$VERSION/apache-cassandra-$VERSION-bin.tar.gz"

# resolve dependencies
apt-get update
apt-get -y install wget git openjdk-7-jdk maven python-yaml
pip install pyjavaproperties

mkdir -m 777 /tmp/cassandra
cd /tmp/cassandra
wget -c -O "apache-cassandra-$VERSION-bin.tar.gz" "$ARCHIVE"
tar -zxvf "apache-cassandra-$VERSION-bin.tar.gz"
mv "apache-cassandra-$VERSION" /opt/cassandra

useradd cassandra
install -d -o cassandra -m 755 /opt/cassandra/data
install -d -o cassandra -m 755 /opt/cassandra/logs

# set cassandra.yaml configuration
cp /opt/cassandra/conf/cassandra.yaml /opt/cassandra/conf/cassandra.original.yaml
cp /opt/cassandra/conf/cassandra-rackdc.properties /opt/cassandra/conf/cassandra-rackdc.original.properties
cp /opt/cassandra/conf/cassandra-topology.properties /opt/cassandra/conf/cassandra-topology.original.properties

python - << EOF
import yaml
stream = file("/opt/cassandra/conf/cassandra.original.yaml", "r")
cassyaml = yaml.load(stream)
cassyaml["cluster_name"] = "$CLUSTER"
cassyaml["data_file_directories"] = ["$DATADIR/data"]
cassyaml["commitlog_directory"] = "$DATADIR/commitlog"
cassyaml["saved_caches_directory"] = "$DATADIR/saved_caches"
cassyaml["seed_provider"][0]["parameters"][0]["seeds"] = "$SEEDS"
cassyaml["listen_address"] = "$IPADDR"
cassyaml["broadcast_address"] = "$BRADDR"
cassyaml["start_rpc"] = "true"
cassyaml["rpc_address"] = "$IPADDR"
cassyaml["endpoint_snitch"] = "$SNITCH"
with open("/opt/cassandra/conf/cassandra.yaml", "w") as outfile:
    outfile.write(yaml.dump(cassyaml))

from pyjavaproperties import Properties
p = Properties()
p["dc"] = "$DCNAME"
p["rack"] = "$RACKNAME"
p.store(open("/opt/cassandra/conf/cassandra-rackdc.properties","w"))

p = Properties()
p["default"] = "$DCNAME:$RACKNAME"
p.store(open("/opt/cassandra/conf/cassandra-topology.properties","w"))
EOF

# build cassandra-lucene-index
git clone -b "branch-$VERSION" --single-branch https://github.com/Stratio/cassandra-lucene-index.git
cd cassandra-lucene-index
mvn clean package -Ppatch -Dcassandra_home=/opt/cassandra

chown -R cassandra /opt/cassandra

export PATH=$PATH:/opt/cassandra/bin
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
' | tee /etc/init.d/cassandra

chmod +x /etc/init.d/cassandra
update-rc.d cassandra defaults

echo -e "\nCassandra has been installed succesfully..."
echo -e "Start service with command : "
echo -e "    sudo service cassandra start\n"

