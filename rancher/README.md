# Rancher - Kubernetes Management Platform

Instalação automatizada do Rancher em VM usando Docker ou Terraform.

> **Nota**: Para configuração inicial do ambiente, veja o [README principal](../README.md)

## 🚀 Instalação

### 🐳 **Docker**

```bash
cd docker/
./install.sh
```

### 🏗️ **Terraform**

```bash
cd terraform/
./install.sh
```

```bash
# Personalização
cp terraform.tfvars.example terraform.tfvars

# Gerenciamento
terraform plan
terraform apply
terraform destroy

# Comandos docker
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose ps'
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose logs -f'
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose restart'
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose down'

# Reset completo
terraform destroy -auto-approve
terraform apply -auto-approve
```

## 🔑 Acesso Padrão

- **URL**: http://$VM_HOST
- **Usuário**: admin
- **Senha**: $BOOTSTRAP_PASSWORD (padrão: admin123)

## ⚙️ Variáveis Específicas do Rancher

- `RANCHER_VERSION`: Versão do Rancher (padrão: latest)
- `RANCHER_HOSTNAME`: Hostname do Rancher (padrão: rancher.home)
- `BOOTSTRAP_PASSWORD`: Senha inicial do admin (padrão: admin123)

## 📋 O que Cada Método Instala

### 🐳 **Docker**: Rancher Básico

- Rancher Server + Console Web
- Configuração mínima para testes

### 🏗️ **Terraform**: Rancher + Infraestrutura

- Deploy reproduzível e versionado
- Configuração como código

## 📁 Estrutura Simplificada

```
rancher/
├── docker/     # Instalação via Docker Compose
└── terraform/  # Infraestrutura como código
```

## 🔧 Comandos Específicos do Rancher

### Status e Logs

```bash
# Status do Rancher
ssh $SSH_USER@$VM_HOST 'docker logs rancher'

# Verificar saúde
curl http://$VM_HOST/ping
```

### Gerenciamento

```bash
# Reiniciar Rancher
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose restart'

# Atualizar versão
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose pull && docker-compose up -d'
```

## 🆘 Troubleshooting

### Rancher não inicia

```bash
# Verificar logs específicos
ssh $SSH_USER@$VM_HOST 'docker logs rancher'

# Verificar recursos
ssh $SSH_USER@$VM_HOST 'df -h && free -h'
```

### Problemas de acesso

```bash
# Verificar portas do Rancher
ssh $SSH_USER@$VM_HOST 'netstat -tlnp | grep -E ":(80|443)"'

# Testar endpoint
curl -I http://$VM_HOST
```

### Reset do Rancher

```bash
# Parar e limpar dados
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose down -v'
ssh $SSH_USER@$VM_HOST 'sudo rm -rf /opt/rancher/data/*'

# Reinstalar
./install.sh
```
