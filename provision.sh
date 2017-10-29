#!/bin/bash

# install puppet 5 yum repo
sudo rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm

# install puppet 5
yum install puppet -y

# replace /etc/puppet with the latest version
if [[ -d /tmp/puppet ]]; then

    # if /etc/puppet exists remov it
    if [[ -d /etc/puppet ]]; then
        rm -Rf /etc/puppet
    fi

   # copy the latest puppet folder
   cp -Rp /tmp/puppet /etc/puppet

fi

# apply puppet
puppet apply --confdir=/etc/puppet --verbose /etc/puppet/manifests/ --modulepath /etc/puppet/modules
