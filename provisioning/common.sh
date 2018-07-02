#!/bin/sh

# set time
timedatectl set-ntp true
timedatectl set-timezone 'Europe/Amsterdam'

# install epel + tools
yum -y install epel-release
yum -y install centos-release-scl
yum -y install tree \
    nc \
    vim \
    bind-utils \
    git \
    tracer

# append hosts to /etc/hosts
echo "192.168.100.100   data-server.example.com data-server" >> /etc/hosts

echo "192.168.100.111   web1.example.com web1" >> /etc/hosts
echo "192.168.100.112   web2.example.com web2" >> /etc/hosts

echo "192.168.100.150   lb.example.com lb" >> /etc/hosts
