#!/bin/bash

# install haproxy
yum -y install haproxy \
    socat

# add telegraf config for haproxy
cp /vagrant/provisioning/files/telegraf_haproxy.conf /etc/telegraf/telegraf.d/telegraf_haproxy.conf

# copy config
cp /vagrant/provisioning/files/haproxy.cfg /etc/haproxy/haproxy.cfg

# setup rsyslog for haproxy
sed -i 's/#$ModLoad imudp/$ModLoad imudp/g' /etc/rsyslog.conf
sed -i 's/#$UDPServerRun 514/$UDPServerRun 514/g' /etc/rsyslog.conf
echo "local2.*    /var/log/haproxy.log" > /etc/rsyslog.d/haproxy.conf

# restart rsyslog
systemctl restart rsyslog.service

# start & enable haproxy
systemctl enable haproxy.service
systemctl start haproxy.service
