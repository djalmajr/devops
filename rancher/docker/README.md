# 🐄 Rancher Docker - Desenvolvimento

Instalação rápida do Rancher usando Docker Compose.

> **Configuração**: Veja [README principal](../../README.md) para setup inicial

## 🚀 Instalação

```bash
./install.sh
```

## 🔑 Acesso

- **Interface Web**: http://$VM_HOST
- **Login**: admin / admin123

## 🔧 Comandos Úteis

```bash
# Status e logs
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose ps'
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose logs -f'

# Gerenciamento
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose restart'
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose down'

# Reset completo
ssh $SSH_USER@$VM_HOST 'cd /opt/rancher && docker-compose down -v'
./install.sh
```
