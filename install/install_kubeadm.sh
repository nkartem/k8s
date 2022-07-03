#!/bin/bash
###OS Rocky linux 8.6 node-master
########### https://citizix.com/how-to-setup-kubernetes-cluster-on-rocky-linux-8-using-kubeadm/
yum install -y nano mc git curl vim iproute-tc

cat /etc/hosts >> EOF
192.168.88.137 node1
192.168.88.138 node2
EOF

##########Disable SELinux###############
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

#####SWAP OFF########
sed -i '/swap/d' /etc/fstab
swapoff -a

#############
lsmod | grep br_netfilter
modprobe br_netfilter

cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF


cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

modprobe overlay
modprobe br_netfilter
sysctl --system

####### Firewall open ports ##########
systemctl stop firewalld
systemctl disable firewalld


# firewall-cmd --permanent --add-port=6443/tcp
# firewall-cmd --permanent --add-port=2379-2380/tcp
# firewall-cmd --permanent --add-port=10250/tcp
# firewall-cmd --permanent --add-port=10251/tcp
# firewall-cmd --permanent --add-port=10252/tcp
# firewall-cmd --reload
# modprobe br_netfilter
# sh -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"
# sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"

### Install docker
dnf install dnf-utils -y
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y containerd.io
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd
systemctl start containerd
systemctl status containerd
systemctl enable containerd
# dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
# dnf install docker-ce -y
# systemctl start docker
# systemctl enable docker

####Install kubelet, Kubeadm and kubectl
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
dnf install yum-plugin-versionlock -y
dnf versionlock kubelet kubeadm kubectl
systemctl enable --now kubelet
######## Enable and start kubelet
systemctl enable kubelet.service
systemctl start kubelet.service
systemctl status kubelet

##########Initialize the cluster (in the master node)
kubeadm config print init-defaults | tee ClusterConfiguration.yaml
sed -i '/name/d' ClusterConfiguration.yaml
sed -i 's/ advertiseAddress: 1.2.3.4/ advertiseAddress: 192.168.88.137/' ClusterConfiguration.yaml ### Your IP adress
sed -i 's/ criSocket: \/var\/run\/dockershim\.sock/ criSocket: \/run\/containerd\/containerd\.sock/' ClusterConfiguration.yaml


###############Configuring the kubelet cgroup driver
cat << EOF | cat >> ClusterConfiguration.yaml
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

kubeadm init --config=ClusterConfiguration.yaml

kdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get nodes



###########Setup networking with Calico
kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml













###Install Kubernetes Cluster with Kubeadm
# $ nano kubeadm-config.yaml
# # kubeadm-config.yaml
# kind: ClusterConfiguration
# apiVersion: kubeadm.k8s.io/v1beta3
# kubernetesVersion: v1.23.4
# kind: KubeletConfiguration
# apiVersion: kubelet.config.k8s.io/v1beta1
# cgroupDriver: cgroupfs

###
# kubeadm init
# kubeadm init --apiserver-advertise-address=192.168.88.137 --pod-network-cidr=10.10.0.0/16 
# kubeadm init --config kubeadm-config.yaml