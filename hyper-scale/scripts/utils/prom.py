from prometheus_api_client import PrometheusConnect
import csv
import urllib3
import argparse
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


# Creating the Parser Object
parser = argparse.ArgumentParser(description="Collect Prom metrics from MC/ OBO/ HC and consolidate to a csv file")

# Adding the argumets
parser.add_argument('--mc_prom_url',
                    help='Supply the MC Prom URL')

parser.add_argument('--obo_prom_url',
                    help="Supply the OBO Prom URL")

parser.add_argument('--hc_prom_url',
                    help="Supply the HC Prom URL")

parser.add_argument('--mc_bearer_token',
                    help='Supply the MC Bearer Token')

parser.add_argument('--hc_bearer_token',
                    help='Supply the HC Bearer Token')

parser.add_argument('--hcp_namespace',
                    help='Supply the HCP Namespace')

parser.add_argument('--deployment_name',
                    help="Supply the Deployment name")

parser.add_argument('--container_name',
                    help="Supply the Container name")

# Assign them as attributes
args = parser.parse_args()


mc_prom_header = f'{{"Authorization": "Bearer {args.mc_bearer_token}"}}'
obo_prom_header = f'{{"Authorization": "Bearer {args.mc_bearer_token}"}}'
hc_prom_header = f'{{"Authorization": "Bearer {args.hc_bearer_token}"}}'

HCP_NAMESPACE = f'{args.hcp_namespace}'
DEPLOYMENT_NAME = f'{args.deployment_name}'
CONTAINER_NAME = f'{args.container_name}' 


# Connect to MC_PROM
mc_prom = PrometheusConnect(url=f'{args.mc_prom_url}', headers=mc_prom_header, disable_ssl=True)

# Connect to OBO
obo_prom = PrometheusConnect(url=f'{args.obo_prom_url}', headers=obo_prom_header, disable_ssl=False)

# Connect to HC_PROM
hc_prom = PrometheusConnect(url=f'{args.hc_prom_url}', headers=hc_prom_header, disable_ssl=False)


################################################################################################
# MC Metrics from HC_Prom
################################################################################################

# MaxMemory
mc_max_mem_container = f'max(max_over_time(container_memory_working_set_bytes{{namespace=~"{HCP_NAMESPACE}", pod=~"{CONTAINER_NAME}.*"}}[2m]))'
mc_max_mem_container_data = mc_prom.custom_query(mc_max_mem_container)
print(mc_max_mem_container_data)

# MinMemory
mc_min_mem_container = f'min(max_over_time(container_memory_working_set_bytes{{namespace=~"{HCP_NAMESPACE}", pod=~"{CONTAINER_NAME}.*"}}[2m]))'
mc_min_mem_container_data = mc_prom.custom_query(mc_min_mem_container)
print(mc_min_mem_container_data)


# P95 CPU
mc_95_cpu_container = f'quantile_over_time(0.95, rate(container_cpu_usage_seconds_total{{namespace=~"{HCP_NAMESPACE}", container=~"{CONTAINER_NAME}.*"}}[2m])[30m:])'
mc_95_cpu_container_data = mc_prom.custom_query(mc_95_cpu_container)
print(mc_95_cpu_container_data)

# P90 CPU
mc_90_cpu_container = f'quantile_over_time(0.90, rate(container_cpu_usage_seconds_total{{namespace=~"{HCP_NAMESPACE}", container=~"{CONTAINER_NAME}.*"}}[2m])[30m:])'
mc_90_cpu_container_data = mc_prom.custom_query(mc_90_cpu_container)
print(mc_90_cpu_container_data)

# P75 CPU
mc_75_cpu_container = f'quantile_over_time(0.75, rate(container_cpu_usage_seconds_total{{namespace=~"{HCP_NAMESPACE}", container=~"{CONTAINER_NAME}.*"}}[2m])[30m:])'
mc_75_cpu_container_data = mc_prom.custom_query(mc_75_cpu_container)
print(mc_75_cpu_container_data)


################################################################################################
# OBO Metrics from OBO_Prom
################################################################################################

obo_schedulingThroughput = f'irate(apiserver_request_total {{namespace=~"{HCP_NAMESPACE}", verb="POST", resource="pods", subresource="binding", code="201"}}[2m]) > 0'
obo_schedulingThroughput_data = obo_prom.custom_query(obo_schedulingThroughput)
print(obo_schedulingThroughput_data)


obo_APIRequestRate = f' sum ( irate ( apiserver_request_total {{namespace=~"{HCP_NAMESPACE}", job="kube-apiserver",verb!="WATCH"}}[2m]) ) by ( verb, resource, instance) > 0 '
obo_APIRequestRate_data = obo_prom.custom_query(obo_APIRequestRate)
print(obo_APIRequestRate_data)

obo_mutatingAPICallsLatency = f' histogram_quantile (0.99, sum ( irate ( apiserver_request_duration_seconds_bucket{{namespace=~"{HCP_NAMESPACE}", job="kube-apiserver", verb=~"POST|PUT|DELETE|PATCH", subresource!~"log|exec|portforward|attach|proxy"}}[2m])) by ( le, resource, verb, scope)) > 0'
obo_mutatingAPICallsLatency_data = obo_prom.custom_query(obo_mutatingAPICallsLatency)
print(obo_mutatingAPICallsLatency_data)


output_csv_file = 'final_output.csv'

row_headers = [mc_max_mem_container_data, mc_min_mem_container_data, mc_95_cpu_container_data, 
               mc_90_cpu_container_data, mc_75_cpu_container_data, obo_schedulingThroughput_data, 
               obo_APIRequestRate_data, obo_mutatingAPICallsLatency_data]

headers = ["mc_max_mem_container", "mc_min_mem_container", "mc_95_cpu_container", 
               "mc_90_cpu_container", "mc_75_cpu_container", "obo_schedulingThroughput", 
               "obo_APIRequestRate", "obo_mutatingAPICallsLatency"]

# Save the results into a CSV file
with open('output_csv_file', 'a', newline='') as csvfile:
    print(" Move to end of file")
    csvfile.seek(0, 2)

    # Write the Row Header details
    output_file_writer = csv.writer(csvfile)
    output_file_writer.writerow( headers )
    output_file_writer.writerow( row_headers )
    
    # Reset cursor to file starting and close the file
    csvfile.close()