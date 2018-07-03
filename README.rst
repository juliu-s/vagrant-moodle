Vagrant Moodle
##############

.. contents::

Using Vagrant to setup a few servers to play with Moodle in combination with: Apache, PHP-FPM, MariaDB, HAProxy, NFS, Moodle and Redis

.. class:: no-web

    .. image:: https://raw.githubusercontent.com/juliu-s/vagrant-moodle/master/images/moodle_setup.png
        :alt: Moodle setup
        :width: 75%
        :align: center

.. class:: no-web

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
* When you run **vagrant up** you get 4 CentOS 7 machines with an second network adapter:

+-------------------------------------+-----------------+---------------+
| Hostname                            | IP              | Specs         |
+=====================================+=================+===============+
| data-server.example.com             | 192.168.100.100 | 2 CPU, 2048MB |
+-------------------------------------+-----------------+---------------+
| web1.example.com                    | 192.168.100.111 | 1 CPU, 1024MB |
+-------------------------------------+-----------------+---------------+
| web2.example.com                    | 192.168.100.112 | 1 CPU, 1024MB |
+-------------------------------------+-----------------+---------------+
| lb.example.com                      | 192.168.100.150 | 1 CPU, 512MB  |
+-------------------------------------+-----------------+---------------+

Check the following directories in this repo for the provisioning scripts and configuration files.

.. code-block:: text

    provisioning
    provisioning/files
    provisioning/files/setup-moodle.sh << to change the version of Moodle

When you're done run **vagrant destroy**, or if you want to continue later run **vagrant suspend** and **vagrant resume** to continue again.

Post setup
==========

To SSH into a server run from this repo:

* vagrant ssh data-server
* vagrant ssh web1
* vagrant ssh web2
* vagrant ssh lb

**data-server.example.com**

* The database and NFS export are automatically created

.. code-block:: text

    mariadb username: moodleuser
    mariadb password: yourpassword
    mariadb database: moodle
    mariadb host: data-server.example.com / 192.168.100.100

    nfs export: /srv/webexport web1.example.com(rw,no_root_squash) web2.example.com(rw,no_root_squash)"

**lb.example.com**

* The HAProxy server is automatically configured

**web1 & 2.example.com**

* The web servers are automaticlly configured
* The Moodle application is automatically installed and configured

.. code-block:: text

    From your host OS, browse localhost:8080 for HAProxy stats
    From your host OS, browse localhost:8181 for web1 webpage
    From your host OS, browse localhost:8282 for web2 webpage
    From your host OS, browse localhost:8383 for the loadbalanced webpage

    Moodle username: admin
    Moodle password: AdminAdmin123!
