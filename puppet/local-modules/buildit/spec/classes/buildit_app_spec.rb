require 'spec_helper'
 
describe 'buildit::app', :type => 'class' do
    
  context "Should install app and open firewall" do
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
      { :app_user  => 'test123',
    	:app_group => 'test321',
    	:app_repo_url => 'https://github.com/test/testrepo.git',
    	:app_repo_revision => 'master'
      } 
    }
    it do
      should contain_group('test321').with(
        'ensure' => 'present'
      )
      should contain_user('test123').with(
        'ensure'  => 'present',
        'gid'    => 'test321',
        'shell'   => '/sbin/nologin',
        'require' => 'Group[test321]'
      )
    end
  end
 end