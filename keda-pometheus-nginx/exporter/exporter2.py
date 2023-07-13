from prometheus_client import Counter, start_http_server
import os
import time

# Create a Counter metric to track the number of files in the folder
file_count_metric = Counter('folder_files_total', 'Total number of files in the folder')

# Function to update the file count metric
def update_file_count_metric():
    folder_path = 'C:\\Users\\username\\Documents\\GitHub\\k8s\keda-pometheus-nginx'
    file_count = len(os.listdir(folder_path))
    file_count_metric.inc(file_count)

# Start the Prometheus HTTP server on the specified port
start_http_server(8888)
print("http server run")

# Periodically update the file count metric
while True:
    update_file_count_metric()
    time.sleep(60)  # Update the metric every 60 seconds



#folder_name = str("C:\\Users\\username\\Documents\\GitHub\\k8s\keda-pometheus-nginx")
