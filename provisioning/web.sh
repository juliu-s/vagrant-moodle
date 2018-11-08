#!/bin/sh

# install packages
yum -y install httpd \
    mariadb \
    redis \
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
sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/opt\/rh\/rh-php71\/run\/php-fpm\/www/g' /etc/opt/rh/rh-php71/php-fpm.d/www.conf
echo "listen.owner = apache" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf
echo "listen.group = apache" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf

# setup httpd
sed -i 's/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/#LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/g' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/#LoadModule mpm_event_module modules\/mod_mpm_event.so/LoadModule mpm_event_module modules\/mod_mpm_event.so/g' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/Listen 80/#Listen 80/g' /etc/httpd/conf/httpd.conf
sed -i 's/    DirectoryIndex index.html/    DirectoryIndex index.html index.php/g' /etc/httpd/conf/httpd.conf
# copy moodle vhost
cp /vagrant/provisioning/files/00_vhost.conf /etc/httpd/conf.d/00_vhost.conf

# allow apache to use nfs
setsebool httpd_use_nfs=1
# allow appache to connect to db on the network
setsebool httpd_can_network_connect_db=1
# allow apache to use all ports (redis)
setsebool httpd_can_network_connect=1

# edit /etc/redis.conf
sed -i 's/# maxmemory <bytes>/maxmemory 512M/g' /etc/redis.conf
sed -i 's/appendonly no/appendonly yes/g' /etc/redis.conf

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
systemctl enable rh-php71-php-fpm.service
systemctl start rh-php71-php-fpm.service
systemctl enable redis.service
systemctl start redis.service
systemctl enable rpcbind.service
systemctl start rpcbind.service
systemctl enable httpd.service
systemctl start httpd.service

# devide moodle cron
if [ "$HOSTNAME" == "web1.example.com" ]
then
    echo "0,10,20,30,40,50 * * * * apache /opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/cron.php >/dev/null" > /etc/cron.d/moodle
else
    echo "5,15,25,35,45,55 * * * * apache /opt/rh/rh-php71/root/bin/php /srv/webdata/www/admin/cli/cron.php >/dev/null" > /etc/cron.d/moodle
fi
