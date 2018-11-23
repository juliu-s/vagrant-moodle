#!/bin/sh

# prepare dirs
mkdir /srv/webdata/moodledata
chmod 777 /srv/webdata/moodledata
chown -R apache: /srv/*

# get moodle
version="MOODLE_35_STABLE"
echo " "
echo "installing $version"
echo " "
cd /srv/webdata/www
su -s /bin/bash -c "git clone -b $version git://git.moodle.org/moodle.git ." apache
cd

# install moodle as apache
su -s /bin/bash -c "/opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/install.php --lang=en --wwwroot=http://localhost:8383 --dataroot=/srv/webdata/moodledata --dbtype=mariadb --dbhost=data-server.example.com --dbname=moodle --dbuser=moodleuser --dbpass=yourpassword --dbport=3306 --fullname=test-moodle --shortname=tst-mdl --adminuser=admin --adminpass=AdminAdmin123! --adminemail=root@localhost.com --non-interactive --agree-license" apache

# install benchmark plugin
cd /srv/webdata/www/report
su -s /bin/bash -c "git clone -q https://github.com/mikasmart/benchmark benchmark" apache
cd

su -s /bin/bash -c "/opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/upgrade.php --non-interactive" apache

# add local cache dir for Moodle (nfs is slow)
echo -e "\n// Intended for local node caching." >> /srv/webdata/www/config.php
echo "\$CFG->localcachedir = '/tmp/moodle_temp_dir';    // Intended for local node caching." >> /srv/webdata/www/config.php

# add redis cache stores
cp /vagrant/provisioning/files/muc_config.php /srv/webdata/moodledata/muc/config.php
chmod 666 /srv/webdata/moodledata/muc/config.php
chown apache: /srv/webdata/moodledata/muc/config.php

# add redis test cache store
su - vagrant -c "ssh -o StrictHostKeyChecking=no data-server.example.com 'sudo mysql < /vagrant/provisioning/files/set_redis_test_server.sql'"
su -s /bin/bash -c "/opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/purge_caches.php" apache

# copy info pages for debugging
cp /vagrant/provisioning/files/hostname.php /srv/webdata/www/hostname.php
cp /vagrant/provisioning/files/phpinfo.php /srv/webdata/www/phpinfo.php
chown apache: /srv/webdata/www/hostname.php
chown apache: /srv/webdata/www/phpinfo.php

# restart php & apache
systemctl restart httpd.service
systemctl restart rh-php71-php-fpm.service

echo " "
echo "url: http://localhost:8383"
echo "username: admin"
echo "password: AdminAdmin123!"
echo " "
