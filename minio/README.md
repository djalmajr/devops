# 🗄️ MinIO - Object Storage S3-Compatible

Instalação automatizada do MinIO em VM usando Docker ou Terraform.

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
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose ps'
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose logs -f'
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose restart'
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose down'

# Reset completo
terraform destroy -auto-approve
terraform apply -auto-approve
```

## 🔑 Acesso Padrão

- **Console Web**: http://$VM_HOST:9001
- **API**: http://$VM_HOST:9000
- **Usuário**: $MINIO_ROOT_USER (padrão: admin)
- **Senha**: $MINIO_ROOT_PASSWORD (padrão: MySecP4ss!)

## ⚙️ Variáveis Específicas do MinIO

- `MINIO_VERSION`: Versão do MinIO (padrão: latest)
- `MINIO_ROOT_USER`: Usuário admin (padrão: admin)
- `MINIO_ROOT_PASSWORD`: Senha admin (padrão: MySecP4ss!)
- `MINIO_CONSOLE_PORT`: Porta do console (padrão: 9001)
- `MINIO_API_PORT`: Porta da API (padrão: 9000)

## 📋 O que Cada Método Instala

### 🐳 **Docker**: MinIO Básico

- MinIO Server + Console Web
- Configuração mínima para testes

### 🏗️ **Terraform**: MinIO + Infraestrutura

- Deploy reproduzível e versionado
- Configuração como código

## 📁 Estrutura

```
minio/
├── docker/     # Docker Compose
└── terraform/  # Infraestrutura como código
```

## 🆘 Troubleshooting

### MinIO não inicia

```bash
# Verificar logs específicos
ssh $SSH_USER@$VM_HOST 'docker logs minio'

# Verificar recursos
ssh $SSH_USER@$VM_HOST 'df -h && free -h'
```

### Problemas de acesso

```bash
# Verificar portas do MinIO
ssh $SSH_USER@$VM_HOST 'netstat -tlnp | grep -E ":(9000|9001)"'

# Testar API
curl -I http://$VM_HOST:9000/minio/health/live

# Testar console
curl -I http://$VM_HOST:9001
```

### Reset do MinIO

```bash
# Parar e limpar dados
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose down -v'
ssh $SSH_USER@$VM_HOST 'sudo rm -rf /opt/minio/data/*'

# Reinstalar
./install.sh
```
