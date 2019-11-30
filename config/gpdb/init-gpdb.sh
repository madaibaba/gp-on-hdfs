cd /home/gpadmin
source /home/gpadmin/.bash_profile

gpssh-exkeys -f /gpdb/greenplum-db/gpconfigs/all_hosts
gpinitsystem -a -c /gpdb/greenplum-db/gpconfigs/gpinitsystem_config -s hadoop-slave1
pxf cluster init
pxf cluster stop
pxf cluster start

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
create extension pxf;
GRANT INSERT ON PROTOCOL pxf TO gpadmin;
GRANT SELECT ON PROTOCOL pxf TO gpadmin;
GRANT ALL ON PROTOCOL pxf TO gpadmin;
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

drop external table pxf_tbl_parquet;
CREATE WRITABLE EXTERNAL TABLE pxf_tbl_parquet (location text, month text, number_of_orders int, total_sales double precision)
LOCATION ('pxf://user/gpadmin/pxf_parquet?PROFILE=hdfs:parquet')
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_export');
INSERT INTO pxf_tbl_parquet VALUES ( 'Frankfurt', 'Mar', 777, 3956.98 );
INSERT INTO pxf_tbl_parquet VALUES ( 'Cleveland', 'Oct', 3812, 96645.37 );
drop external table read_pxf_parquet;
CREATE EXTERNAL TABLE read_pxf_parquet(location text, month text, number_of_orders int, total_sales double precision)
LOCATION ('pxf://user/gpadmin/pxf_parquet?PROFILE=hdfs:parquet')
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_import')
ENCODING 'UTF8';
SELECT * FROM read_pxf_parquet ORDER BY total_sales;
\q
EOF
