#!/bin/bash

php_version="73"

# install packages
yum -y install httpd \
    mariadb \
    rh-php"$php_version"-php-fpm \
    rh-php"$php_version"-php-cli \
    rh-php"$php_version"-php-common \
    rh-php"$php_version"-php-devel \
    rh-php"$php_version"-php-gd \
    rh-php"$php_version"-php-intl \
    rh-php"$php_version"-php-json \
    rh-php"$php_version"-php-ldap \
    rh-php"$php_version"-php-mbstring \
    rh-php"$php_version"-php-mysqlnd \
    rh-php"$php_version"-php-opcache \
    rh-php"$php_version"-php-pdo \
    rh-php"$php_version"-php-pear \
    rh-php"$php_version"-php-process \
    rh-php"$php_version"-php-soap \
    rh-php"$php_version"-php-xml \
    rh-php"$php_version"-php-xmlrpc \
    rh-php"$php_version"-runtime \
    sclo-php"$php_version"-php-pecl-redis5 \
    sclo-php"$php_version"-php-pecl-igbinary

# configure php
# https://docs.moodle.org/38/en/OPcache
cat <<EOF >> /etc/opt/rh/rh-php"$php_version"/php.d/99-custom-settings.ini
expose_php=off

upload_max_filesize=1024M
post_max_size=1024M

opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.save_comments=1
opcache.enable_file_override=0
opcache.revalidate_path=1
opcache.fast_shutdown=1
opcache.enable_cli=1
EOF

# create mountpoint
mkdir /srv/webdata
# create fstab entry
echo "data-server.example.com:/srv/webexport    /srv/webdata    nfs nfsvers=3,noatime    0 0" >> /etc/fstab
# mount
mount -a
# create dir for documentroot
if [ "$HOSTNAME" == "web1.example.com" ]
then
    mkdir /srv/webdata/www
fi

# create dir for local caching and fix selinux
mkdir /tmp/moodle_temp_dir
chown apache:apache /tmp/moodle_temp_dir
semanage fcontext -a -t httpd_sys_rw_content_t /tmp/moodle_temp_dir
restorecon -v /tmp/moodle_temp_dir/

# setup php-fpm
mkdir /var/log/php-fpm
sed -i 's/;log_level = notice/log_level = debug/g' /etc/opt/rh/rh-php"$php_version"/php-fpm.conf
sed -i "s/error_log = \/var\/opt\/rh\/rh-php$php_version\/log\/php-fpm\/error.log/error_log = \/var\/log\/php-fpm\/error.log/g" /etc/opt/rh/rh-php"$php_version"/php-fpm.conf

cat <<EOF >> /etc/opt/rh/rh-php"$php_version"/php-fpm.d/www.conf
slowlog = /var/log/php-fpm/www-slow.log
request_slowlog_timeout = 5s
access.log = /var/log/php-fpm/www-access.log
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
catch_workers_output = yes
listen.owner = apache
listen.group = apache
EOF

sed -i "s/listen = 127.0.0.1:9000/listen = \/var\/opt\/rh\/rh-php$php_version\/run\/php-fpm\/www/g" /etc/opt/rh/rh-php"$php_version"/php-fpm.d/www.conf

# setup httpd
sed -i 's/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/#LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/g' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/#LoadModule mpm_event_module modules\/mod_mpm_event.so/LoadModule mpm_event_module modules\/mod_mpm_event.so/g' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/Listen 80/#Listen 80/g' /etc/httpd/conf/httpd.conf
sed -i 's/LogLevel warn/LogLevel debug/g' /etc/httpd/conf/httpd.conf
sed -i 's/    DirectoryIndex index.html/    DirectoryIndex index.html index.php/g' /etc/httpd/conf/httpd.conf

# increase timeouts and configure stats page
cat <<EOF >> /etc/httpd/conf/httpd.conf
# set timeout to 10 min
Timeout 600

<Location /server-status>
    SetHandler server-status
    Require ip 127.0.0.1
</Location>
EOF

# copy moodle vhost
cat <<EOF >> /etc/httpd/conf.d/00_moodle_vhost.conf
Listen 80

<VirtualHost *:80>
    DocumentRoot /srv/webdata/www
    ErrorLog /var/log/httpd/moodle-error_log
    CustomLog /var/log/httpd/moodle-access_log \
            "LB: %h X-Forwared-For: %{X-Forwarded-For}i %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\" **%T/%D**"
    ProxyPassMatch ^/(.*\.php(/.*)?)$ unix:/var/opt/rh/rh-php$php_version/run/php-fpm/www|fcgi://localhost/srv/webdata/www/
    <Directory "/srv/webdata">
        Options Indexes FollowSymLinks
        Require all granted
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

# allow apache to use nfs
setsebool -P httpd_use_nfs on
# allow appache to connect to db on the network
setsebool -P httpd_can_network_connect_db on
# allow apache to use all ports (redis)
setsebool -P httpd_can_network_connect on

# start & enable services
systemctl enable rh-php"$php_version"-php-fpm.service
systemctl start rh-php"$php_version"-php-fpm.service
systemctl enable httpd.service
systemctl start httpd.service

# devide moodle cron
if [ "$HOSTNAME" == "web0.example.com" ]
then
    touch /srv/webdata/moodle_cron.log
    chown apache: /srv/webdata/moodle_cron.log
    echo "0,4,8,12,16,20,24,28,32,36,40,44,48,52,56 * * * * apache /opt/rh/rh-php$php_version/root/bin/php /srv/webdata/www/admin/cli/cron.php >> /srv/webdata/moodle_cron.log" > /etc/cron.d/moodle
elif [ "$HOSTNAME" == "web1.example.com" ]
then
    echo "2,6,10,14,18,22,26,30,34,38,42,46,50,54,58 * * * * apache /opt/rh/rh-php$php_version/root/bin/php /srv/webdata/www/admin/cli/cron.php >> /srv/webdata/moodle_cron.log" > /etc/cron.d/moodle
fi
