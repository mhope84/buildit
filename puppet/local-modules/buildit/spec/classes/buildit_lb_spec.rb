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
      { :app_nodes  => ['http://192.168.1.1:3000', 'http://192.168.1.2:3000'],
      } 
    }
    it do
      should contain_class('apache').with(
        'default_vhost' => 'false',
      )
    end
  end
 end