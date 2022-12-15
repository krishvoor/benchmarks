#!/bin/bash
set -x
#
### Script to perform load test on HyperShift###
#

# Variables declared in this file
CURRENT_DIR="$(dirname "$(realpath "$0")")"
MGMT_CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
pushd "${CURRENT_DIR}" >/dev/null

# Variables read from krishvoor/kruize-demos/hpo_helpers/*script.sh
RESULTS_DIR=$1 ## Check whether this is required
NAMESPACE=$2
CPU_REQUESTS=$3
MEMORY_REQUESTS=$4
SERVICE_NAME=$5

# Create(s) the results directory
RESULTS_DIR_PATH=result
#rm -rf ${RESULTS_DIR_PATH}/hyperscale-* || true
RESULTS_DIR_ROOT=${RESULTS_DIR_PATH}/hyperscale-$(date +%Y%m%d%H%M)
mkdir -p ${RESULTS_DIR_ROOT} || true
mkdir -p ${RESULTS_DIR} || true

# Describes usage of the script
function usuage() {
    # Update the echo statement
    echo
    echo "Usage: ./run_me.sh <RESULT_DIRECTORY_NAME> <HOSTER_CLUSTER_NS> <CPU_REQUEST> <MEMORY_REQUEST> <SERVICE_NAME>"
    exit -1
}

function deploy_me() {

    # 1) Deploy the P75 cluster-ms kube-burner load
    # 2) Run the PromQL Queries against External-Thanos/OCP's Prometheus

    oc project ${NAMESPACE}

    echo "################################################################################"
    echo "                    Patching ${SERVICE_NAME} CPU & Memory                     "
    echo "################################################################################"

    oc patch deployment ${SERVICE_NAME} --type=strategic -p='{"spec":{"template":{"spec":{"containers":[{"name":"kube-apiserver","resources": {"requests":{"cpu":"'${CPU_REQUESTS}'m","memory":"'${MEMORY_REQUESTS}'M"}}}]}}}}'
    oc wait --for=condition=available --timeout=600s deployments -n ${NAMESPACE} ${SERVICE_NAME}

    echo "################################################################################"
    echo "    Deploying the P75 Workloads with ${CPU_REQUESTS} & ${MEMORY_REQUESTS}       "
    echo "################################################################################"

    pushd ../../e2e-benchmarking/workloads/kube-burner/ >/dev/null

    # unset KUBECONFIG and remove the KUBECONFIG if any
    unset KUBECONFIG
    rm -rf kubeconfig* || true

    # Extract KUBECONFIG from targetted HCP, update KUBECONFIG
    oc extract secrets/admin-kubeconfig
    export KUBECONFIG=$PWD/kubeconfig

    # Run workload
    WORKLOAD=cluster-density-ms HYPERSHIFT=false MGMT_CLUSTER_NAME=${MGMT_CLUSTER_NAME} HOSTED_CLUSTER_NS=${NAMESPACE} CLEANUP=true ./run.sh
    popd >/dev/null

    # unset KUBECONFIG
    unset KUBECONFIG
    
    # Run the utils/monitoring_metrics.csv file
    echo "################################################################################"
    echo "                            Writing to csv file                                 "
    echo "################################################################################"
    ../utils/monitor-metrics-promql.sh 1 10m ${RESULTS_DIR_ROOT} ${SERVICE_NAME} ${SERVICE_NAME} ${NAMESPACE}
    # Check this logic
    #cp ../utils/output.csv ${RESULTS_DIR}/output.csv
}
export -f deploy_me usuage
deploy_me
