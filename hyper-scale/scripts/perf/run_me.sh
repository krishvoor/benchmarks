#!/bin/bash
#
### Script to perform load test on HyperShift###
#

# Variables declared in this file
CURRENT_DIR="$(dirname "$(realpath "$0")")"
TEMP_DIR=$(mktemp -d)
pushd "${CURRENT_DIR}" > /dev/null

# Create(s) the results directory
RESULTS_DIR_PATH=result
rm -rf ${RESULTS_DIR_PATH}/hyperscale-* || true
RESULTS_DIR_ROOT=${RESULTS_DIR_PATH}/hyperscale-$(date +%Y%m%d%H%M)


# Variables declared are read from krishvoor/kruize-demos/hpo_helpers/*script.sh
CPU_REQUESTS= <UPDATE_ME>
MEMORY_REQUESTS= <UPDATE_ME>
### Kubernetes object 
SERVICE_NAME= <UPDATE_ME>

# Describes usage of the script
function usuage() {
    # Update the echo statement
	echo
	echo "Usage: $0 --clustertype=CLUSTER_TYPE -s BENCHMARK_SERVER -e RESULTS_DIR_PATH [-w WARMUPS] [-m MEASURES] [-i TOTAL_INST] [--iter=TOTAL_ITR] [-r= set redeploy to true] [-n NAMESPACE] [-g TFB_IMAGE] [--cpureq=CPU_REQ] [--memreq=MEM_REQ] [--cpulim=CPU_LIM] [--memlim=MEM_LIM] [-t THREAD] [-R REQUEST_RATE] [-d DURATION] [--connection=CONNECTIONS]"
	exit -1
}

function start_and_rollout_tweaks() {
    # Function to edit CPU/ Memory SPECS for respective services/deployments
    
}

function write_to_csv() {
    # Write to csv File
    echo "################################################################################"
    echo "Writing to csv file"
    echo "################################################################################"
  
}

function deploy_the_load() {
    # Deploy the load via kube-burner P75 Load

    oc project <HCP_NAMESPACE>

    echo "################################################################################"
    echo "Patching ${SERVICE_NAME}'s CPU"
    echo "################################################################################"

    oc patch deployment kube-apiserver --type=strategic -p='{"spec":{"template":{"spec":{"containers":[{"name":"kube-apiserver","resources": {"requests":{"cpu":"${CPU_REQUESTS}m"}}}]}}}}'
    oc wait --for=condition=Available=true deployments -n <HCP_NAMESPACE> <DEPLOYMENTS.APPS>

    echo "################################################################################"
    echo "Patching ${SERVICE_NAME}'s Memory"
    echo "################################################################################"

    oc patch deployment kube-apiserver --type=strategic -p='{"spec":{"template":{"spec":{"containers":[{"name":"kube-apiserver","resources": {"requests":{"memory":"${MEMORY_REQUESTS}M"}}}]}}}}'
    oc wait --for=condition=Available=true deployments -n <HCP_NAMESPACE> <DEPLOYMENTS.APPS>

    echo "################################################################################"
    echo " Deploying the P75 Workloads with ${CPU_REQUESTS} & ${MEMORY_REQUESTS}"
    echo "################################################################################"
    pushd e2e-benchmarking/workloads/kube-burner/ > /dev/null
    WORKLOAD=cluster-density-ms ./run.sh
}