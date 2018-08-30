cd /home/gpadmin
source /home/gpadmin/.bash_profile

gpssh-exkeys -f /gpdb/greenplum-db/gpconfigs/all_hosts
gpinitsystem -a -c /gpdb/greenplum-db/gpconfigs/gpinitsystem_config -s hadoop-slave1

cat >> /gpdb/master/gpseg-1/pg_hba.conf << EOF
host    all     alex    127.0.0.1/32    trust
host    all     all     172.0.0.0/8     md5
host    all     all     127.0.0.1/32    trust
host    all     all     ::1/32  trust
EOF
gpstop -u

psql -d postgres <<EOF
create user alex with password 'alex';
create database alex;
\q
EOF

psql -d alex <<EOF
alter user alex superuser;
\q
EOF

rm -f /home/gpadmin/ext_test.txt

psql -U alex -p 5432 -h 127.0.0.1 -d alex <<EOF
GRANT INSERT ON PROTOCOL gphdfs TO gpadmin;
GRANT SELECT ON PROTOCOL gphdfs TO gpadmin;
GRANT ALL ON PROTOCOL gphdfs TO gpadmin;
ALTER ROLE gpadmin CREATEEXTTABLE (type='readable');
ALTER ROLE gpadmin CREATEEXTTABLE (type='writable');
ALTER ROLE alex CREATEEXTTABLE (type='readable');
ALTER ROLE alex CREATEEXTTABLE (type='writable');
create schema alex;
drop table t1;
create table t1 (id int, name text);
insert into t1 values (1,'HDFS');
insert into t1 values (2,'SPARK');
insert into t1 values (3,'GPDB');
select * from t1;
copy t1 to '/home/gpadmin/ext_test.txt' with csv header delimiter ',';
\q
EOF

gpconfig -c gp_hadoop_target_version -v "'hadoop'"
gpconfig -c gp_hadoop_home -v "'/usr/local/hadoop'"
gpstop -u

hadoop fs -copyFromLocal /home/gpadmin/ext_test.txt /user/gpadmin
hadoop fs -ls /user/gpadmin

psql -U alex -p 5432 -h 127.0.0.1 -d alex <<EOF
drop external table ext_test;
create external table ext_test (id int, name varchar(100))
LOCATION ('gphdfs://hadoop-master:9000/user/gpadmin/ext_test.txt')
FORMAT 'CSV' (HEADER);
drop external table ext_write;
create writable external table ext_write (like ext_test)
LOCATION ('gphdfs://hadoop-master:9000/user/gpadmin/ext_write.txt')
FORMAT 'TEXT' (delimiter ',');
drop external table ext_read;
create readable external table ext_read (id int, name text)
LOCATION ('gphdfs://hadoop-master:9000/user/gpadmin/ext_write.txt')
FORMAT 'TEXT' (delimiter ',');
insert into ext_write select * from ext_test;
\q
EOF
