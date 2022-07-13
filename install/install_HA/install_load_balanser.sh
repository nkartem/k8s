#!/bin/bash
###OS Rocky linux 8.6 node-worker
### sed -i -e 's/\r$//' install_worker_kubeadm.sh
########### worker CPU 2 RAM 2

yum install -y nano mc git curl vim iproute-tc keepalived haproxy


cat >> /etc/hosts << EOF
192.168.10.169 node1.k8s.local
192.168.10.169 node1
192.168.10.146 node2.k8s.local
192.168.10.146 node2
192.168.10.88 node3.k8s.local
192.168.10.88 node3
192.168.10.81 node0.k8s.local
192.168.10.81 node0
192.168.10.77 lb.k8s.local
192.168.10.77 lb
EOF


cat >> /etc/keepalived/check_apiserver.sh <<EOF
#!/bin/sh

errorExit() {
  echo "*** $@" 1>&2
  exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q 172.16.16.100; then
  curl --silent --max-time 2 --insecure https://172.16.16.100:6443/ -o /dev/null || errorExit "Error GET https://172.16.16.100:6443/"
fi
EOF

chmod +x /etc/keepalived/check_apiserver.sh


cat >> /etc/keepalived/keepalived.conf <<EOF
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  timeout 10
  fall 5
  rise 2
  weight -2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth1
    virtual_router_id 1
    priority 100
    advert_int 5
    authentication {
        auth_type PASS
        auth_pass mysecret
    }
    virtual_ipaddress {
        172.16.16.100 # IP address host
    }
    track_script {
        check_apiserver
    }
}
EOF

systemctl enable --now keepalived


cat >> /etc/haproxy/haproxy.cfg <<EOF

frontend kubernetes-frontend
  bind *:6443
  mode tcp
  option tcplog
  default_backend kubernetes-backend

backend kubernetes-backend
  option httpchk GET /healthz
  http-check expect status 200
  mode tcp
  option ssl-hello-chk
  balance roundrobin
    server node1 192.168.10.169:6443 check fall 3 rise 2
    server node2 192.168.10.146:6443 check fall 3 rise 2
    server node3 192.168.10.88:6443 check fall 3 rise 2

EOF

systemctl enable haproxy && systemctl restart haproxy