#!/usr/bin/env bash
set -euxo pipefail

PKG="dnf"
command -v dnf >/dev/null 2>&1 || PKG="yum"

sudo $PKG -y update || true

sudo $PKG -y install wget vim git ebtables ethtool socat conntrack iproute-tc which
sudo $PKG -y swap curl-minimal curl || sudo $PKG -y install --allowerasing curl || true

sudo $PKG -y install containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab || true

cat <<'EOF' | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

sudo $PKG -y install kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU

sudo -u ec2-user mkdir -p /home/ec2-user/.kube
sudo cp /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config

sudo -u ec2-user kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

sudo -u ec2-user kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

sudo -u ec2-user bash -lc '
  timeout 600 bash -c "
    until kubectl get nodes; do echo \"Esperando API...\"; sleep 5; done
    until kubectl get nodes | grep -E \" Ready \"; do echo \"Esperando nodo Ready...\"; sleep 10; done
  "
' || true

# Ingress NGINX (crea el ns ingress-nginx y el controller)
sudo -u ec2-user kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/baremetal/deploy.yaml
sudo -u ec2-user kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=5m

# Aplica tus manifiestos si existen
if [ -f /home/ec2-user/ingress.yaml ]; then
  sudo -u ec2-user kubectl apply -f /home/ec2-user/ingress.yaml || true
fi
if [ -f /home/ec2-user/ingress-service.yaml ]; then
  sudo -u ec2-user kubectl apply -f /home/ec2-user/ingress-service.yaml || true
fi

echo "Instalación Kubernetes finalizada."
