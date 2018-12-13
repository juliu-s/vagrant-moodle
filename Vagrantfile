# vim: ai et ts=2 sw=2 sts=2 ft=ruby fenc=UTF-8
# -*- mode: ruby -*-

#Fedora
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.define :"data-server" do |dataserver|
    dataserver.vm.hostname = "data-server.example.com"
    dataserver.vm.network "private_network", ip: "192.168.100.100"
    dataserver.vm.provider :virtualbox do |vm|
      vm.memory = 2048
      vm.cpus = 2
    end
    dataserver.vm.network :forwarded_port, guest: 3000, host: 3000
    dataserver.vm.provision :shell, path: "provisioning/common.sh"
    dataserver.vm.provision :shell, path: "provisioning/data-server.sh"
  end

  config.vm.define :"lb" do |lb|
    lb.vm.hostname = "lb.example.com"
    lb.vm.network "private_network", ip: "192.168.100.150"
    lb.vm.provider :virtualbox do |vm|
      vm.memory = 1024
      vm.cpus = 1
    end
    lb.vm.network :forwarded_port, guest: 80, host: 8383
    lb.vm.network :forwarded_port, guest: 8080, host: 9090
    lb.vm.provision "shell", path: "provisioning/common.sh"
    lb.vm.provision "shell", path: "provisioning/lb.sh"
  end

  config.vm.define :"web0" do |web0|
    web0.vm.hostname = "web0.example.com"
    web0.vm.network "private_network", ip: "192.168.100.110"
    web0.vm.provider :virtualbox do |vm|
      vm.memory = 2048
      vm.cpus = 2
    end
    web0.vm.network :forwarded_port, guest: 80, host: 8080
    web0.vm.provision :shell, path: "provisioning/common.sh"
    web0.vm.provision :shell, path: "provisioning/web.sh"
  end

  config.vm.define :"web1" do |web1|
    web1.vm.hostname = "web1.example.com"
    web1.vm.network "private_network", ip: "192.168.100.111"
    web1.vm.provider :virtualbox do |vm|
      vm.memory = 2048
      vm.cpus = 2
    end
    web1.vm.network :forwarded_port, guest: 80, host: 8181
    web1.vm.provision :shell, path: "provisioning/common.sh"
    web1.vm.provision :shell, path: "provisioning/web.sh"
  end

  config.vm.define :"web2" do |web2|
    web2.vm.hostname = "web2.example.com"
    web2.vm.network "private_network", ip: "192.168.100.112"
    web2.vm.provider :virtualbox do |vm|
      vm.memory = 2048
      vm.cpus = 2
    end
    web2.vm.network :forwarded_port, guest: 80, host: 8282
    web2.vm.provision :shell, path: "provisioning/common.sh"
    web2.vm.provision :shell, path: "provisioning/web.sh"
    web2.vm.provision :shell, path: "provisioning/setup-moodle.sh"
  end
end
