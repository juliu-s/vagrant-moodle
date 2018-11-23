#!/bin/sh

# install packages, install config & start service
yum -y install mariadb-server \
    redis

cp /vagrant/provisioning/files/0_moodle.cnf /etc/my.cnf.d/0_moodle.cnf

touch /var/log/mariadb/mariadb-error.log
touch /var/log/mariadb/mariadb-slow.log
chown mysql: /var/log/mariadb/*

systemctl enable mariadb.service
systemctl start mariadb.service

# create database
mysql -e "CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'localhost' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web0.example.com' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web1.example.com' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web2.example.com' IDENTIFIED BY 'yourpassword';"

# install mysqltuner
cd /home/vagrant
git clone -q https://github.com/major/MySQLTuner-perl mysqltuner
cd
chown -R vagrant: /home/vagrant

# export nfs
mkdir /srv/webexport
echo "/srv/webexport web0.example.com(rw,no_root_squash) web1.example.com(rw,no_root_squash) web2.example.com(rw,no_root_squash)" >> /etc/exports
exportfs -avr

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
systemctl enable nfs-server
systemctl start nfs-server
systemctl enable redis_rq.service
systemctl start redis_rq.service
systemctl enable redis.service
systemctl start redis.service
