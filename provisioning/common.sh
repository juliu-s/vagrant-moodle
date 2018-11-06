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
    iotop \
    iftop \
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

# append hosts to /etc/hosts
echo "192.168.100.100   data-server.example.com data-server" >> /etc/hosts

echo "192.168.100.111   web1.example.com web1" >> /etc/hosts
echo "192.168.100.112   web2.example.com web2" >> /etc/hosts

echo "192.168.100.150   lb.example.com lb" >> /etc/hosts
