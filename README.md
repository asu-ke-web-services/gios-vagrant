# gios-vagrant
Vagrant Box creation scripts

#How to use gios vagrant box:
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads), [Vagrant](http://www.vagrantup.com/downloads.html) on your machine if not installed before.

2. Run below command in the directory you want to setup.

//TODO create gios-asu on atlas and host there. For testing added to personal repo

  `vagrant int chasethenag420/gios`

3. To start the vagrant

  `vagrant up`

4. By default this box comes with Apache2, php5, MySql-5.5, Wordpress, phpmyadmin, nodejs, grunt, composer, sass.

5. Wait until the above command completes. Above command generate gios.box file into present working directory.

6. Run below command to create a sample `Vagrantfile` in present working directory.

  `vagrant init gios gios.box`

7. Update Vagarantfile with the required configuration be used.
  ```
  Example:
  Below configuration redirects 9100 port on host to 9000 on guest(vagrant).
  Synchronizes the /app on host with /var/www/html on guest.
  Vagrant.configure(2) do |config|
    config.vm.box = "gios"
    config.vm.box_url = "gios.box"
    config.vm.synced_folder "/app", "/var/www/html"
    config.vm.network "forwarded_port", guest: 9000, host: 9100

  end

  Note: Default settings
   Ports: SSH: 2222 → Forwards To 22
          HTTP: 8000 → Forwards To 80
          HTTPS: 44300 → Forwards To 443
          MySQL: 33060 → Forwards To 3306
   Directories: "./" Maps To "/vagrant"
   ```
8. To start the vagrant machine use below command.

  `vagrant up`

9. Check application by using below urls:

   `For Apache: localhost:8000`
   `For Wordpress: localhost:8000/wordpress`
   `For phpmyadmin: localhost:8000/phpmyadmin`

10. To add more packages to vagrant machine you can update provising script (scripts/dep.sh) with other dependencies and run below command.

 `vagrant provision`

11. To working directly on vagrant machine use.

  `vagrant ssh`

12. Read more about vagrant commands on [Documentation](http://docs.vagrantup.com/v2/).

#How to create gios vagrant box:

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads), [Vagrant](http://www.vagrantup.com/downloads.html). and [Packer](https://www.packer.io/) on your machine if not installed before.

  * If you are using ubuntu you can use install_vb_vagrant.sh which installs above 3 packages for you.

  `Example: sudo bash install_vb_vagrant.sh`

2. To create the box you can run below command.

  * `packer build template.json`
  * If you are using linux create_box.sh script

  `Example: bash create_box.sh`

 Note: Optionally you can push the box to [Altas](https://atlas.hashicorp.com) so it can be distributed easily.
