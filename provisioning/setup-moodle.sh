#!/bin/bash

php_version="73"
moodle_version="MOODLE_38_STABLE"

# prepare dirs
mkdir -p /srv/webdata/moodledata
chmod 777 /srv/webdata/moodledata
chown -R apache: /srv/*

# get moodle
echo " "
echo "installing $moodle_version"
echo " "
cd /srv/webdata/www || exit
su -s /bin/bash -c "git clone -b $moodle_version git://git.moodle.org/moodle.git ." apache
sleep 1
cd || exit

# install moodle as apache
su -s /bin/bash -c "/opt/rh/rh-php$php_version/root/bin/php \
    /srv/webdata/www/admin/cli/install.php \
    --lang=en \
    --wwwroot=http://localhost:8383 \
    --dataroot=/srv/webdata/moodledata \
    --dbtype=mariadb \
    --dbhost=data-server.example.com \
    --dbname=moodle \
    --dbuser=moodleuser \
    --dbpass=yourpassword \
    --dbport=3306 \
    --fullname=dev-moodle \
    --shortname=dev-mdl \
    --adminuser=admin \
    --adminpass=AdminAdmin123! \
    --adminemail=root@localhost.com \
    --non-interactive \
    --agree-license" \
    apache

# install simplesamlphp

# install benchmark plugin
cd /srv/webdata/www/report || exit
su -s /bin/bash -c "git clone -q https://github.com/mikasmart/benchmark benchmark" apache
# install extra auth plugins
cd /srv/webdata/www/auth || exit
su -s /bin/bash -c "git clone -q https://github.com/catalyst/moodle-auth_saml2 saml2" apache
cd || exit

# activate new plugins
su -s /bin/bash -c "/opt/rh/rh-php$php_version/root/bin/php /srv/webdata/www/admin/cli/upgrade.php --non-interactive" apache

# add local cache dir for Moodle (nfs is slow)
echo -e "\n// Intended for local node caching." >> /srv/webdata/www/config.php
echo "\$CFG->localcachedir = '/tmp/moodle_temp_dir';    // Intended for local node caching." >> /srv/webdata/www/config.php

# add redis cache stores
cp /vagrant/provisioning/files/muc_config.php /srv/webdata/moodledata/muc/config.php
chmod 666 /srv/webdata/moodledata/muc/config.php
chown apache: /srv/webdata/moodledata/muc/config.php

# add redis test cache store
mysql -h data-server.example.com -u moodleuser --password="yourpassword" < /vagrant/provisioning/files/set_redis_test_server.sql
su -s /bin/bash -c "/opt/rh/rh-php$php_version/root/bin/php /srv/webdata/www/admin/cli/purge_caches.php" apache

# copy info pages for debugging
curl -so /srv/webdata/www/opcache.php https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php
cp /vagrant/provisioning/files/hostname.php /srv/webdata/www/hostname.php
cp /vagrant/provisioning/files/phpinfo.php /srv/webdata/www/phpinfo.php
chown apache:apache /srv/webdata/www/*.php

echo "
Done..

To see Moodle:

url: http://localhost:8383
username: admin
password: AdminAdmin123!

To see HAProxy stats:

url: http://localhost:9090
"
