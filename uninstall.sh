#!/bin/bash
#

rm -R /opt/cassandra
useradd -f cassandra
update-rc.d -f cassandra remove
rm /etc/init.d/cassandra
