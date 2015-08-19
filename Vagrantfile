$script = <<SCRIPT
cp /vagrant/settings /tmp/settings
SCRIPT
Vagrant.configure(2) do |config|
  config.vm.box = "gios-asu/gios"
  config.vm.network "forwarded_port", guest: 80, host: 8000
  config.vm.network "forwarded_port", guest: 443, host: 44300
  config.vm.network "forwarded_port", guest: 3306, host: 33060
  config.vm.synced_folder "./working_dir/mysql", "/var/lib/mysql", create: true
  config.vm.synced_folder "./working_dir/html", "/var/www/html", create: true, :owner => "www-data", :group => "www-data"
  config.vm.synced_folder "./working_dir/log", "/var/log", create: true
  config.vm.provision "shell", inline: $script
  config.vm.provision "shell", path: "before_provision.sh"
  config.vm.provision "shell", path: "provision.sh"
  config.vm.provision "shell", path: "after_provision.sh"
  config.ssh.pty = true
end
