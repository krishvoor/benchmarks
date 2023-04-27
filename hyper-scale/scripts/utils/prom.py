from prometheus_api_client import PrometheusConnect
from yaml import SafeLoader
import time

prom_url = "https://prometheus-k8s-openshift-monitoring.apps.hs-mc-jbahnnsi0.0j7y.s1.devshift.org" 
prom_header = {"Authorization": "Bearer <UPDATE_THIS>"}
prom = PrometheusConnect(url=prom_url, headers=prom_header, disable_ssl=True)

# Return Current values MC nodes
query_kube_node_role = ' sum by (node) ( kube_node_role{role=~"master|infra|workload|obo" } ) '
data = prom.get_current_metric_value(query_kube_node_role)
print(data)

# APIRequestRate on HCP

## apiserver_request_total cannot not find HCP_NAMESPACE
##  Tried on default NS, job=kube-apiserver was not found
query_APIRequestRate = '( sum( irate( apiserver_request_total{namespace=~"default", job="apiserver", verb!="WATCH"} [2m] ) ) by (verb,resource,instance) ) > 0' 
prom.custom_query(query_APIRequestRate)

query_APIRequestRate = '( sum( irate( apiserver_request_total{namespace="ocm-staging-23c1ih4sou995ndcavpgfkbej9dr9r8f-xuelihp04274"", job="apiserver", verb!="WATCH"} [2m] ) ) by (verb,resource,instance) ) > 0' 
