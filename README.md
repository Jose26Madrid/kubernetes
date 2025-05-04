
# 🧩 Kubernetes en AWS EC2 con Terraform + kubeadm + Ingress

Este proyecto despliega un clúster Kubernetes de un solo nodo en EC2 (Amazon Linux 2) **sin EKS**, usando `kubeadm`, `containerd`, red Flannel y NGINX Ingress Controller, con toda la infraestructura creada automáticamente por Terraform, incluyendo VPC y subnets públicas.

---

## ✅ ¿Qué incluye?

- Creación automática de:
  - VPC y subnets públicas
  - Security Group con puertos 22 y 30000-32767 abiertos
  - EC2 con IP pública (Amazon Linux 2)
- Instalación de Kubernetes en EC2 usando `kubeadm`
- Instalación de Flannel como CNI
- Instalación del NGINX Ingress Controller
- Publicación del Ingress Controller usando un Service tipo NodePort (`30080`)
- Aplicación automática de:
  - `ingress.yaml` (reglas de rutas)
  - `ingress-service.yaml` (exposición de Ingress Controller)
- Salida automática de la IP pública para acceso web

---

## 📦 Estructura del proyecto

```
repo-root/
├── README.md
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── install/
│       └── install_k8s.sh
├── k8s/
│   ├── ingress.yaml
│   └── ingress-service.yaml
```

---

## 🔧 Requisitos

- Terraform >= 1.3
- AWS CLI configurado (`aws configure`)
- Clave SSH existente en AWS (par de claves llamado "aws")
- Archivo `.pem` en tu PC (`/home/jose/aws.pem`) y clave pública generada:
  ```bash
  ssh-keygen -y -f ~/aws.pem > ~/.ssh/aws.pub
  ```

---

## ⚙️ Configuración inicial

1. Rellena `terraform.tfvars`:
```hcl
public_key_path  = "/home/jose/.ssh/aws.pub"
private_key_path = "/home/jose/aws.pem"
instance_type    = "t3.large"
```

2. Asegúrate de que la clave tenga los permisos correctos:
```bash
chmod 400 ~/aws.pem
```

---

## 🚀 Despliegue

```bash
cd terraform
terraform init
terraform apply
```

👉 Espera unos 3–5 minutos hasta que el nodo esté listo.

---

## 🌐 Acceder al Ingress

Cuando termine la ejecución, verás algo como:

```bash
Outputs:

ec2_public_ip = "34.201.99.123"
```

Entonces puedes acceder a tus apps:

```
http://34.201.99.123:30080/app1
http://34.201.99.123:30080/app2
```

---

## ✅ Confirmaciones técnicas

- Security Group abre rango NodePort: `30000–32767`
- El Service del Ingress Controller expone `nodePort: 30080`
- El Ingress está configurado para enrutar `/app1`, `/app2`, etc.
- `kubectl` está listo para usarse en `ec2-user` en la EC2 (`~/.kube/config`)

---

## 🧼 Limpieza

Para destruir todo:
```bash
terraform destroy
```

---

## 🧠 Notas adicionales

- Esta arquitectura **no tiene alta disponibilidad**, es ideal para pruebas, aprendizaje o proyectos personales.
- Puedes extenderla fácilmente con MetalLB si deseas LoadBalancers reales sin usar EKS.
- Puedes automatizar despliegues de apps agregando más archivos YAML en la carpeta `k8s/`.

---

MIT License  
(c) 2025 Jose Magariño
