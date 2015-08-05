# gios-vagrant
Vagrant Box creation scripts

#How to use:
============
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads), [Vagrant](http://www.vagrantup.com/downloads.html). and [Packer](https://www.packer.io/) on your machine if not installed before

  * If you are using ubuntu you can use install_vb_vagrant.sh which installs above 3 packages for you.
  `Example: sudo bash install_vb_vagrant.sh`

2. To create the box you can run below command
  * `packer build -force template.json`
  * If you are using linux create_box.sh script
  `Example: bash create_box.sh`

3. By default this box comes with Apache2, php5, MySql-5.5, Wordpress, phpmyadmin, nodejs, grunt, composer, sass.

4. Wait until the above command completes. Above command generate gios.box file into present working directory.

5. Run below command to create a sample `Vagrantfile` in present working directory
  `vagrant init gios gios.box`

6. Update Vagarantfile with the required configuration be used.
  ```
  Example:
  Below configuration redirects 8080 port on host to 80 on guest(vagrant)
  Synchronizes the /app on host with /var/www/html on guest
  Vagrant.configure(2) do |config|
    config.vm.box = "gios"
    config.vm.box_url = "gios.box"
    config.vm.synced_folder "/app", "/var/www/html"
    config.vm.network "forwarded_port", guest: 80, host: 8080
  end
  ```
7. To start the vagrant machine use below command
  `vagrant up`

8. To add more packages to vagrant machine you can update provising script (scripts/dep.sh) with other dependencies and run below command
 `vagrant provision`

9. To working directly on vagrant machine use
  `vagrant ssh`

10. Read more about vagrant command on [Documentation]http://docs.vagrantup.com/v2/