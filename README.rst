Vagrant Moodle
##############

.. contents::

Using Vagrant to setup a few servers with increased logging to play with Moodle in combination with: Apache, PHP-FPM, MariaDB, HAProxy, NFS, Moodle and Redis in the following setup:

.. code-block:: text

                        0
                       -|-
                       / \
                        |
                        v
               ,-----------------.
               |       lb        | - HAProxy with sticky sessions
               `-----------------'
                  /    |       \
     ,----------. ,----------. ,----------.
     | web-tst0 | | web-tst1 | | web-tst2 | - Apache & PHP-FPM
     `----------' `----------' `----------'
                    \  |   /
                ,-------------.
                | data-server | - MariaDB, InfluxDB, Redis, NFS & Grafana
                `-------------'


Requirements
============

* `Vagrant <https://www.vagrantup.com/downloads.html>`_
* `Virtualbox <https://www.virtualbox.org/wiki/Downloads>`_
* `Git <https://git-scm.com/downloads>`_

-----

* CPU's: 4
* Mem: ~8GB
* Free diskspace: ~6GB

Installation instructions
=========================

1. Install the requirements
2. Clone this repo on your laptop
3. Enter the directory and run **vagrant up**

It takes about 15 min with an i5 CPU & SSD and a 40Mbit/s internet connection to complete

Details
=======

* Check the Vagrant file, config and bash scripts in the provisioning directory
* When you run **vagrant up** you get 5 CentOS 7 machines with an second network adapter:

+-------------------------------------+-----------------+---------------+
| Hostname                            | IP              | Specs         |
+=====================================+=================+===============+
| lb.example.com                      | 192.168.100.150 | 1 CPU, 1024M  |
+-------------------------------------+-----------------+---------------+
| web0.example.com                    | 192.168.100.110 | 2 CPU, 2048M  |
+-------------------------------------+-----------------+---------------+
| web1.example.com                    | 192.168.100.111 | 2 CPU, 2048M  |
+-------------------------------------+-----------------+---------------+
| web2.example.com                    | 192.168.100.112 | 2 CPU, 2048M  |
+-------------------------------------+-----------------+---------------+
| data-server.example.com             | 192.168.100.100 | 2 CPU, 2048M  |
+-------------------------------------+-----------------+---------------+

Check the following directories in this repo for the provisioning scripts and configuration files.

.. code-block:: text

    provisioning
    provisioning/files
    provisioning/setup-moodle.sh << to change the version of Moodle

When you're done run **vagrant destroy**, or if you want to continue later run **vagrant suspend** and **vagrant resume** to continue again.

Post setup
==========

To SSH into a server run from this repo:

* vagrant ssh data-server
* vagrant ssh web1
* vagrant ssh web2
* vagrant ssh web3
* vagrant ssh lb

**data-server.example.com**

* The data server is automatically configured

**lb.example.com**

* The HAProxy server is automatically configured

**web0, web1 and 2.example.com**

* The web servers are automaticlly configured
* The Moodle application is automatically installed and configured

Usage
=====

.. code-block:: text

    From your host OS, browse localhost:3000 for Grafana
    From your host OS, browse localhost:9090 for HAProxy stats
    From your host OS, browse localhost:8080 for web0 webpage
    From your host OS, browse localhost:8181 for web1 webpage
    From your host OS, browse localhost:8282 for web2 webpage
    From your host OS, browse localhost:8383 for the loadbalanced webpage

    Grafana username: admin
    Grafana password: admin123

    Moodle username: admin
    Moodle password: AdminAdmin123!
