#!/bin/bash

SUPPORTED_DISTROS="Ubuntu 20.04, Ubuntu 22.04, OpenSUSE Leap 15.3, OpenSUSE Leap 15.4, Fedora 35, Fedora 36, Fedora 37, Debian 11"

function usage {
    echo -e "Starts $SUPPORTED_DISTROS virtual machines, runs their configured provisionners and shuts them down\n
            -v | --vm-path <VMpath>:\t Start the VM contained in the VMpath, run its configured provisionners and shut it down\n
            -d | --destroy:\t Destroy the VM after being shut down\n
            -h | --help:\t Display help\n"
    exit
}

script_dir="$(dirname "$(readlink -f "$0")")"


LISTPATH_DEFAULT="fedora/35/ fedora/36/ fedora/37/ debian/11/ ubuntu/20.04/ ubuntu/22.04/ opensuse-leap/15.3/ opensuse-leap/15.4/"



LISTPATH=""
DESTROY_AFTER="n"

error_message () {
	echo "Your distribution, $PRETTY_NAME, is not supported. Supported distribution are $SUPPORTED_DISTROS. For more information, please check https://docs.redpesk.bzh/"
}

BRANCH="upstream"

#test arguments
while [[ $# -gt 0 ]]; do
    OPTION="$1"
    case $OPTION in
    -h | --help)
        usage;
    ;;
    -d | --destroy)
        DESTROY_AFTER="y"
        shift 1;
    ;;
    -b | --branch)
        BRANCH="$2"
        shift 2;
    ;;
    -v | --vm-path)
        if [ -z $2 ]; then 
            echo "No parameter for option --vm-path"
            usage
            exit 1
        fi
        LISTPATH="${LISTPATH} $2"
        shift 2;
    ;;
    *)
        usage;
    ;;
    esac
done

if [ -z "${LISTPATH}" ]; then
    LISTPATH="${LISTPATH_DEFAULT}"
fi

#function that runs all VMs from listepath
run_all_test(){   
    for path in ${LISTPATH}; do
        run_one_test "${script_dir}/${path}"
    done
}

run_one_test(){
    cd "$1" || exit
    vagrant up --no-provision
    if [ "${BRANCH}" == "master" ]; then
        vagrant provision --provision-with test-sdk-script,test-sdk-master-script,install-redpesk-sdk
    elif [ "${BRANCH}" == "next" ]; then
        vagrant provision --provision-with test-sdk-script,test-sdk-next-script,install-redpesk-sdk
    else
        vagrant provision --provision-with test-sdk-script,test-sdk-upstream-script,install-redpesk-sdk
    fi
    vagrant halt
    if [ "$DESTROY_AFTER" = "y" ]; then
        vagrant destroy -f
    fi
    cd ../..
}

run_all_test