from prometheus_api_client import PrometheusConnect
from yaml import SafeLoader
import time


# Enhancements
# 1) Supply OBO, MC_PROM, HC_PROM via
# https://docs.python.org/3/library/argparse.html
# 2) Maintain files for metric endpoint & TOKENS

# Stage MC_PROM, OBO, HC_PROM URLs
# This can be passed as arguments to the python script
mc_prom_url = "https://prometheus-k8s-openshift-monitoring.apps.hs-mc-jbahnnsi0.0j7y.s1.devshift.org"
obo_url = "http://prometheus-hypershift-openshift-observability-operator.apps.hs-mc-jbahnnsi0.0j7y.s1.devshift.org"
hc_url = "https://prometheus-k8s-openshift-monitoring.apps.rosa.kruiz-nug-0001.6tjk.s3.devshift.org"

# Stage MC_BEARER, OBO_BEARER, HC_BEARER
mc_prom_header = {"Authorization": "Bearer <UPDATE_ME>"}
obo_header = mc_prom_header
hc_header = {"Authorization": "Bearer <UPDATE_ME>"}


# Connect to MC_PROM
mc_prom = PrometheusConnect(url=mc_prom_url, headers=mc_prom_header, disable_ssl=True)

# Connect to OBO
obo_prom = PrometheusConnect(url=obo_url, headers=obo_header, disable_ssl=False)

# Connect to HC_PROM
hc_prom = PrometheusConnect(url=hc_url, headers=hc_header, disable_ssl=False)


################################################################################################
# MC Metrics from MC_Prom
################################################################################################
# Check if mc_prom.check_prometheus_connection() is True

mc_prom_kube_node_role = ' sum by (node) ( kube_node_role{role=~"master|infra|workload|obo" } ) '
mc_data_kube_node_role = mc_prom.get_current_metric_value(mc_prom_kube_node_role)
print(mc_data_kube_node_role)


################################################################################################
# HCP Metrics from HC_Prom
################################################################################################
# Check if hc_prom.check_prometheus_connection() is True

hc_query_containerCPU_Workers = '(avg(irate(container_cpu_usage_seconds_total{name!="",container!="POD",namespace=~"openshift-(sdn|ovn-kubernetes|ingress)"}[2m]) * 100 and on (node) kube_node_role{role="worker"}) by (namespace, pod, container)) > 0' 
hc_data_containerCPU_Workers= hc_prom.custom_query(hc_query_containerCPU_Workers)
print(hc_data_containerCPU_Workers)


################################################################################################
# OBO Metrics from OBO_Prom
################################################################################################
# Check if obo_prom.check_prometheus_connection() is True

obo_query_APIRequestRate = '( sum( irate( apiserver_request_total{namespace="ocm-staging-23c1ih4sou995ndcavpgfkbej9dr9r8f-xuelihp04274", job="apiserver", verb!="WATCH"} [2m] ) ) by (verb,resource,instance) ) > 0' 
obo_data_APIRequestRate = obo_prom.custom_query(obo_query_APIRequestRate)
print(obo_data_APIRequestRate)