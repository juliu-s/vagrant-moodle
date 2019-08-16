#!/bin/bash

# add grafana repo
cat <<EOF >> /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# install packages, install config & start service
yum -y install mariadb-server \
    redis \
    influxdb \
    grafana

# reload systemd-daemon
systemctl daemon-reload

# add telegraf config for mariadb and redis
cp /vagrant/provisioning/files/telegraf_mariadb.conf /etc/telegraf/telegraf.d/telegraf_mariadb.conf
cp /vagrant/provisioning/files/telegraf_redis.conf /etc/telegraf/telegraf.d/telegraf_redis.conf

# configure influxdb
sed -i 's/#\ bind-address\ =\ ":8086"/bind-address\ =\ "192\.168\.100\.100:8086"/g' /etc/influxdb/influxdb.conf
sed -i 's/#\ auth-enabled\ =\ false/auth-enabled\ =\ true/g' /etc/influxdb/influxdb.conf

# start and enable influxdb
systemctl enable influxdb.service
systemctl start influxdb.service

# create influxdb user
sleep 3
curl -XPOST "http://192.168.100.100:8086/query" --data-urlencode "q=CREATE USER username WITH PASSWORD 'password' WITH ALL PRIVILEGES"

# configure grafana
mkdir /etc/grafana/provisioning/templates
chown root:grafana /etc/grafana/provisioning/templates
sed -i 's/;admin_user\ =\ admin/admin_user\ =\ admin/g' /etc/grafana/grafana.ini
sed -i 's/;admin_password\ =\ admin/admin_password\ =\ admin123/g' /etc/grafana/grafana.ini

# import data sources
cp /vagrant/provisioning/files/telegraf.yaml /etc/grafana/provisioning/datasources/telegraf.yaml

# import dashboard source
cp /vagrant/provisioning/files/grafana_dasboards.yaml /etc/grafana/provisioning/dashboards/grafana.yaml

# copy dashboards files from template
cp /vagrant/provisioning/files/grafana_basic_stats_dashboard_template.json /etc/grafana/provisioning/templates/grafana_basic_stats_dashboard.json
cp /vagrant/provisioning/files/grafana_mariadb_stats_dashboard_template.json /etc/grafana/provisioning/templates/grafana_mariadb_stats_dashboard.json
cp /vagrant/provisioning/files/grafana_haproxy_stats_dashboard_template.json /etc/grafana/provisioning/templates/grafana_haproxy_stats_dashboard.json
cp /vagrant/provisioning/files/grafana_apache_stats_dashboard_template.json /etc/grafana/provisioning/templates/grafana_apache_stats_dashboard.json
cp /vagrant/provisioning/files/grafana_redis_stats_dashboard_template.json /etc/grafana/provisioning/templates/grafana_redis_stats_dashboard.json

# update templates for basic stats:
sed -i 's/${DS_INFLUXDB}/telegraf/g' /etc/grafana/provisioning/templates/grafana_basic_stats_dashboard.json
sed -i 's/"title":\ "Telegraf\ -\ system\ metrics"/"title":\ "Basic stats"/g' /etc/grafana/provisioning/templates/grafana_basic_stats_dashboard.json

# update templates for mariadb stats:
sed -i 's/${DS_INFLUXDB}/telegraf/g' /etc/grafana/provisioning/templates/grafana_mariadb_stats_dashboard.json
sed -i 's/"title":\ "Service\ -\ MySQL\ Metrics"/"title":\ "MariaDB\ stats"/g' /etc/grafana/provisioning/templates/grafana_mariadb_stats_dashboard.json

# update templates for haproxy stats:
sed -i 's/${DS_NDF_APP}/telegraf/g' /etc/grafana/provisioning/templates/grafana_haproxy_stats_dashboard.json

# update templates for apache stats:
sed -i 's/${DS_INFLUXPROD}/telegraf/g' /etc/grafana/provisioning/templates/grafana_apache_stats_dashboard.json

# update templates for redis stats:
sed -i 's/${DS_INFLUXDB}/telegraf/g' /etc/grafana/provisioning/templates/grafana_redis_stats_dashboard.json

# fix permissions
chown -R root:grafana /etc/grafana/provisioning

# copy mysql config
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

# start and enable and export nfs
systemctl enable nfs-server
systemctl start nfs-server

mkdir /srv/webexport
echo "/srv/webexport web0.example.com(rw,no_root_squash) web1.example.com(rw,no_root_squash) web2.example.com(rw,no_root_squash)" >> /etc/exports

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
systemctl start grafana-server
systemctl enable grafana-server

# start collecting mariadb and redis stats
systemctl restart telegraf.service
