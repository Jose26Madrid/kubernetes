
# ☁️ Kubernetes en AWS EC2 (Spot) con Terraform + kubeadm + Ingress

Este proyecto crea un clúster Kubernetes de un solo nodo en una instancia **EC2 Spot** usando `kubeadm`, todo gestionado por Terraform.

---

## ✅ ¿Qué hace este proyecto?

- Crea automáticamente:
  - VPC y subnets públicas (modular y reutilizable)
  - Security Group con acceso por SSH y puertos Kubernetes NodePort (30000–32767)
  - EC2 Spot con Amazon Linux 2
- Instala en la EC2:
  - Containerd
  - kubeadm + kubectl + kubelet
  - CNI Flannel
  - NGINX Ingress Controller
- Aplica automáticamente:
  - `ingress.yaml`: rutas de aplicaciones
  - `ingress-service.yaml`: Service tipo NodePort en el puerto 30080
- Expone la IP pública de la EC2 al final del despliegue

---

## 💸 ¿Por qué usar Spot Instances?

Las instancias EC2 Spot son hasta **90% más baratas** que las On-Demand.  
Este clúster está pensado para ser **efímero, barato y reproducible**.

---

## 📂 Estructura del proyecto

```
repo-root/
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
├── README.md
```

---

## ⚙️ Requisitos

- Terraform ≥ 1.3
- AWS CLI configurado (`aws configure`)
- Par de claves en AWS llamado `"aws"`
- Clave privada `.pem` en tu PC:
  ```bash
  chmod 400 ~/aws.pem
  ssh-keygen -y -f ~/aws.pem > ~/.ssh/aws.pub
  ```

---

## 🛠 Configura `terraform.tfvars`

```hcl
public_key_path  = "/home/jose/.ssh/aws.pub"
private_key_path = "/home/jose/aws.pem"
```

---

## 🚀 Despliegue (6–9 minutos total)

```bash
cd terraform
terraform init
terraform apply
```

Esto creará toda la infraestructura, configurará Kubernetes e Ingress, y expondrá la IP pública.

---

## ✅ Validación después del despliegue

1. Verifica la IP pública:
   ```bash
   terraform output ec2_public_ip
   ```

2. Accede desde el navegador:
   ```
   http://<EC2_PUBLIC_IP>:30080/app1
   ```

3. (Opcional) Conéctate vía SSH:
   ```bash
   ssh -i ~/aws.pem ec2-user@<EC2_PUBLIC_IP>
   ```

4. Verifica el clúster desde dentro:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   kubectl get ingress
   ```

5. Espera a que el Ingress Controller esté `Running`:
   ```bash
   kubectl -n ingress-nginx get pods
   ```

---

## 🧼 Eliminación completa de la infraestructura

Para destruir **todo lo que se creó en AWS**, ejecuta:

```bash
cd terraform
terraform destroy
```

Esto eliminará:
- EC2 Spot Instance
- VPC y subnets
- Security Group
- Clave SSH (si fue creada desde Terraform)

---

MIT License  
(c) 2025 Jose Magariño
