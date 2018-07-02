#!/bin/sh

# install packages & start service
yum -y install mariadb-server

cp /vagrant/provisioning/files/0_moodle.cnf /etc/my.cnf.d/0_moodle.cnf

systemctl enable mariadb.service
systemctl start mariadb.service

# create database
mysql -e "CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'localhost' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web1.example.com' IDENTIFIED BY 'yourpassword';"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodleuser'@'web2.example.com' IDENTIFIED BY 'yourpassword';"

# nfs
mkdir /srv/webexport
echo "/srv/webexport web1.example.com(rw,no_root_squash) web2.example.com(rw,no_root_squash)" >> /etc/exports
exportfs -avr

systemctl enable rpcbind
systemctl start rpcbind
systemctl enable nfs-server
systemctl start nfs-server
