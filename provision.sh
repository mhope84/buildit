#!/bin/bash

# install puppet 5 yum repo
sudo rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm

# install puppet 5
yum install puppet -y
