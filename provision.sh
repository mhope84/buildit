#!/bin/bash

# install puppet 5 yum repo
sudo rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm

# install puppet 5, git and ruby
yum install puppet ruby git -y

# install r10k (old version as newer have dependencie issues)
gem install r10k -v 2.1.1

# replace /etc/puppet with the latest version
if [[ -d /tmp/puppet ]]; then

    # if /etc/puppet exists remov it
    if [[ -d /etc/puppet ]]; then
        rm -Rf /etc/puppet
    fi

   # copy the latest puppet folder
   cp -Rp /tmp/puppet /etc/puppet

fi

# bring in external puppet modules with r10k
cd /etc/puppet; r10k puppetfile install

# apply puppet
puppet apply --confdir=/etc/puppet --verbose /etc/puppet/manifests/ --modulepath /etc/puppet/modules:/etc/puppet/local-modules
