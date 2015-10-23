$script = <<SCRIPT
cp /vagrant/settings /tmp/settings
SCRIPT
Vagrant.configure(2) do |config|
  config.vm.box = "gios-asu/gios"
  config.vm.network "forwarded_port", guest: 80, host: 8000
  config.vm.network "forwarded_port", guest: 443, host: 44300
  config.vm.network "forwarded_port", guest: 3306, host: 33060
  config.vm.synced_folder "./working_dir/html", "/var/www/html", create: true, :owner => "www-data", :group => "www-data"
  config.vm.synced_folder "./working_dir/log/apache2", "/var/log/apache2", create: true
  config.vm.provision "shell", inline: $script
  config.vm.provision "shell", path: "provision_scripts/before_provision.sh"
  config.vm.provision "shell", path: "provision_scripts/provision.sh", args: "wordpress root root localhost wp_ /var/www/html latest"
  config.vm.provision "shell", path: "provision_scripts/after_provision.sh"
  config.vm.network :private_network, ip: "192.168.160.196"
  config.vm.hostname = "local.gios"
  config.ssh.pty = true
end
