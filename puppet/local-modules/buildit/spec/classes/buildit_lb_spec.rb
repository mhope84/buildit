require 'spec_helper'
 
describe 'buildit::lb', :type => 'class' do
    
  context "Should install apache lb and open firewall" do
    # set facts for test
    let(:facts) { 
      { :osfamily => 'RedHat',
        :operatingsystem => 'CentOS',
        :operatingsystemrelease => '7.2',
        :concat_basedir => '/tmp',
        :kernel => 'Linux',
        :id => 'root',
        :path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      } 
    }
    # set class params for test
    let(:params) { 
      { :app_nodes  => ['http://192.168.1.1:3000', 'http://192.168.1.2:3000','http://192.168.1.3:3000'],
      } 
    }
    it do
      should contain_class('apache').with(
        'default_vhost' => 'false',
      )

      should contain_apache__balancermember('http://192.168.1.1:3000-buildit').with(
        'balancer_cluster' => 'buildit',
        'url'              => 'http://192.168.1.1:3000',
      )

      should contain_apache__balancermember('http://192.168.1.2:3000-buildit').with(
        'balancer_cluster' => 'buildit',
        'url'              => 'http://192.168.1.2:3000',
      )

      should contain_apache__balancermember('http://192.168.1.3:3000-buildit').with(
        'balancer_cluster' => 'buildit',
        'url'              => 'http://192.168.1.3:3000',
      )

      should contain_class("apache::vhosts").with(
        'vhosts' => {
            'buildit_vhost' => {
                'docroot'    => '/var/www/html',
                'port'       => '80',
                'proxy_pass' => [ {'path' => '/', 'url' => 'balancer://buildit' } ]
            },
        },
      )
      
      should contain_firewalld_service('Allow Access to HTTP from the public zone').with(
        'ensure'  => 'present',
        'service' => 'http',
        'zone'    => 'public',
      )
    end
  end
 end