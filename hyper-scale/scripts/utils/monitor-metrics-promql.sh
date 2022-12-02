#!/bin/bash
set -ex
#
# Copyright (c) 2020, 2021 IBM Corporation, RedHat and others.
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
### Script to get pod and cluster information through prometheus queries###
#
# checks if the previous command is executed successfully
# input:Return value of previous command
# output:Prompts the error message if the return value is not zero
function err_exit() {
    if [ $? != 0 ]; then
        printf "$*"
        echo
        exit -1
    fi
}

function cpu_metrics() {
    URL=$1
    TOKEN=$2
    RESULTS_DIR=$3
    ITER=$4
    DEPLOYMENT_NAME=$5
    CONTAINER_NAME=$6
    NAMESPACE=$7
    INTERVAL=$8

    while true; do
        start_timestamp=$(date)
        # Processing curl output "timestamp value" using jq tool.
        # cpu_request_avg_container
        cpu_request_avg_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=avg(kube_pod_container_resource_requests{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'", resource="cpu", unit="core"})' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # cpu_request_sum_container
        cpu_request_sum_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(kube_pod_container_resource_requests{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'", resource="cpu", unit="core"})' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # cpu_usage_avg_container
        cpu_usage_avg_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=avg(avg_over_time(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # cpu_usage_max_container
        cpu_usage_max_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=max(max_over_time(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # cpu_usage_min_container
        cpu_usage_min_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=min(min_over_time(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # cpu_throttle_avg_container
        cpu_throttle_avg_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=avg(rate(container_cpu_cfs_throttled_seconds_total{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        sleep ${INTERVAL}
        end_timestamp=$(date)
        echo "${start_timestamp},${end_timestamp},${cpu_request_avg_container},${cpu_request_sum_container},${cpu_usage_avg_container},${cpu_usage_max_container},${cpu_usage_min_container},${cpu_throttle_avg_container}" >>${RESULTS_DIR}/cpu_metrics.csv
    done
}

function mem_metrics() {
    URL=$1
    TOKEN=$2
    RESULTS_DIR=$3
    ITER=$4
    DEPLOYMENT_NAME=$5
    CONTAINER_NAME=$6
    NAMESPACE=$7
    INTERVAL=$8

    # Delete the old json file if any
    rm -rf ${RESULTS_DIR}/mem_request_avg_container-${ITER}.json
    while true; do
        start_timestamp=$(date)
        # Processing curl output "timestamp value" using jq tool.
        # mem_request_avg_container
        mem_request_avg_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=avg(kube_pod_container_resource_requests{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'", resource="memory", unit="byte"})' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # mem_request_sum_container
        mem_request_sum_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(kube_pod_container_resource_requests{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'", resource="memory", unit="byte"})' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # mem_usage_avg_container
        mem_usage_avg_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=avg(avg_over_time(container_memory_working_set_bytes{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # mem_usage_min_container
        mem_usage_min_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=min(min_over_time(container_memory_working_set_bytes{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # mem_usage_max_container
        mem_usage_max_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=max(max_over_time(container_memory_working_set_bytes{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # mem_rss_avg_container
        mem_rss_avg_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=avg(avg_over_time(container_memory_rss{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # mem_rss_min_container
        mem_rss_min_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=min(min_over_time(container_memory_rss{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        # mem_rss_max_container
        mem_rss_max_container=$(curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=max(max_over_time(container_memory_rss{pod=~"'"${DEPLOYMENT_NAME}-[^-]*-[^-]*$"'", container="'"${CONTAINER_NAME}"'", namespace="'"${NAMESPACE}"'"}['"${INTERVAL}"']))' ${URL} | jq -c '[ .data.result[] | .value[1]] | .[]')

        sleep ${INTERVAL}
        end_timestamp=$(date)
        echo ",${mem_request_avg_container},${mem_request_sum_container},${mem_usage_avg_container},${mem_usage_max_container},${mem_usage_min_container},${mem_rss_avg_container},${mem_rss_max_container},${mem_rss_min_container}" >>${RESULTS_DIR}/mem_metrics.csv
    done
}

ITER=$1
TIMEOUT=$2
RESULTS_DIR=$3
DEPLOYMENT_NAME=$4
CONTAINER_NAME=$5
NAMESPACE=$6
INTERVAL=5m

mkdir -p ${RESULTS_DIR}

QUERY_APP=$(oc get routes -n openshift-monitoring prometheus-k8s -o jsonpath="{.spec.host}")
URL=https://${QUERY_APP}/api/v1/query
TOKEN=$(oc whoami --show-token)

export -f err_exit cpu_metrics mem_metrics

echo "start_timestamp,end_timestamp,cpu_request_avg_container,cpu_request_sum_container,cpu_usage_avg_container,cpu_usage_max_container,cpu_usage_min_container,cpu_throttle_avg_container" >${RESULTS_DIR}/cpu_metrics.csv
echo ",mem_request_avg_container,mem_request_sum_container,mem_usage_avg_container,mem_usage_max_container,mem_usage_min_container,mem_rss_avg_container,mem_rss_max_container,mem_rss_min_container" >${RESULTS_DIR}/mem_metrics.csv

echo "Collecting metric data" >>setup.log
start_timestamp=$(date)
timeout ${TIMEOUT} bash -c "cpu_metrics ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${DEPLOYMENT_NAME} ${CONTAINER_NAME} ${NAMESPACE} ${INTERVAL}" &
timeout ${TIMEOUT} bash -c "mem_metrics ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${DEPLOYMENT_NAME} ${CONTAINER_NAME} ${NAMESPACE} ${INTERVAL}" &
sleep ${TIMEOUT}
paste ${RESULTS_DIR}/cpu_metrics.csv ${RESULTS_DIR}/mem_metrics.csv >${RESULTS_DIR}/../../monitoring_metrics.csv
