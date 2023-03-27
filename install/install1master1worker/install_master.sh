#!/bin/bash
########### OS Rocky linux 8.7 node-master
########### master CPU 2 RAM 2


yum install -y nano mc git curl vim iproute-tc nc
#dnf install -y conntrack-tools libnetfilter_cthelper libnetfilter_cttimeout
cat >> /etc/hosts << EOF
192.168.1.106 k8s-master
192.168.1.110 k8s-worker1
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


# firewall-cmd --permanent --add-port=6443/tcp
# firewall-cmd --permanent --add-port=2379-2380/tcp
# firewall-cmd --permanent --add-port=10250/tcp
# firewall-cmd --permanent --add-port=10251/tcp
# firewall-cmd --permanent --add-port=10252/tcp
# firewall-cmd --reload
# modprobe br_netfilter
# sh -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"
# sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"

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

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
######## Enable and start kubelet
systemctl enable kubelet.service
systemctl start kubelet.service
systemctl status kubelet

curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O
kubectl apply -f calico.yaml


##### Creating a cluster with kubeadm
kubeadm init
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# kubeadm init --apiserver-advertise-address=192.168.88.137 --pod-network-cidr=10.10.0.0/16 
# kubeadm init --config kubeadm-config.yaml

###########Setup networking with Calico
kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl get nodes