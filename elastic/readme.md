1. Install elasticsearch

Create folder in node 
mkdir -p /mnt/data-elastic/
chmod 777  -r /mnt/data-elastic/

Create PV 


https://github.com/elastic/helm-charts (read)
https://github.com/elastic/helm-charts/blob/main/elasticsearch/README.md (read)

helm repo add elastic https://helm.elastic.co
helm repo update elastic
helm upgrade --install elasticsearch --version 7.17.3 elastic/elasticsearch --set replicas=1 -n elastic --create-namespace --debug
helm upgrade --install kibana --version 7.17.3 elastic/kibana -n elastic --debug

or

helm upgrade --install elasticsearch --version 8.5.1 elastic/elasticsearch --set replicas=1 -n elastic --create-namespace --debug
helm upgrade --install kibana --version 8.5.1 elastic/kibana -n elastic --debug

2. Install Fluentd

https://github.com/fluent/fluentd-kubernetes-daemonset

https://docs.fluentd.org/configuration/config-file#5.-group-filter-and-output-the-label-directive