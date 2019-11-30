#!/bin/bash

# the default node number is 3
# N is the node number of hadoop cluster
N=$1

if [ $# = 0 ]
then
	echo "The default node number is 3!"
	N=3
fi

HADOOP_HOME=/usr/local/hadoop
GPHOME=/gpdb/greenplum-db

# start hadoop master container
sudo docker rm -f hadoop-master &> /dev/null
echo "start hadoop-master container..."
sudo docker run -itd \
                --net=mybridge \
                -p 50070:50070 \
                -p 8088:8088 \
                -p 8042:8042 \
                -p 5432:5432 \
                -p 10022:22 \
                --name hadoop-master \
                --hostname hadoop-master \
                --privileged \
                madaibaba/gp-on-hdfs:1.0 &> /dev/null

# start hadoop slave container
i=1
while [ $i -lt $N ]
do
	sudo docker rm -f hadoop-slave$i &> /dev/null
	echo "start hadoop-slave$i container..."
	sudo docker run -itd \
	                --net=mybridge \
	                --name hadoop-slave$i \
	                --hostname hadoop-slave$i \
	                --privileged \
	                madaibaba/gp-on-hdfs:1.0 &> /dev/null
	i=$(( $i + 1 ))
done 

# update slaves
rm -f slaves
rm -f all_hosts
echo "hadoop-master" >> all_hosts
i=1
while [ $i -lt $N ]
do
	echo "hadoop-slave$i" >> slaves
	echo "hadoop-slave$i" >> all_hosts
	i=$(( $i + 1 ))
done 
sudo docker cp slaves hadoop-master:$HADOOP_HOME/etc/hadoop
sudo docker cp all_hosts hadoop-master:$GPHOME/gpconfigs
sudo docker exec -it hadoop-master chown gpadmin:gpadmin $GPHOME/gpconfigs/all_hosts
sudo docker cp config/gpdb/gpinitsystem_config hadoop-master:$GPHOME/gpconfigs
sudo docker exec -it hadoop-master chown gpadmin:gpadmin $GPHOME/gpconfigs/gpinitsystem_config
i=1
while [ $i -lt $N ]
do
	sudo docker cp slaves hadoop-slave$i:$HADOOP_HOME/etc/hadoop
	sudo docker cp all_hosts hadoop-slave$i:$GPHOME/gpconfigs
	sudo docker exec -it hadoop-slave$i chown gpadmin:gpadmin $GPHOME/gpconfigs/all_hosts
	sudo docker cp config/gpdb/gpinitsystem_config hadoop-slave$i:$GPHOME/gpconfigs
	sudo docker exec -it hadoop-slave$i chown gpadmin:gpadmin $GPHOME/gpconfigs/gpinitsystem_config
	i=$(( $i + 1 ))
done 
rm -f slaves
rm -f all_hosts

# init gpdb cluster
sudo docker cp config/gpdb/init-hdfs.sh hadoop-master:/tmp
sudo docker exec -it hadoop-master chmod u+x /tmp/init-hdfs.sh
sudo docker cp config/gpdb/init-gpdb.sh hadoop-master:/tmp
sudo docker exec -it hadoop-master chmod u+x /tmp/init-gpdb.sh
sudo docker exec -it hadoop-master chown gpadmin:gpadmin /tmp/init-gpdb.sh
sudo docker exec -it hadoop-master sh -c /tmp/init-hdfs.sh
sudo docker exec -it hadoop-master rm -f /tmp/init-hdfs.sh
sudo docker exec -it hadoop-master rm -f /tmp/init-gpdb.sh
sudo docker cp config/gpdb/gpdb.sh hadoop-master:/home/gpadmin
sudo docker exec -it hadoop-master chmod u+x /home/gpadmin/gpdb.sh
sudo docker exec -it hadoop-master chown gpadmin:gpadmin /home/gpadmin/gpdb.sh

# get into hadoop master container
sudo docker exec -u gpadmin -it hadoop-master bash /home/gpadmin/gpdb.sh
