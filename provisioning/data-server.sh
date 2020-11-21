#!/bin/bash

# install packages
yum -y install mariadb-server \
    redis

# reload systemd-daemon
systemctl daemon-reload

# mysql config
cat <<EOF >> /etc/my.cnf.d/customsettings.cnf
[client]
default-character-set = utf8mb4

[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake

innodb_buffer_pool_size = 1G
max_allowed_packet = 64M
innodb_file_per_table = 1
innodb_large_prefix = 1
innodb_file_format = barracuda
innodb_buffer_pool_instances = 12
innodb_flush_log_at_trx_commit = 0
innodb_flush_method = O_DIRECT
innodb_log_file_size = 256M
innodb_read_io_threads = 28
innodb_stats_on_metadata = OFF
innodb_thread_concurrency = 8
innodb_write_io_threads = 16

query_cache_size = 0
query_cache_type = OFF

log-error=/var/log/mariadb/mariadb-error.log

slow_query_log_file = /var/log/mariadb/mariadb-slow.log
log_queries_not_using_indexes = ON
long_query_time = 2
slow_query_log = ON

[mysql]
default-character-set = utf8mb4
EOF

touch /var/log/mariadb/mariadb-error.log
touch /var/log/mariadb/mariadb-slow.log
chown mysql:mysql /var/log/mariadb/*

systemctl enable mariadb.service
systemctl start mariadb.service

# create database
mysql -e "CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'localhost' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web0.example.com' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web1.example.com' IDENTIFIED BY 'yourpassword';"

# install mysqltuner
cd /home/vagrant || exit
git clone -q https://github.com/major/MySQLTuner-perl mysqltuner
cd || exit
chown -R vagrant:vagrant /home/vagrant

# start and enable and export nfs
systemctl enable nfs-server
systemctl start nfs-server

mkdir /srv/webexport
echo "/srv/webexport web0.example.com(rw,no_root_squash) web1.example.com(rw,no_root_squash)" >> /etc/exports

exportfs -var

# edit /etc/redis.conf
sed -i 's/bind 127.0.0.1/bind 192.168.100.100/g' /etc/redis.conf
sed -i 's/# maxmemory <bytes>/maxmemory 512M/g' /etc/redis.conf
sed -i 's/appendonly no/appendonly yes/g' /etc/redis.conf
sed -i 's/loglevel notice/loglevel debug/g' /etc/redis.conf

# create script & copy unit file to to activate changes for redis requirements
cat <<EOF >> /usr/local/bin/redis_req.sh
#!/bin/sh
sysctl vm.overcommit_memory=1
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 512 > /proc/sys/net/core/somaxconn
EOF
chmod 750 /usr/local/bin/redis_req.sh
cp /vagrant/provisioning/files/redis_rq.service /etc/systemd/system/redis_rq.service
systemctl daemon-reload

# start & enable services
systemctl enable redis_rq.service
systemctl start redis_rq.service
systemctl enable redis.service
systemctl start redis.service
