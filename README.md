# gios-vagrant
Vagrant Box creation scripts

# Usage

This box comes with:

* Ubuntu 16.04
* Apache 2.4
* php7.0
* MySQL 5.7
* Wordpress - latest
* phpmyadmin - 4.0.1
* nodejs
* grunt
* composer
* sass
* git
* phpunit

The box contains MySQL, which has the following usernames, passwords, and databases by default:

* mysqluser="root"
* mysqlpass="root"
* mysqlhost="localhost"
* dbname="wordpress"
* dbuser="root"
* dbpass="root"
* dbtable="wp_"

The box contains phpmyadmin, which has the following username and password by default:
   * username="root"
   * password="root"

## Setup Instructions

1. This vagrant box requires:
    * [VirtualBox](https://www.virtualbox.org/wiki/Downloads) - v4~
    * [Vagrant](http://www.vagrantup.com/downloads.html) - v~1.7
    * [Git](https://desktop.github.com/)

2. Install [Git](https://desktop.github.com/) and clone this repo:
```
  git clone https://github.com/gios-asu/gios-vagrant.git
```
  or [download zip](https://github.com/gios-asu/gios-vagrant/archive/master.zip) and extract the repo.

3. Change your current working directory to `gios-vagrant`
4. Install VirtualBox and Vagrant for your OS:

```
UBUNTU:
  - sudo bash install_vb_vagrant.sh

MAC:
  * Install [homebrew](http://brew.sh/) using steps listed on their homepage. Once done, run following commands:
    - brew cask install virtualbox
    - brew cask install vagrant
    - brew cask install vagrant-manager

  * In the `gios-vagrant` directory, install vagrant-hostsupdater plugin with command:
    - vagrant plugin install vagrant-hostsupdater

WINDOWS:
  * Download and install the VirtualBox for Windows.
  * Download and install vagrant for Windows.
  * Install vagrant-hostsupdater plugin with command `vagrant plugin install vagrant-hostsupdater`
  * Download and install both PuTTY and PuTTYGen for windows from [here](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html).
  * A visual example to install is [here](http://aryannava.com/2014/04/05/installing-vagrant-on-windows-7-and-8/).
```

5. Rename file `settings-default` located in `gios-vagrant` directory to `settings`.

6. Open `settings` file and replace `GIT_USER_NAME` with your Git username and `GIT_TOKEN` with your [Git Personal Access Token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/).

7. Run the following command in the `gios-vagrant` directory to launch this Vagrant Box:

```
  vagrant up
```

### NOTE: The first time you launch vagrant, the machine must be setup and provisioned, including initializing the databases and web applications used for development. This process takes quite some time, up to 30 minutes, in some cases, and the provisioning scripts will not provide any visual feedback until after they have completed their work. Be prepared to step away and allow the process to take the time it needs.

8. You can see wordpress, mysql, logs, web-apps under `gios-vagrant/working_dir` directory.

9. You can now access the guest machine using following urls:
  * `sustainability.local.gios.asu.edu`
  * `sos.local.gios.asu.edu`
  * `local.gios.asu.edu/phpmyadmin`
  * `local.gios.asu.edu`
10. If you are going to use git within the vagrant machine, configure username and email id by logging into vagrant machine using `vagrant ssh`:

```
  git config --global user.name "YOUR_NAME"
  git config --global user.email "YOUR_EMAIL"
```

The box will have the following ports forwarded by default:

* 8000 => 80
* 2222 => 22
* 44300 => 443
* 33060 => 3306

It will also have the following paths mapped:

* `./` => `/vagrant` i.e., current directory `gios-vagrant` in host system is synced to /vagrant on guest system.

It will have the following urls set up as well:

* localhost:8000
* localhost:8000/wordpress
* localhost:8000/phpmyadmin

The following gios-asu repos are cloned into `gios-vagrant/working_dir/html` directory.
* gios2-php
* gios2-wp
* wordpress-news-kiosk-plugin
* wp-front-end-editor
* wordpress-newsletter-plugin
* ASU-Web-Standards-Wordpress-Theme

Add more by updating `provision.sh` and the run below command in `gios-vagrant` directory

`vagrant reload --provision`

## Changing the Settings

You can change the settings for the box by updating the `Vagrantfile` located in `gios-vagrant`.

### Examples:

To map `../gios2-api` to `/var/www/html/gios2-api` add the following line to your `Vagrantfile`:

  `config.vm.synced_folder "../gios2-api", "/var/www/html/gios2-api"`

To map port from host 8888 to guest 80 add the following line to your `Vagrantfile`:

 `config.vm.network "forwarded_port", guest: 80, host: 8888`

For more options see [Vagrantfile Documentation](http://docs.vagrantup.com/v2/vagrantfile/index.html)

After you make changes to your `Vagrantfile` you will need to run `vagrant reload`.

## Working with the Box

* `vagrant up` starts the virtual machine and provisions it
* `vagrant suspend` will essentially put the machine to 'sleep' with `vagrant resume` waking it back up
* `vagrant halt` attempts a graceful shutdown of the machine and will need to be brought back with `vagrant up`
* `vagrant ssh` gives you shell access to the virtual machine
* `vagrant reload` equivalent of running a halt followed by an up. Any changes made to Vagrantfile will take effect after this command. Can also forcefully rerun provisioners with `vagrant reload --provision`
* `vagrant status` shows the status of current vagrant machine
* `vagrant global-status` shows information about all the vagrants on the host machine.
* `vagrant init <box name> <box path>` sets up the box and creates a sample Vagrantfile in current working directory
* `vagrant destroy` destroys the box running from current working directory (Do not destory unless you want to loose data and fresh box. Use `vagrant suspend` to have data persistent and to use same box later)
* `vagrant box remove <box name>` removes the box completely so that next time when you do `vagrant init <box name>  <box path>` it forces to install a fresh box.
* `vagrant box add <box name> <box path>` same like `vagrant init <box name> <box path>` but doesn't create Vagrantfile.
* `vagrant box update` from the `gios-vagrant` path will check for new version and downloads it.

Read more about vagrant commands on [Documentation](http://docs.vagrantup.com/v2/).

# Building A Box

1. In order to build the box, you will require:
  - [VirtualBox](https://www.virtualbox.org/wiki/Downloads) - v~5.1
  - [Vagrant](http://www.vagrantup.com/downloads.html) - v~1.9
  - [Packer](http://www.packer.io/downloads.html) - v~1.0

  Follow steps as in [Setup Instructions](#setup-instructions) for installing `Vagrant` and `Virtualbox`.

2. Install Packer

```
UBUNTU:

  sudo bash install_vb_vagrant.sh

MAC:

  brew install packer

WINDOWS:

  Download packer and install manually from here: http://www.packer.io/downloads.html
```

3. Update the image\_scripts/xxxx.sh file to change an existing package or add a new script file to add completely new package images\_scripts/new_file.sh and add this file name in `gios.json` file to include as part of image creation.

4. To create the box you can run below command.

```
  packer build gios.json
```
  Note: Above command may fail if artifacts are already present. You can force to create by using `-force` option

5. `gios.box` will be created in current directory `gios-vagrant`.

6. Upload this box to [gios-asu on Atlas](https://atlas.hashicorp.com/gios-asu/boxes/gios) and update version number.

7. Destroy any previously running box in `gios-vagrant` directory using below command

```
  vagrant destroy
```

8. Start box using:

```
 vagrant up
```
