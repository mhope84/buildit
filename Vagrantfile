Vagrant.configure("2") do |buildit|
  # define box image to use
  buildit.vm.box = "puppetlabs/centos-7.0-64-nocm"
  buildit.vm.box_version = "1.0.2"

  # set virtualbox settings (memory/cpu)
  buildit.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 512]
    v.customize ["modifyvm", :id, "--cpus", 2]
  end

  # define domain for all VM's
  domain = "test.local"

  # define subnet prefix
  subnet_prefix = "192.168.12"

  # define VM's
  buildit.vm.define :node1 do |config|
    config.vm.hostname = "app-node1.#{domain}"
    config.vm.network :private_network, ip: "#{subnet_prefix}.10"
  end
  buildit.vm.define :node2 do |config|
    config.vm.hostname = "app-node2.#{domain}"
    config.vm.network :private_network, ip: "#{subnet_prefix}.20"
  end
  buildit.vm.define :lb1 do |config|
    config.vm.hostname = "load-balancer1.#{domain}"
    config.vm.network :private_network, ip: "#{subnet_prefix}.30"
  end

  # run provision script
  buildit.vm.provision :shell, path: "provision.sh"

  # sync local folder into VM's
  buildit.vm.synced_folder "puppet", "/tmp/puppet"
end
