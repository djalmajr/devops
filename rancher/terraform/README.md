# 🐄 Rancher Terraform - Produção Simples

Instalação do Rancher usando Terraform para infraestrutura como código.

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

- **Interface Web**: http://$VM_HOST
- **Login**: admin / admin123

## 🔧 Comandos Terraform

```bash
# Gerenciamento
terraform plan
terraform apply
terraform destroy

# Status na VM
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose ps'
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose logs -f'

# Reset completo
terraform destroy -auto-approve
terraform apply -auto-approve
```
