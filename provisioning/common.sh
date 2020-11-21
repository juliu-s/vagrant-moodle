#!/bin/bash

# set time
timedatectl set-ntp true
timedatectl set-timezone 'Europe/Amsterdam'

# update yum cache
yum makecache fast -y

# install extra repo's and packages
yum -y install epel-release
yum -y install centos-release-scl
yum -y install tree \
    nc \
    vim \
    bind-utils \
    git \
    lsof \
    iotop \
    tcpdump \
    iftop \
    strace \
    tracer

# setup ssh between boxes
cp /vagrant/provisioning/files/id_rsa /home/vagrant/.ssh/id_rsa
cp /vagrant/provisioning/files/id_rsa.pub /home/vagrant/.ssh/id_rsa.pub
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant

# append hosts to /etc/hosts
{ echo "192.168.100.100   data-server.example.com data-server"; echo "192.168.100.110   web0.example.com web0"; echo "192.168.100.111   web1.example.com web1"; echo "192.168.100.150   lb.example.com lb"; } >> /etc/hosts
