# gios-vagrant
Vagrant Box creation scripts

# Usage

By default this box comes with:

* Ubuntu 14.04
* Apache 2.4
* php5 ( Extensions: php5-cli, php5-common, php5-dev, php5-curl, php5-gd, php5-json, php5-imagick, php5-imap, php5-intl, php5-mcrypt, php5-memcache, php5-ming, php5-mysql, php5-ps, php5-pspell, php5-recode, php5-readline, php5-sqlite, php5-tidy, php5-xdebug, php5-xmlrpc, php5-xsl, php-pear )
* MySQL-5.5
* Wordpress - 4.2.4
* phpmyadmin - 4.0.1
* nodejs
* grunt
* composer
* sass
* subversion
* git
* curl
* vim
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
  
  To install them Ubuntu users can follow below steps: 
  * Clone this repo: `git clone https://github.com/gios-asu/gios-vagrant.git`
  * `cd gios-vagrant`
  * `sudo bash install_vb_vagrant.sh`
  
 To install them Mac users can use below steps if you have homebrew installed else do manual:
  * `brew cask install virtualbox`
  * `brew cask install vagrant`
  * `brew cask install vagrant-manager`

2. Change your working directory to one you want to keep your Vagrantfile and sync the directory with guest machine.

3. Run the following command in the directory choosen in step 2 to install this Vagrant Box:

  `vagrant init gios chasethenag420/gios`

  Or, if you are cloning this repo and building the `gios.box`, you can use `vagrant init gios gios.box`. See [Building A Box](#building-a-box) for more details.

4. To start the vagrant, run `vagrant up`

Once set up, the box will have the following ports forwarded by default:

* 8000 => 80
* 2222 => 22
* 44300 => 443
* 33060 => 3306

It will also have the following paths mapped:

* `./` => `/vagrant`

It will have the following urls set up as well:

* localhost:8000
* localhost:8000/wordpress
* localhost:8000/phpmyadmin

## Changing the Settings

You can change the settings for the box by updating the `Vagrantfile` located in the working directory you chose in step 2 of the above section. You can add new configuration or override the default configuration by editting the `Vagrantfile`. For example, if you want to map `../gios2-api` to `/var/www/html/gios2-api` you would add the following line to your `Vagrantfile`:

`config.vm.synced_folder "../gios2-api", "/var/www/html/gios2-api"`

After you make changes to your `Vagrantfile` you will need to run `vagrant reload`.

## Working with the Box

* `vagrant up` starts the virtual machine and provisions it
* `vagrant suspend` will essentially put the machine to 'sleep' with `vagrant resume` waking it back up
* `vagrant halt` attempts a graceful shutdown of the machine and will need to be brought back with `vagrant up`
* `vagrant ssh` gives you shell access to the virtual machine
* `vagrant status` shows the status of current vagrant machine
* `vagrant global-status` shows information about all the vagrants on the host machine.
* `vagrant init <box name> <box path>` sets up the box and creates a sample Vagrantfile in current working directory
* `vagrant destroy` destroys the box running from current working directory 
* `vagrant box remove <box name>` removes the box completely so that next time when you do `vagrant init <box name>  <box path>` it forces to install a fresh box.
* `vagrant box add <box name> <box path>` same like `vagrant init <box name> <box path> but doesn't create Vagrantfile

Read more about vagrant commands on [Documentation](http://docs.vagrantup.com/v2/).

# Building A Box

1. In order to build the box, you will require:
  - [VirtualBox](https://www.virtualbox.org/wiki/Downloads) - v~4.3
  - [Vagrant](http://www.vagrantup.com/downloads.html) - v~1.7
  - [Packer](https://www.packer.io/) - v~0.8

  Or run the following if you are on Ubuntu:

  `sudo bash install_vb_vagrant.sh`


2. Update the scripts/dep.sh file to add more packages as part of provision.

3. To create the box you can run below command.

  `sudo packer build template.json`

  Note: Above command may fail if artifacts are already present. You can force to create by using `-force` option

4. `gios.box` will be created in current directory.

5. Destroy any previously running box from directory you choose above using `vagrant destroy`.

6. Remove any existing box installed with name `gios` using

    `vagrant box remove gios`

7. Change to directory you want to keep vagrant files and Intialize the box by using `vagrant init <box name> <box path>`
   
   Examples:
     * vagrant init gios http://yoursever.com/giox.box
     * vagrant init gios /path/to/gios.box
   
8. Start box using `vagrant up`

Note: Optionally you can push the box to gios-asu on [Altas](https://atlas.hashicorp.com) so it can be distributed easily.

