from datetime import datetime, timedelta
from prometheus_api_client import PrometheusConnect
import csv
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


# Enhancements
# 1) Supply OBO, MC_PROM, HC_PROM via
# https://docs.python.org/3/library/argparse.html
# 2) Maintain files for metric endpoint & TOKENS

# Prefix o/p csv file name w/ HCP name
# Stage MC_PROM, OBO, HC_PROM URLs
# This can be passed as arguments to the python script

# Check if mc_prom.check_prometheus_connection() is True
# Check if hc_prom.check_prometheus_connection() is True
# Check if obo_prom.check_prometheus_connection() is True


mc_prom_url = "https://prometheus-k8s-openshift-monitoring.apps.hs-mc-jbahnnsi0.0j7y.s1.devshift.org"
obo_prom_url = "http://prometheus-hypershift-openshift-observability-operator.apps.hs-mc-jbahnnsi0.0j7y.s1.devshift.org"
hc_prom_url = "https://prometheus-k8s-openshift-monitoring.apps.rosa.kruiz-rrl-0001.6bzt.s3.devshift.org"

# Stage MC_BEARER, OBO_BEARER, HC_BEARER
mc_prom_header = {"Authorization": "Bearer <UPDATE_ME>"}
obo_header = mc_prom_header
hc_header = {"Authorization": "Bearer <UPDATE_ME>"}


# Connect to MC_PROM
mc_prom = PrometheusConnect(url=mc_prom_url, headers=mc_prom_header, disable_ssl=True)

# Connect to OBO
obo_prom = PrometheusConnect(url=obo_prom_url, headers=obo_header, disable_ssl=False)

# Connect to HC_PROM
hc_prom = PrometheusConnect(url=hc_prom_url, headers=hc_header, disable_ssl=False)


# Variables to be used
HCP_NAMESPACE = "ocm-staging-23fd33s6u5dr56rbvivaciovsthu9qdm-kruiz-rrl-0001"
DEPLOYMENT_NAME = "openshift-apiserver"
CONTAINER_NAME = "kube-apiserver"


################################################################################################
# MC Metrics from HC_Prom
################################################################################################

# MaxMemory
mc_max_mem_container = 'max(max_over_time(container_memory_working_set_bytes{pod=~"kube-apiserver.*", namespace="ocm-staging-23fd33s6u5dr56rbvivaciovsthu9qdm-kruiz-rrl-0001"}[2m]))'
mc_max_mem_container_data = mc_prom.custom_query(mc_max_mem_container)
print(mc_max_mem_container_data)

# MinMemory
mc_min_mem_container = 'min(max_over_time(container_memory_working_set_bytes{pod=~"kube-apiserver.*", namespace="ocm-staging-23fd33s6u5dr56rbvivaciovsthu9qdm-kruiz-rrl-0001"}[2m]))'
mc_min_mem_container_data = mc_prom.custom_query(mc_min_mem_container)
print(mc_min_mem_container_data)


# P95 CPU
mc_95_cpu_container = 'histogram_quantile(0.95, rate(kube_pod_container_resource_requests{namespace=~"ocm-staging-23fd33s6u5dr56rbvivaciovsthu9qdm-kruiz-rrl-0001", resource="cpu", unit="core", pod=~"kube-apiserver-.*"}[30m]))'
mc_95_cpu_container_data = mc_prom.custom_query(mc_95_cpu_container)

# P90 CPU
mc_90_cpu_container = 'histogram_quantile(0.90, rate(kube_pod_container_resource_requests{namespace=~"ocm-staging-23fd33s6u5dr56rbvivaciovsthu9qdm-kruiz-rrl-0001", resource="cpu", unit="core", pod=~"kube-apiserver-.*"}[30m]))'
mc_90_cpu_container_data = mc_prom.custom_query(mc_90_cpu_container)

# P75 CPU
mc_75_cpu_container = 'histogram_quantile(0.75, rate(kube_pod_container_resource_requests{namespace=~"ocm-staging-23fd33s6u5dr56rbvivaciovsthu9qdm-kruiz-rrl-0001", resource="cpu", unit="core", pod=~"kube-apiserver-.*"}[30m]))'
mc_75_cpu_container_data = mc_prom.custom_query(mc_75_cpu_container)

# Average CPU Usuage
mc_avg_cpu_pod = '(sum(irate(container_cpu_usage_seconds_total{openshift_cluster_name=~"${MGMT_CLUSTER_NAME}",name!="",container!="POD",namespace=~"${HOSTED_CLUSTER_NS}"}[2m]) * 100) by (pod, container, namespace, node, openshift_cluster_name)) > 0'

################################################################################################
# HCP Metrics from HC_Prom
################################################################################################



################################################################################################
# OBO Metrics from OBO_Prom
################################################################################################

# Needs formatting
obo_schedulingThroughput = 'irate(apiserver_request_total {{namespace=~"{}", verb="POST", resource="pods", subresource="binding", code="201"}}[2m]) > 0'.format(HCP_NAMESPACE)
obo_schedulingThroughput_data = obo_prom.custom_query(obo_schedulingThroughput)
print(obo_schedulingThroughput_data)


obo_APIRequestRate = ' sum ( irate ( apiserver_request_total {namespace=~"HCP_NAMESPACE}", job="kube-apiserver",verb!="WATCH"}[2m]) ) by ( verb, resource, instance) > 0 '
obo_APIRequestRate_data = obo_prom.custom_query(obo_APIRequestRate)
print(obo_APIRequestRate_data)

obo_mutatingAPICallsLatency = ' histogram_quantile (0.99, sum ( irate ( apiserver_request_duration_seconds_bucket{namespace=~"HCP_NAMESPACE", job="kube-apiserver", verb=~"POST|PUT|DELETE|PATCH", subresource!~"log|exec|portforward|attach|proxy"}[2m])) by ( le, resource, verb, scope)) > 0'
obo_mutatingAPICallsLatency_data = obo_prom.custom_query(obo_mutatingAPICallsLatency)
print(obo_mutatingAPICallsLatency_data)



# To-do:
# Append the HCP Name, iteration name
output_csv_file = 'final_output.csv'

row_headers = [mc_max_mem_container_data, mc_min_mem_container_data, mc_95_cpu_container_data, 
               mc_90_cpu_container_data, mc_75_cpu_container_data, obo_schedulingThroughput_data, 
               obo_APIRequestRate_data, obo_mutatingAPICallsLatency_data]

headers = ["mc_max_mem_container", "mc_min_mem_container", "mc_95_cpu_container", 
               "mc_90_cpu_container", "mc_75_cpu_container", "obo_schedulingThroughput", 
               "obo_APIRequestRate", "obo_mutatingAPICallsLatency"]

# Save the results into a CSV file
with open('output_csv_file', 'a', newline='') as csvfile:
    # Move to end of the file
    print(" Move to end of file")
    csvfile.seek(0, 2)

    # Write the Row Header details
    output_file_writer = csv.writer(csvfile)
    output_file_writer.writerow( headers )
    output_file_writer.writerow( row_headers )
    
    # Reset cursor to file starting and close the file
    csvfile.close()
