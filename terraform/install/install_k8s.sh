set -e

# Actualizar sistema
sudo yum update -y

# Instalar dependencias necesarias
sudo yum install -y curl wget vim git yum-utils device-mapper-persistent-data lvm2

# Configurar repositorio de containerd
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y containerd.io

# Configurar containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl enable containerd
sudo systemctl restart containerd

# Deshabilitar swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Ajustes de red para Kubernetes
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

# Añadir repositorio de Kubernetes
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Instalar kubeadm, kubelet y kubectl
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet

# Inicializar el clúster Kubernetes
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configurar kubectl para ec2-user
mkdir -p /home/ec2-user/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config

# Permitir que el nodo master ejecute pods
sudo -u ec2-user kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# Instalar Flannel como red CNI
sudo -u ec2-user kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Instalar NGINX Ingress Controller
sudo -u ec2-user kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/baremetal/deploy.yaml

echo "Esperando a que el Ingress Controller esté listo..."
sleep 30