#!/bin/bash

echo ""

echo -e "\nbuild docker gp-on-hdfs:2.0 image\n"

#sudo docker build -t madaibaba/gp-on-hdfs:2.0 .

sudo docker pull madaibaba/hadoop-on-docker:1.0
sudo docker rm -f hadoop-master &> /dev/null
sudo docker run -itd \
                --net=mybridge \
                -p 50070:50070 \
                -p 8088:8088 \
                -p 10022:22 \
                --name hadoop-master \
                --hostname hadoop-master \
                --privileged \
                madaibaba/hadoop-on-docker:1.0 &> /dev/null

sudo docker cp config/build/env.sh hadoop-master:/root
sudo docker exec -it hadoop-master chown root:root /root/env.sh
sudo docker exec -it hadoop-master chmod u+x /root/env.sh
sudo docker exec -it hadoop-master bash -c /root/env.sh
sudo docker exec -it hadoop-master rm -f /root/env.sh
sudo docker cp config/build/gpadmin.sh hadoop-master:/tmp
sudo docker exec -it hadoop-master chown gpadmin:gpadmin /tmp/gpadmin.sh
sudo docker exec -it hadoop-master chmod u+x /tmp/gpadmin.sh
sudo docker exec -u gpadmin -it hadoop-master bash -c /tmp/gpadmin.sh
sudo docker exec -u gpadmin -it hadoop-master rm -f /tmp/gpadmin.sh

sudo docker cp package/greenplum-db-6.1.0.tar.gz hadoop-master:/gpdb
sudo docker exec -it hadoop-master chown gpadmin:gpadmin /gpdb/greenplum-db-6.1.0.tar.gz
sudo docker exec -u gpadmin -it hadoop-master tar -zxvf /gpdb/greenplum-db-6.1.0.tar.gz -C /gpdb
sudo docker exec -u gpadmin -it hadoop-master ln -s greenplum-db-6.1.0 /gpdb/greenplum-db
sudo docker exec -u gpadmin -it hadoop-master mkdir -p /gpdb/greenplum-db-6.1.0/gpconfigs
sudo docker exec -it hadoop-master rm -f /gpdb/greenplum-db-6.1.0.tar.gz

sudo docker cp config/build/reset-hdfs.sh hadoop-master:/tmp
sudo docker exec -it hadoop-master chmod u+x /tmp/reset-hdfs.sh
sudo docker exec -it hadoop-master bash -c /tmp/reset-hdfs.sh

sudo docker commit hadoop-master madaibaba/gp-on-hdfs:2.0
sudo docker rm -f hadoop-master &> /dev/null

echo ""