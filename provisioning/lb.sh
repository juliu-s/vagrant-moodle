#!/bin/sh

# install haproxy
yum -y install haproxy \
    socat

# copy config
cp /vagrant/provisioning/files/haproxy.cfg /etc/haproxy/haproxy.cfg

# start & enable haproxy
systemctl enable haproxy.service
systemctl start haproxy.service
