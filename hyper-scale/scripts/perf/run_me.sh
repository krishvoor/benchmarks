#!/bin/bash
#
### Script to perform load test on HyperShift###
#

# Variables declared in this file
CURRENT_DIR="$(dirname "$(realpath "$0")")"
pushd "${CURRENT_DIR}" > /dev/null

# Variables read from krishvoor/kruize-demos/hpo_helpers/*script.sh
RESULTS_DIR=$1 ## Check whether this is required
NAMESPACE= $2
CPU_REQUESTS= $3
MEMORY_REQUESTS= $4
SERVICE_NAME= $5

# Create(s) the results directory
RESULTS_DIR_PATH=result
rm -rf ${RESULTS_DIR_PATH}/hyperscale-* || true
RESULTS_DIR_ROOT=${RESULTS_DIR_PATH}/hyperscale-$(date +%Y%m%d%H%M)
mkdir -p ${RESULTS_DIR_ROOT} || true
mkdir -p ${RESULTS_DIR} || true

# Describes usage of the script
function usuage() {
    # Update the echo statement
	echo
	echo "Usage: $0 --clustertype=CLUSTER_TYPE -s BENCHMARK_SERVER -e RESULTS_DIR_PATH [-w WARMUPS] [-m MEASURES] [-i TOTAL_INST] [--iter=TOTAL_ITR] [-r= set redeploy to true] [-n NAMESPACE] [-g TFB_IMAGE] [--cpureq=CPU_REQ] [--memreq=MEM_REQ] [--cpulim=CPU_LIM] [--memlim=MEM_LIM] [-t THREAD] [-R REQUEST_RATE] [-d DURATION] [--connection=CONNECTIONS]"
	exit -1
}

function deploy_me() {

    # 1) Deploy the P75 cluster-ms kube-burner load
    # 2) Run the PromQL Queries against External-Thanos/OCP's Prometheus

    oc project ${NAMESPACE}


    echo "################################################################################"
    echo "                    Patching ${SERVICE_NAME}'s CPU & Memory                     "
    echo "################################################################################"

    oc patch deployment ${SERVICE_NAME} --type=strategic -p='{"spec":{"template":{"spec":{"containers":[{"name":"kube-apiserver","resources": {"requests":{"cpu":"'${CPU_REQUESTS}'m","memory":"'${MEMORY_REQUESTS}'M"}}}]}}}}'
    oc wait --for=condition=Available=true deployments -n ${NAMESPACE} ${SERVICE_NAME}

    echo "################################################################################"
    echo " Deploying the P75 Workloads with ${CPU_REQUESTS} & ${MEMORY_REQUESTS}"
    echo "################################################################################"
    pushd e2e-benchmarking/workloads/kube-burner/ > /dev/null
    WORKLOAD=cluster-density-ms ./run.sh
    popd > /dev/null

    # Run the utils/monitoring_metrics.csv file
    echo "################################################################################"
    echo "Writing to csv file"
    echo "################################################################################"
    ../utils/monitor-metrics-promql.sh 1 10m ${RESULTS_DIR_ROOT} ${SERVICE_NAME} ${SERVICE_NAME} ${NAMESPACE}
    # Check this logic
    cp ../utils/output.csv ${RESULTS_DIR}/output.csv
}

deploy_me