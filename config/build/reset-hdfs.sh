cat >> /gpdb/greenplum-db/pxf/conf/pxf-env-default.sh << EOF
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PXF_USER_IMPERSONATION=false
EOF

sed -i '/^GPHOME=/a\GPHOME=/gpdb/greenplum-db' /gpdb/greenplum-db/greenplum_path.sh
cat >> /gpdb/greenplum-db/greenplum_path.sh <<EOF
export PXF_CONF=/gpdb/greenplum-db/pxf/conf
export PATH=\$PATH:/gpdb/greenplum-db/bin:/gpdb/greenplum-db/pxf/bin
EOF

sed -i '/<\/configuration>/d' /usr/local/hadoop/etc/hadoop/core-site.xml
cat >> /usr/local/hadoop/etc/hadoop/core-site.xml <<EOF
<property>
<name>hadoop.proxyuser.gpadmin.hosts</name>
<value>*</value>
</property>
<property>
<name>hadoop.proxyuser.gpadmin.groups</name>
<value>*</value>
</property>
</configuration>
EOF

cd /usr/local/hadoop/etc/hadoop
cp core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml /gpdb/greenplum-db/pxf/conf
chown gpadmin:gpadmin /gpdb/greenplum-db/pxf/conf/*.xml

