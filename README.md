# DevOps - Automação de Infraestrutura

Coleção de scripts e configurações para automação de infraestrutura usando Docker e Terraform.

## 📁 Projetos Disponíveis

### 🗄️ [MinIO](./minio/)

**Object Storage S3-Compatible**

- **Docker**: Instalação rápida para desenvolvimento
- **Terraform**: Produção com infraestrutura como código

### 🐄 [Rancher](./rancher/)

**Kubernetes Management Platform**

- **Docker**: Setup rápido para testes
- **Terraform**: Deploy automatizado

### 🌐 [DNS Server](./dns-server/)

**Servidor DNS Local com BIND9**

- Resolução de domínios locais personalizados
- Encaminhamento para DNS públicos
- Configuração via Docker

### 🔧 [Scripts](./scripts/)

**Utilitários de Automação**

- `setup-ssh-keys.sh`: Configuração de chaves SSH
- `test-connection.sh`: Teste de conectividade

## 🚀 Início Rápido

### 1. Configurar Ambiente

```bash
# Configurar chaves SSH
./scripts/setup-ssh-keys.sh

# Testar conectividade
./scripts/test-connection.sh
```

### 2. Escolher Projeto

```bash
# MinIO - Object Storage
cd minio/

# Rancher - Kubernetes
cd rancher/
```

### 3. Escolher Método de Deploy

```bash
# Desenvolvimento/Testes
cd docker/
./install.sh

# Produção
cd terraform/
./install.sh
```

## 📋 Pré-requisitos Gerais

### Máquina Local

- **Sistema**: macOS, Linux ou WSL2
- **SSH**: Acesso configurado à VM de destino
- **Git**: Para versionamento

### VM de Destino

- **Sistema**: Ubuntu 20.04+ ou CentOS 8+
- **RAM**: Mínimo 2GB (recomendado 4GB+)
- **Disco**: Mínimo 20GB livres
- **Rede**: Portas 22 (SSH) abertas

### Ferramentas por Método

| Método        | Ferramentas Necessárias  |
| ------------- | ------------------------ |
| **Docker**    | Docker, Docker Compose   |
| **Terraform** | Terraform >= 1.0, Docker |

## 🔧 Comandos Úteis

### Verificar Status Geral

```bash
# Testar conectividade com todas as VMs
./scripts/test-connection.sh
```

### Gerenciamento de Projetos

```bash
# Ver logs de qualquer serviço
ssh $SSH_USER@$VM_HOST 'docker logs <container_name>'

# Verificar recursos da VM
ssh $SSH_USER@$VM_HOST 'htop'

# Verificar espaço em disco
ssh $SSH_USER@$VM_HOST 'df -h'
```

## 🔍 Troubleshooting Geral

### Problemas de Conectividade

```bash
# Testar SSH
ssh -v $SSH_USER@$VM_HOST

# Verificar portas abertas
nmap -p 22,80,443,9000,9001 $VM_HOST

# Testar conectividade básica
ping $VM_HOST
```

### Problemas de Docker

```bash
# Verificar status do Docker
ssh $SSH_USER@$VM_HOST 'sudo systemctl status docker'

# Reiniciar Docker
ssh $SSH_USER@$VM_HOST 'sudo systemctl restart docker'

# Limpar recursos não utilizados
ssh $SSH_USER@$VM_HOST 'docker system prune -f'
```

### Problemas de Firewall

```bash
# Verificar regras do firewall
ssh $SSH_USER@$VM_HOST 'sudo ufw status'

# Abrir porta específica
ssh $SSH_USER@$VM_HOST 'sudo ufw allow <porta>'
```

## 📚 Estrutura do Projeto

```
devops/
├── README.md                 # Este arquivo
├── dns-server/               # Servidor DNS Local
│   ├── README.md            # Documentação específica
│   ├── config/              # Configurações BIND9
│   └── docker-compose.yml   # Deploy via Docker
├── scripts/                  # Utilitários gerais
│   ├── setup-ssh-keys.sh    # Configuração SSH
│   └── test-connection.sh    # Teste de conectividade
├── minio/                    # Object Storage
│   ├── README.md            # Documentação completa (Docker + Terraform)
│   ├── docker/              # Deploy via Docker
│   │   ├── docker-compose.yml
│   │   └── install.sh
│   └── terraform/           # Deploy via Terraform
│       ├── main.tf
│       ├── install.sh
│       └── terraform.tfvars.example
└── rancher/                  # Kubernetes Management
    ├── README.md            # Documentação completa (Docker + Terraform)
    ├── docker/              # Deploy via Docker
    │   ├── docker-compose.yml
    │   └── install.sh
    └── terraform/           # Deploy via Terraform
        ├── main.tf
        ├── install.sh
        └── terraform.tfvars.example
```

## 🎯 Casos de Uso

### 🌐 **DNS Local**

```bash
cd dns-server/
docker-compose up -d
```

**Ideal para**: Resolução de domínios locais (\*.home), desenvolvimento com múltiplos serviços

### 🧪 **Desenvolvimento/Testes**

```bash
cd minio/docker/     # ou rancher/docker/
./install.sh
```

**Ideal para**: Desenvolvimento local, testes rápidos, prototipagem

### 🏢 **Produção**

```bash
cd minio/terraform/  # ou rancher/terraform/
./install.sh
```

**Ideal para**: Produção, infraestrutura versionada, deploy/destroy frequente

## 🔗 Links Úteis

- [Docker Documentation](https://docs.docker.com/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [MinIO Documentation](https://docs.min.io/)
- [Rancher Documentation](https://rancher.com/docs/)

---

**💡 Dica**: Comece sempre com a opção Docker para testes, depois migre para Terraform conforme a necessidade de produção.
