require 'spec_helper'
 
describe 'buildit', :type => 'class' do
    
  context "Should include app class on app node" do
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
      { :app_node => true,
        :lb_node => false,
      }
    }
    # set params on other used classes
    let(:pre_condition) { 
      'class {
        "::buildit::app": 
    	  app_user  => buildit,
    	  app_group => buildit,
    	  app_repo_url => \'https://github.com/test/testrepo.git\',
    	  app_repo_revision => master
      }'
    }
    it do
      should contain_class('buildit::app')
      should_not contain_class('buildit::lb')
    end
  end

   context "Should include lb class on lb node" do
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
      { :app_node => false,
        :lb_node => true,
      }
    }
    # set params on other used classes
    let(:pre_condition) { 
      'class {
        "::buildit::lb": 
    	app_nodes  => [\'http://192.168.1.1:3000\', \'http://192.168.1.2:3000\'],
      }' 
    }
    it do
      should_not contain_class('buildit::app')
      should contain_class('buildit::lb')
    end
  end

  context "Should include both app and lb classes on dual node" do
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
      { :app_node => true,
        :lb_node => true,
      }
    }
     # set params on other used classes
    let(:pre_condition) { 
      'class {
        "::buildit::app": 
    	  app_user  => buildit,
    	  app_group => buildit,
    	  app_repo_url => \'https://github.com/test/testrepo.git\',
    	  app_repo_revision => master
      }
      class {
        "::buildit::lb": 
    	app_nodes  => [\'http://192.168.1.1:3000\', \'http://192.168.1.2:3000\'],
      }' 
    }
    it do
      should contain_class('buildit::app')
      should contain_class('buildit::lb')
    end
  end
end
