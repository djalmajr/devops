# 🏗️ MinIO Terraform - Produção Simples

Instalação do MinIO usando Terraform para infraestrutura como código.

> **Configuração**: Veja [README principal](../../README.md) para setup inicial

## 🚀 Instalação

```bash
./install.sh
```

## ⚙️ Personalização

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

## 🔑 Acesso

- **Console**: http://$VM_HOST:9001
- **API**: http://$VM_HOST:9000
- **Login**: admin / password123

## 🔧 Comandos Terraform

```bash
# Gerenciamento
terraform plan
terraform apply
terraform destroy

# Status na VM
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose ps'
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose logs -f'

# Reset completo
terraform destroy -auto-approve
terraform apply -auto-approve
```
