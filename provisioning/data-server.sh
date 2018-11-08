#!/bin/sh

# install packages, install config & start service
yum -y install mariadb-server

cp /vagrant/provisioning/files/0_moodle.cnf /etc/my.cnf.d/0_moodle.cnf

touch /var/lib/mysql/data-server.example.com.err
chown mysql: /var/lib/mysql/data-server.example.com.err

systemctl enable mariadb.service
systemctl start mariadb.service

# create database
mysql -e "CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'localhost' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web1.example.com' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web2.example.com' IDENTIFIED BY 'yourpassword';"

# install mysqltuner
cd /home/vagrant
git clone -q https://github.com/major/MySQLTuner-perl mysqltuner
cd
chown -R vagrant: /home/vagrant

# export nfs
mkdir /srv/webexport
echo "/srv/webexport web1.example.com(rw,no_root_squash) web2.example.com(rw,no_root_squash)" >> /etc/exports
exportfs -avr

# start nfs-server
systemctl enable nfs-server
systemctl start nfs-server
