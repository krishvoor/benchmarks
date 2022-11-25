#!/bin/bash
#
### Installs the pre-requisites

CURRENT_DIR="$(dirname "$(realpath "$0")")"
export KUBE_BURNER_RELEASE=${KUBE_BURNER_RELEASE:-0.16}


function submodule_update() {
    # Running the workload

    echo "################################################################################"
    echo ""
    echo "################################################################################"
   
    pushd "${CURRENT_DIR}" > /dev/null
    git submodule --recursive update
    popd
}

function download_kb() {
    echo "################################################################################"
    echo "Installing kube-burner"
    echo "################################################################################"
    KB_EXISTS=$(which kube-burner)
    if [ $? -ne 0 ]; then
        export KUBE_BURNER_RELEASE=${KUBE_BURNER_RELEASE:-0.16}
        curl -L https://github.com/cloud-bulldozer/kube-burner/releases/download/v${KUBE_BURNER_RELEASE}/kube-burner-${KUBE_BURNER_RELEASE}-Linux-x86_64.tar.gz -o kube-burner.tar.gz
        sudo tar -xvzf kube-burner.tar.gz -C /usr/local/bin/
    fi
}