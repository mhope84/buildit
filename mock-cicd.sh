#!/bin/bash

# declare default variable values
LOOP_INTERVAL=30 # how long to sleep between each go around the loop
APP_GIT_REPO="https://github.com/buildit/devops-test-webapp.git" # the repository containing the app to test/deploy
DEPLOY_GIT_REPO="https://github.com/mhope84/buildit.git" # the repository containing the build tool (including this script!)
CLONE_PARENT_DIR="/tmp/buildit_pipeline_tmp" # the parent directory to checkout the app to
DEPLOY_SLEEP=300 # the amount of time to wait after a deployment to kill off the vagrant environment and loop, 0 means never (script will exit)

# declare functions
function usage () {
  echo "$( basename $0 )  [--loop_interval <value>] [--app_repo <value>] [--deploy_repo <value>] [--clone_parent_dir <value>] [--deploy_sleep <value>]"
}

log_message() {
    echo "### MOCK-CICD: ${1}"
}

# handle arguments, can override defult variable values
while (( $# > 0 )); do
    opt="$1"
        case $opt in
            --loop_interval)
                LOOP_INTERVAL="$2"
                shift
        		;;
    		--app_repo)
        		APP_GIT_REPO="$2"
        		shift
        		;;
    		--deploy_repo)
        		DEPLOY_GIT_REPO="$2"
        		shift
        		;;
    		--clone_parent_dir)
        		CLONE_PARENT_DIR="$2"
        		shift
        		;;
    		--deploy_sleep)
        		DEPLOY_SLEEP="$2"
        		shift
        		;;
        	--help)
				usage
				exit 0
				;;
    		--*)
        		echo "Invalid option: '$opt'"
        		usage
        		exit 1
        		;;
    	esac
	shift
done

# MAIN CODE STARTS HERE

 # get the current directory
CWD=$(pwd)

# fetch initial list of branches avaliable in target repo, along with ref
for REMOTE_BRANCH in $(git ls-remote --head ${APP_GIT_REPO} | grep 'refs/' | awk '{print $2 ":" $1}' | sed 's#refs/heads/##g' ); do
    BRANCHES+=(${REMOTE_BRANCH})
done

# loop forever
while true; do
    # get new branch list with refs
    LATEST_BRANCHES=()
    for REMOTE_BRANCH in $(git ls-remote --head ${APP_GIT_REPO} | grep 'refs/' | awk '{print $2 ":" $1}' | sed 's#refs/heads/##g' ); do
        LATEST_BRANCHES+=(${REMOTE_BRANCH})
    done
   
    # loop through all "new" branch list and check to see if they match the existing 
    # understanding of the branch state, this will incude new branches and also changes to existing
    CHANGED_BRANCHES=()
    for NEW_BRANCH in "${LATEST_BRANCHES[@]}"; do
    	found=0
        for OLD_BRANCH in "${BRANCHES[@]}"; do
            if [[ $NEW_BRANCH == $OLD_BRANCH ]]; then
                found=1
                break	
            fi
        done

        # if the new branch "state" cannot be found within the understanding of historical state
        # add the branch info to an array of changes 
        if [[ $found -eq 0 ]]; then
            CHANGED_BRANCHES+=(${NEW_BRANCH})
        fi
    done

    # if the list of changes is not blank do something
    if [[ ! -z $CHANGED_BRANCHES ]]; then
      
	    # loop through changed branches and execute test/deploy
	    # script wil pause after first branch "deploy" for the amount of time specified
	    # if that is 0 (no pause) then the script will just exit
	    for CHANGED in "${CHANGED_BRANCHES[@]}"; do
            # split the data into branch name and ref
	        CHANGED_BRANCH=$(echo ${CHANGED} | awk -F \: '{print $1}')
	        CHANGED_BRANCH_REF=$(echo ${CHANGED} | awk -F \: '{print $2}')

	        log_message "Branch ${CHANGED_BRANCH} has changes to be built/deployed"

            APP_CLONE_DIR=${CLONE_PARENT_DIR}/build/${CHANGED_BRANCH_REF}
            BUILD_CLONE_DIR=${CLONE_PARENT_DIR}/deploy/${CHANGED_BRANCH_REF}

            # ensure the build dir exists and is empty
            if [[  -d ${APP_CLONE_DIR} ]]; then
                rm -Rf ${APP_CLONE_DIR}               
            fi
            mkdir -p  ${APP_CLONE_DIR}

            # ensure the deploy dir exists and is empty
            if [[  -d ${BUILD_CLONE_DIR} ]]; then
                rm -Rf ${BUILD_CLONE_DIR}               
            fi
            mkdir -p  ${BUILD_CLONE_DIR}
		    
		    # checkout app branch
		    git clone -b ${CHANGED_BRANCH} ${APP_GIT_REPO} ${APP_CLONE_DIR}

		    # if there was a clone error inform the user, if not carry on
	        if [[ $? -ne 0 ]]; then
	        	log_message "ERROR: Checkout of app code failed, build will be skiped"
	        else
			    # run npm test
			    cd ${APP_CLONE_DIR} && npm test 
			    
			    # if the test failed inform the user, if not carry on to deploy
			    if [[ $? -ne 0 ]]; then
	                log_message "ERROR: Build for branch ${CHANGED_BRANCH} failed, this will not be deployed"
	            else
	            	log_message "SUCCESS: Build for branch ${CHANGED_BRANCH} passed, deployment will follow"
	            	
	            	# clone the deployment repo, ok this may sem silly as this script is part of it
	            	# however this script may be running standalone or the deployment code may have changed
	            	git clone ${DEPLOY_GIT_REPO} ${BUILD_CLONE_DIR}

	            	# if the deplyment clone failed inform the user, if not carry on
	            	if [[ $? -ne 0 ]]; then
	            	    log_message "ERROR: Checkout of deploy tools faled, build will be skiped"
	            	else	     	
		            	cd ${BUILD_CLONE_DIR}

		            	# if the hiera directory does not exist as part of the deployment location inform the user,
		            	# otherwise....you guessed it, carry on
		            	if [[ ! -d ${BUILD_CLONE_DIR}/puppet/hiera ]]; then
		            		log_message "ERROR: Unable to find local hiera directory, build will be skipped"
		            	else
		            		# create override hiera file, this will allow the build to pickup the desired repo/branch 
		            	    echo -e "---\n\nbuildit::app::app_repo_url: '${APP_GIT_REPO}'\nbuildit::app::app_repo_revision: '${CHANGED_BRANCH}'" > ${BUILD_CLONE_DIR}/puppet/hiera/override.yaml

		            	    # if we cannot create the override yaml inform the user, otherwise spin on...
		                    if [[ $? -ne 0 ]]; then
		                        log_message "ERROR: Unable to create override yaml, build will be skipped"
		                    else
		                    	# bring up the vagrant environment

		                    	# check if vagrant started, if not sucessfully then cal vagrant destroy to attempt to clean up
		                    	vagrant up 
		                    	if [[ $? -ne 0 ]]; then
		                    		log_message "ERROR: Vagrant up failed, as the deployment may well be in an unknown state vagrant destroy will be called"
		                    		vagrant destroy -f
		                    	else
			                    	# check if there is a deployment timeout, if so sleep and then destroy this deploy and carry on the loop
			                    	# if not exit this script as the deploy is here to stay for the forseable
			                    	if [[ ${DEPLOY_SLEEP} -eq 0 ]]; then
			                            log_message "There is no timeout specified for deployment, therefore this script will exit and leave you with your vagratn environment"
			                            exit 0
			                        else
			                        	log_message "### Deployment is now complete, in ${DEPLOY_SLEEP} seconds the environment will be pulled down, get testing!!"
			                        	sleep ${DEPLOY_SLEEP}
			                        	vagrant destroy -f
			                        	if [[ $? -ne 0 ]]; then
                                            log_message "ERROR: vagrant destroy failed, the deployment is possibly in an inconistent state, as a result this script will, please look to cleanup manually"
                                            exit 1
			                        	fi
			                    	fi
		                    	fi
		                    fi
		                fi
	                fi
			    fi
		    fi

		    # no matter what hapened with the build/deploy, remove the tmp build and deploy flders
		    rm -Rf ${APP_CLONE_DIR}
		    rm -Rf ${BUILD_CLONE_DIR}

		    # change back into the initial directory
		    cd ${CWD}
	    done

    	# replace old branches list with the current one
	    BRANCHES=(${LATEST_BRANCHES[@]})

	# if the list of changes is blank inform the user nothing has changed
    else 
    	log_message "no changes detected, sleeping for ${LOOP_INTERVAL}"
    fi

    # sleep for the desired amount of time and then go back through the loop again
    sleep ${LOOP_INTERVAL}
done
