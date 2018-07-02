#!/bin/sh

# prepare dirs
mkdir /srv/webdata/moodledata
chmod 777 /srv/webdata/moodledata
chown -R apache: /srv/*

# get moodle
version="MOODLE_33_STABLE"
echo " "
echo "installing $version"
echo " "
cd /srv/webdata/www
su -s /bin/bash -c "git clone -b $version git://git.moodle.org/moodle.git ." apache
cd

# install moodle as apache
su -s /bin/bash -c "/opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/install.php --lang=en --wwwroot=http://localhost:8383 --dataroot=/srv/webdata/moodledata --dbtype=mysqli --dbhost=data-server.example.com --dbname=moodle --dbuser=moodleuser --dbpass=yourpassword --dbport=3306 --fullname=test-moodle --shortname=tst-mdl --adminuser=admin --adminpass=AdminAdmin123! --adminemail=root@localhost.com --non-interactive --agree-license" apache

# copy info pages for debugging
cp /vagrant/provisioning/files/hostname.php /srv/webdata/www/hostname.php
cp /vagrant/provisioning/files/phpinfo.php /srv/webdata/www/phpinfo.php
chown apache: /srv/webdata/www/hostname.php
chown apache: /srv/webdata/www/phpinfo.php

echo " "
echo "url: http://localhost:8383"
echo "username: admin"
echo "password: AdminAdmin123!"
echo " "
echo "Don't forget to configure Redis cache"
