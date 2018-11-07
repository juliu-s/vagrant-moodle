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

# add redis config for Moodle
cat <<EOF >> /srv/webdata/www/config.php
//REDIS
\$CFG->session_handler_class = '\core\session\redis';
\$CFG->session_redis_host = '127.0.0.1';
\$CFG->session_redis_port = 6379;  // Optional.
\$CFG->session_redis_database = 0;  // Optional, default is db 0.
\$CFG->session_redis_prefix = ''; // Optional, default is don't set one.
\$CFG->session_redis_acquire_lock_timeout = 120;
\$CFG->session_redis_lock_expire = 7200;
EOF

# copy info pages for debugging
cp /vagrant/provisioning/files/hostname.php /srv/webdata/www/hostname.php
cp /vagrant/provisioning/files/phpinfo.php /srv/webdata/www/phpinfo.php
chown apache: /srv/webdata/www/hostname.php
chown apache: /srv/webdata/www/phpinfo.php

# restart apache
systemctl restart httpd.service

echo " "
echo "url: http://localhost:8383"
echo "username: admin"
echo "password: AdminAdmin123!"
echo " "
echo "Don't forget to configure Redis cache in the UI"
