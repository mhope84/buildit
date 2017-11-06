require 'spec_helper'
 
describe 'buildit::app', :type => 'class' do

  app_group = 'test321'
  app_user = 'test123'
  app_repo_url = 'https://github.com/test/testrepo.git'
  app_repo_revision = 'master'
  app_directory = '/opt/nodeapp'
  app_tcp_port = '2000'
  node_repo_package_name = 'fakereleasee-release-el7-1'
  node_repo_package_url = 'https://rpm.nodesource.com/pub_6.x/el/7/x86_64/fakereleasee-release-el7-1.noarch.rpm'
  node_package = 'fakepackage'
  systemd_template = 'buildit/nodejs-systemd'
  systemd_unit_file = '/etc/systemd/system/test-app.service'
  service_name = 'test-app'
    
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
      { :app_user  => app_user,
    	:app_group => app_group,
    	:app_repo_url => app_repo_url,
    	:app_repo_revision => app_repo_revision,
      :app_directory => app_directory,
      :app_tcp_port => app_tcp_port,
      :node_repo_package_name =>  node_repo_package_name,
      :node_repo_package_url => node_repo_package_url,
      :node_package =>  node_package,
      :systemd_template => systemd_template,
      :systemd_unit_file => systemd_unit_file,
      :service_name => service_name,
      } 
    }
    it do
      should contain_group(app_group).with(
        'ensure' => 'present'
      )
      should contain_user(app_user).with(
        'ensure'  => 'present',
        'gid'     => app_group,
        'shell'   => '/sbin/nologin',
        'require' => "Group[#{app_group}]"
      )

      should contain_package(node_repo_package_name).with(
        'ensure'   => 'installed',
        'provider' => 'rpm',
        'source'   => node_repo_package_url,
      )

      should contain_package(node_package).with(
        'ensure'  => 'installed',
        'require' => "Package[#{node_repo_package_name}]",
      )

      should contain_vcsrepo(app_directory).with(
        'ensure'   => 'latest',
        'provider' => 'git',
        'source'   => app_repo_url,
        'revision' => app_repo_revision,
        'require'  => "Package[#{node_package}]",
      )

      should contain_file(systemd_unit_file).with(
        'owner'   => 'root',
        'group'   => 'root',
        'before'  => "Service[#{service_name}]",
        'require' => "Vcsrepo[#{app_directory}]",
        'notify'  => '[Exec[reload-systemd]{:command=>"reload-systemd"}, Service[test-app]{:name=>"test-app"}]',
      )

      should contain_exec('reload-systemd').with(
        'command'     => 'systemctl daemon-reload',
        'refreshonly' => true,
      )

      should contain_service(service_name).with(
        'ensure'  => 'running',
        'enable'  => true,
        'require' => '[File[/etc/systemd/system/test-app.service]{:path=>"/etc/systemd/system/test-app.service"}, User[test123]{:name=>"test123"}]',
      )

      should contain_firewalld__custom_service('buildit-app').with(
        'short'       => 'buildit-app',
        'description' => 'Service for Buildit test Node.JS app',
        'port'        => [
            {
                'port'     => app_tcp_port,
                'protocol' => 'tcp',
            }
        ],
      )

      should contain_firewalld_service('Allow Access to Node.JS app from the public zone').with(
        'ensure'  => 'present',
        'service' => 'buildit-app',
        'zone'    => 'public',
      )
    end
  end
 end