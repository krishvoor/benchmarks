#!/bin/bash
#
# Copyright (c) 2020, 2021 Red Hat, IBM Corporation and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
### Script to perform load test on HyperShift###
#

CURRENT_DIR="$(dirname "$(realpath "$0")")"
TEMP_DIR=$(mktemp -d)
export UUID=$(uuidgen)
export KUBE_BURNER_RELEASE=${KUBE_BURNER_RELEASE:-0.16}
pushd "$TEMP_DIR" > /dev/null

# Describes usage of the script
function usuage() {
    # Update the echo statement
	echo
	echo "Usage: $0 --clustertype=CLUSTER_TYPE -s BENCHMARK_SERVER -e RESULTS_DIR_PATH [-w WARMUPS] [-m MEASURES] [-i TOTAL_INST] [--iter=TOTAL_ITR] [-r= set redeploy to true] [-n NAMESPACE] [-g TFB_IMAGE] [--cpureq=CPU_REQ] [--memreq=MEM_REQ] [--cpulim=CPU_LIM] [--memlim=MEM_LIM] [-t THREAD] [-R REQUEST_RATE] [-d DURATION] [--connection=CONNECTIONS]"
	exit -1
}

# Download kube-burner tool
function download_kb() {
    pushd "${TEMP_DIR}" > /dev/null
    echo "Downloading Kube-burner tool..."
    curl -L https://github.com/cloud-bulldozer/kube-burner/releases/download/v${KUBE_BURNER_RELEASE}/kube-burner-${KUBE_BURNER_RELEASE}-Linux-x86_64.tar.gz -o kube-burner.tar.gz
    mkdir -p ${TEMP_DIR}/bin
    sudo tar -xvzf kube-burner.tar.gz -C ${TEMP_DIR}/bin/
    popd
}

function submodule_update() {
    # Running the workload
    pushd "${CURRENT_DIR}" > /dev/null
    git submodule init
    git submodule update
    popd
}

function start_and_rollout_tweaks() {
    # Function to edit CPU/ Memory SPECS for respective services/deployments
    
}

function deploy_the_load() {

}