#!/bin/sh
#
# HELM installation
cd /tmp
sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh

# Add Keda’s helm repo
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Install it inside "keda" namespace. 
kubectl create namespace keda
helm install keda kedacore/keda --namespace keda
helm install keda kedacore/keda --namespace testing

# Prometheus Installation
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus --namespace keda
helm install prometheus prometheus-community/prometheus --namespace testing