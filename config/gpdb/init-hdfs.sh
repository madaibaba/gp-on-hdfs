yum install -y sudo

/root/start-hadoop.sh
hadoop fs -mkdir /tmp
hadoop fs -mkdir /user
hadoop fs -mkdir /user/gpadmin
hadoop fs -chown gpadmin /user/gpadmin
hadoop fs -chmod -R 777 /tmp
hadoop fs -chmod -R 777 /user/gpadmin

sudo -u gpadmin sh -c /tmp/init-gpdb.sh
