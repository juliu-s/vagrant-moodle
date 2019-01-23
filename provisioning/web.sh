#!/bin/bash

# install packages
yum -y install httpd \
    mariadb \
    rh-php71-php-fpm \
    rh-php71-php-cli \
    rh-php71-php-common \
    rh-php71-php-devel \
    rh-php71-php-gd \
    rh-php71-php-intl \
    rh-php71-php-json \
    rh-php71-php-ldap \
    rh-php71-php-mbstring \
    rh-php71-php-mysqlnd \
    rh-php71-php-opcache \
    rh-php71-php-pdo \
    rh-php71-php-pear \
    rh-php71-php-process \
    rh-php71-php-soap \
    rh-php71-php-xml \
    rh-php71-php-xmlrpc \
    rh-php71-runtime \
    sclo-php71-php-pecl-redis \
    sclo-php71-php-pecl-igbinary

# add apache config for haproxy
cp /vagrant/provisioning/files/telegraf_apache.conf /etc/telegraf/telegraf.d/telegraf_apache.conf

# optimize php-opcache -> https://docs.moodle.org/35/en/OPcache
sed -i 's/4000/10000/g' /etc/opt/rh/rh-php71/php.d/10-opcache.ini
sed -i 's/;opcache\.revalidate_freq=2/opcache\.revalidate_freq=60/g' /etc/opt/rh/rh-php71/php.d/10-opcache.ini
sed -i 's/;opcache\.use_cwd=1/opcache\.use_cwd=1/g' /etc/opt/rh/rh-php71/php.d/10-opcache.ini
sed -i 's/;opcache\.validate_timestamps=1/opcache\.validate_timestamps=1/g' /etc/opt/rh/rh-php71/php.d/10-opcache.ini
sed -i 's/;opcache\.save_comments=1/opcache\.save_comments=1/g' /etc/opt/rh/rh-php71/php.d/10-opcache.ini
sed -i 's/;opcache\.enable_file_override=0/opcache\.enable_file_override=0/g' /etc/opt/rh/rh-php71/php.d/10-opcache.ini

# allow bigger uploads
sed -i 's/2M/1024M/g' /etc/opt/rh/rh-php71/php.ini

# create mountpoint
mkdir /srv/webdata
# create fstab entry
echo "data-server.example.com:/srv/webexport    /srv/webdata    nfs defaults    0 0" >> /etc/fstab
# mount
mount -a
# create dir for documentroot
if [ "$HOSTNAME" == "web2.example.com" ]
then
    mkdir /srv/webdata/www
fi

# create dir for local caching and fix selinux
mkdir /tmp/moodle_temp_dir
chown apache: /tmp/moodle_temp_dir
semanage fcontext -a -t httpd_sys_rw_content_t /tmp/moodle_temp_dir
restorecon -v /tmp/moodle_temp_dir/

# setup php-fpm
mkdir /var/log/php-fpm
sed -i 's/log_level = notice/log_level = debug/g' /etc/opt/rh/rh-php71/php-fpm.conf
sed -i 's/error_log = \/var\/opt\/rh\/rh-php71\/log\/php-fpm\/error.log/error_log = \/var\/log\/php-fpm\/error.log/g' /etc/opt/rh/rh-php71/php-fpm.conf

echo "slowlog = /var/opt/rh/rh-php71/log/php-fpm/www-slow.log" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf
echo "request_slowlog_timeout = 10s" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf
echo "access.log = /var/log/php-fpm/www-access.log" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf
echo "php_admin_value[error_log] = /var/log/php-fpm/www-error.log" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf
echo "catch_workers_output = yes" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf
echo "listen.owner = apache" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf
echo "listen.group = apache" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf

sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/opt\/rh\/rh-php71\/run\/php-fpm\/www/g' /etc/opt/rh/rh-php71/php-fpm.d/www.conf

# setup httpd
sed -i 's/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/#LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/g' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/#LoadModule mpm_event_module modules\/mod_mpm_event.so/LoadModule mpm_event_module modules\/mod_mpm_event.so/g' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/Listen 80/#Listen 80/g' /etc/httpd/conf/httpd.conf
sed -i 's/LogLevel warn/LogLevel debug/g' /etc/httpd/conf/httpd.conf
sed -i 's/    DirectoryIndex index.html/    DirectoryIndex index.html index.php/g' /etc/httpd/conf/httpd.conf

# increase timeouts and configure stats page for telegraf
cat <<EOF >> /etc/httpd/conf/httpd.conf
# set timeout to 10 min
Timeout 600
ProxyTimeout 600

<Location /server-status>
    SetHandler server-status
    Require ip 127.0.0.1
</Location>
EOF

# copy moodle vhost
cp /vagrant/provisioning/files/00_vhost.conf /etc/httpd/conf.d/00_vhost.conf

# allow apache to use nfs
setsebool -P httpd_use_nfs on
# allow appache to connect to db on the network
setsebool -P httpd_can_network_connect_db on
# allow apache to use all ports (redis)
setsebool -P httpd_can_network_connect on

# start & enable services
systemctl enable rh-php71-php-fpm.service
systemctl start rh-php71-php-fpm.service
systemctl enable httpd.service
systemctl start httpd.service

# restart telegraf
systemctl restart telegraf.service

# create "homedir" for apache, otherwise cron won't run
mkdir -p /opt/rh/httpd24/root/usr/share/httpd

# devide moodle cron
if [ "$HOSTNAME" == "web0.example.com" ]
then
    touch /srv/webdata/moodle_cron.log
    chown apache: /srv/webdata/moodle_cron.log
    echo "0,9,18,27,36,45,54 * * * * apache /opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/cron.php >> /srv/webdata/moodle_cron.log" > /etc/cron.d/moodle
elif [ "$HOSTNAME" == "web1.example.com" ]
then
    echo "3,12,21,30,39,48,57 * * * * apache /opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/cron.php >> /srvwebdata//moodle_cron.log" > /etc/cron.d/moodle
else
    echo "6,15,24,33,42,51 * * * * apache /opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/cron.php >> /srv/webdata/moodle_cron.log" > /etc/cron.d/moodle
fi
