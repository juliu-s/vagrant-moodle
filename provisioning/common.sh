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

# create direcotries for vim stuff
mkdir -p ~/.vim/bundle
mkdir ~/.vim/autoload
mkdir ~/.vim/colors

# install pathogen
curl -so ~/.vim/autoload/pathogen.vim https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim
# install plugins
git clone -q https://github.com/itchyny/lightline.vim ~/.vim/bundle/lightline.vim
git clone -q https://github.com/sheerun/vim-polyglot.git ~/.vim/bundle/vim-polyglot
# install color scheme
curl -so ~/.vim/colors/sahara.vim https://sanctum.geek.nz/cgit/vim-sahara.git/plain/colors/sahara.vim
# install .vimrc
curl -so ~/.vimrc https://gitlab.com/juliu-s/install-arch/raw/master/configs/vimrc

# setup vim stuff for vagrant user
rsync -qa /root/.vi* /home/vagrant/ --exclude=".git"
chown -R vagrant: /home/vagrant

# setup ssh between boxes
cp /vagrant/provisioning/files/id_rsa /home/vagrant/.ssh/id_rsa
cp /vagrant/provisioning/files/id_rsa.pub /home/vagrant/.ssh/id_rsa.pub
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
chown -R vagrant: /home/vagrant

# append hosts to /etc/hosts
echo "192.168.100.100   data-server.example.com data-server" >> /etc/hosts

echo "192.168.100.110   web0.example.com web0" >> /etc/hosts
echo "192.168.100.111   web1.example.com web1" >> /etc/hosts

echo "192.168.100.150   lb.example.com lb" >> /etc/hosts
