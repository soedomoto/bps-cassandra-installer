#!/bin/bash
#

clear
read -e -p "Enter the Cluster Name: " -i "BPS Cluster" CLUSTER
clear
read -e -p "Enter Data Directory (Different Disk is Recommended): " -i "/opt/cassandra/data" DATADIR
clear
read -e -p "Enter Listen Address (Use System IP Addr if Possible): " -i "127.0.0.1" IPADDR
clear
read -e -p "Enter Seeds Address (If more than one, use comma-delimited): " -i "127.0.0.1" SEEDS
clear
read -e -p "Enter Endpoint Snitch (Options : SimpleSnitch, GossipingPropertyFileSnitch, PropertyFileSnitch, Ec2Snitch, Ec2MultiRegionSnitch, RackInferringSnitch): " -i "PropertyFileSnitch" SNITCH

VERSION="2.2.4"
ARCHIVE="http://www.eu.apache.org/dist/cassandra/$VERSION/apache-cassandra-$VERSION-bin.tar.gz"

# resolve dependencies
apt-get update
apt-get -y install wget git openjdk-7-jdk maven python-yaml

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
cassyaml["start_rpc"] = "true"
cassyaml["rpc_address"] = "$IPADDR"
cassyaml["endpoint_snitch"] = "$SNITCH"
with open("/opt/cassandra/conf/cassandra.yaml", "w") as outfile:
    outfile.write(yaml.dump(cassyaml))
EOF

