# Buildit Devops App Deployment

This repo contains a `vagrant` environment to deploy the buildit test application, it will create three CentOS 7 VM's and deploy the applicaiton on two of them, a Load Balancer will be configured on the final VM.

All custom code is within this repository, however a number of 3rd party `puppet` modules are needed in order to run a deployment, these modules will be install onto each VM via `r10k` automatically.

### Usage:
    git clone https://github.com/mhope84/buildit.git
    cd buildit
    vagrant up

## IP's
* 192.168.12.10 - This is the first app node
* 192.168.12.20 - This is the second app node
* 192.168.12.30 - This is the Load balancer

# Web Access
* http://192.168.12.30 - load balancer
* http://192.168.12.10:3000 - first app node
* http://192.168.12.10:3000 - second app node

# Puppet

The deployment of the app nodes and load balancer is achieved by a custom `puppet` module caled `buildit` it makes use of a number of third party `puppet` modules to provide additional functionality, for example installing/configuring apache httpd is done by the `puppetlabs/apache` module.

## CI/CD Pipeline

The `mock-cdcd.sh` script provides a very basic "mockup" of a CICD pipeline, it will grab an initial list of all branches from the application repository, it will then periodically (by default 30 seconds) get an updated branch list to check for changes.   If there are any new branches or if the commit ref's have changed for an existing branch then it will be checked out and a "build" executed (npm test), if this passed then a deployment is run for that repo/branch.

The script will then pause for a pre determined amount of time (default 300 seconds) to allow the new environment to be used, after this time the vagrant environment will be destroyed, and the script will continue looking for further changes.  Setting the deployment sleep time (`--deploy_sleep`) to 0 means there will be no automated destruction of the environment and no further builds will be run, instead the script will exit.

#### Usage: 
    mock-cicd.sh  [--loop_interval <value>] [--app_repo <value>] [--deploy_repo <value>] [--clone_parent_dir <value>] [--deploy_sleep <value>]"

#### Example:
    mock-cicd.sh --loop_interval 10 --deploy_sleep 500 --clone_parent_dir /tmp/buildit --app_repo "https://github.com/buildit/devops-test-webapp.git" --deploy_rep "https://github.com/mhope84/buildit.git"
