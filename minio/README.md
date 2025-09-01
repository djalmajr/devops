# 🗄️ MinIO - Object Storage S3-Compatible

Instalação automatizada do MinIO em VM usando Docker ou Terraform.

> **Nota**: Para configuração inicial do ambiente, veja o [README principal](../README.md)

## 🚀 Instalação

```bash
# Escolher método de instalação:
cd docker && ./install.sh      # Desenvolvimento/Testes
cd terraform && ./install.sh   # Produção
```

## 🔑 Acesso Padrão

- **Console Web**: http://$VM_HOST:9001
- **API**: http://$VM_HOST:9000
- **Usuário**: $MINIO_ROOT_USER (padrão: admin)
- **Senha**: $MINIO_ROOT_PASSWORD (padrão: password123)

## ⚙️ Variáveis Específicas do MinIO

- `MINIO_VERSION`: Versão do MinIO (padrão: latest)
- `MINIO_ROOT_USER`: Usuário admin (padrão: admin)
- `MINIO_ROOT_PASSWORD`: Senha admin (padrão: password123)
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
docker logs minio
sudo netstat -tlnp | grep :9000
```

### Problemas de acesso

```bash
# Testar API
curl -I http://$VM_HOST:9000/minio/health/live

# Verificar console
curl -I http://$VM_HOST:9001
```

### Reset do MinIO

```bash
docker-compose down -v
./install.sh
```
