Vagrant.configure("2") do |buildit|
  # define box image to use
  buildit.vm.box = "puppetlabs/centos-7.0-64-nocm"
  buildit.vm.box_version = "1.0.2"

  buildit.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 512]
    v.customize ["modifyvm", :id, "--cpus", 2]
  end

  # define domain for all VM's
  domain = "test.local"

  # define VM's
  buildit.vm.define :node1 do |config|
    config.vm.hostname = "app-node1.#{domain}"
    config.vm.network :private_network, ip: "192.168.12.10"
  end
  buildit.vm.define :node2 do |config|
    config.vm.hostname = "app-node2.#{domain}"
    config.vm.network :private_network, ip: "192.168.12.20"
  end
  buildit.vm.define :lb1 do |config|
    config.vm.hostname = "load-balancer1.#{domain}"
    config.vm.network :private_network, ip: "192.168.12.30"
  end

  # install puppet via provision
  buildit.vm.provision :shell, path: "provision.sh"
end
