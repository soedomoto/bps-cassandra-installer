#!/bin/bash
#

rm -R /opt/cassandra
userdel -f cassandra
update-rc.d -f cassandra remove
rm /etc/init.d/cassandra
