
# 🛠️ Terraform EKS Cluster con Instancias Spot en AWS

Este repositorio contiene el código necesario para desplegar un clúster de Kubernetes (EKS) en AWS utilizando Terraform y nodos EC2 Spot para reducir costos.

---

## 📦 Requisitos previos

Antes de comenzar, asegúrate de tener lo siguiente instalado en tu máquina local:

- [Terraform](https://www.terraform.io/downloads.html)
- [AWS CLI](https://aws.amazon.com/cli/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Una cuenta de AWS y credenciales configuradas (`aws configure`)

---

## 📁 Estructura de archivos

- `main.tf`: código principal de infraestructura.
- `README.md`: este archivo con las instrucciones.

---

## 🚀 Pasos para desplegar

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu_usuario/eks-cluster-spot.git
cd eks-cluster-spot
```

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Validar la configuración

```bash
terraform validate
```

### 4. Ver un plan de ejecución

```bash
terraform plan
```

### 5. Aplicar los cambios

```bash
terraform apply
```

Confirma con `yes` cuando Terraform te lo solicite.

### 6. Configurar `kubectl`

Una vez creado el clúster, configura tu cliente local para acceder al clúster:

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-spot-cluster
```

Ahora puedes interactuar con el clúster usando `kubectl`.

---

## 📌 Notas importantes

- Este clúster usa **instancias Spot**, lo cual reduce costos, pero los nodos pueden ser interrumpidos por AWS en cualquier momento.
- El clúster tiene un **costo fijo de $0.10/hora** por el control plane (EKS).
- El módulo de Terraform maneja automáticamente los recursos de red, IAM, y la configuración básica de EKS.

---

## 🧹 Para destruir la infraestructura

Cuando ya no lo necesites, puedes eliminar todo con:

```bash
terraform destroy
```

---

## ✅ Recursos usados

- [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [Kubernetes CLI - kubectl](https://kubernetes.io/docs/reference/kubectl/)

---
