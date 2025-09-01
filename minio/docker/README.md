# 🐳 MinIO Docker - Desenvolvimento

Instalação rápida do MinIO usando Docker Compose.

> **Configuração**: Veja [README principal](../../README.md) para setup inicial

## 🚀 Instalação

```bash
./install.sh
```

## 🔑 Acesso

- **Console**: http://$VM_HOST:9001
- **API**: http://$VM_HOST:9000
- **Login**: admin / password123

## 🔧 Comandos Úteis

```bash
# Status e logs
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose ps'
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose logs -f'

# Gerenciamento
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose restart'
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose down'

# Reset completo
ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose down -v'
./install.sh
```
