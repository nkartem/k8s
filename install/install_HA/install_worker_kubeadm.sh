#!/bin/bash
###OS Rocky linux 8.6 node-worker
### sed -i -e 's/\r$//' install_worker_kubeadm.sh
########### worker CPU 2 RAM 2

yum install -y nano mc git curl vim iproute-tc
dnf install -y conntrack-tools libnetfilter_cthelper libnetfilter_cttimeout

cat >> /etc/hosts << EOF
192.168.10.169 node1.k8s.local
192.168.10.169 node1
192.168.10.146 node2.k8s.local
192.168.10.146 node2
192.168.10.88 node3.k8s.local
192.168.10.88 node3
192.168.10.81 node0.k8s.local
192.168.10.81 node0
192.168.10.155 node4.k8s.local
192.168.10.155 node4
192.168.10.89 node5.k8s.local
192.168.10.89 node5
192.168.10.167 lb.k8s.local
192.168.10.167 lb
EOF

##########Disable SELinux###############
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

#####SWAP OFF########
sed -i '/swap/d' /etc/fstab
swapoff -a

### Install containerd
dnf install dnf-utils -y
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y containerd.io
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd
systemctl start containerd
systemctl status containerd
systemctl enable containerd

###############Configuring the kubelet cgroup driver
lsmod | grep br_netfilter
modprobe br_netfilter
lsmod | grep br_netfilter

cat << EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat << EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system
systemctl restart containerd

####### Firewall open ports ##########
systemctl stop firewalld
systemctl disable firewalld

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
dnf install -y yum-plugin-versionlock 
dnf versionlock kubelet kubeadm kubectl
systemctl daemon-reload
systemctl enable --now kubelet
######## Enable and start kubelet
#systemctl enable kubelet.service
#systemctl start kubelet.service
systemctl status kubelet




###########Setup networking with Calico
kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml