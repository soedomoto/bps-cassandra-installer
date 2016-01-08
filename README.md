# BPS Cassandra Autoinstaller for Ubuntu

###### Includes : 
* OpenJDK 7
* Apache Cassandra 2.2.4
* Cassandra Lucene Index 2.2.4.1
* Git ( to clone Cassandra Luce Index from Github)
* Maven (to build Cassandra Lucene Index)

## To Install
```sh
wget https://github.com/soedomoto/bps-cassandra-installer/raw/master/install.sh | sudo bash
```

#### Usage
###### Start Service :
```sh
sudo service cassandra start
```

###### Stop Service :
```sh
sudo service cassandra stop
```

## To Uninstall
```sh
wget https://github.com/soedomoto/bps-cassandra-installer/raw/master/uninstall.sh | sudo bash
```
