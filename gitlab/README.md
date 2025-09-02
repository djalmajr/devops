# GitLab DevOps Setup

Este diretório contém a configuração para instalação e gerenciamento do GitLab usando Docker e Terraform, seguindo o mesmo padrão dos outros serviços (Rancher e MinIO).

## 📁 Estrutura

```
gitlab/
├── docker/                       # Instalação local via Docker Compose
│   ├── docker-compose.yml        # Configuração do GitLab
│   └── install.sh                # Script de instalação local
├── terraform/                    # Instalação remota via Terraform
│   ├── main.tf                   # Configuração principal do Terraform
│   ├── docker-compose.yml.tpl    # Template do Docker Compose
│   ├── terraform.tfvars.example  # Exemplo de variáveis
│   └── install.sh                # Script de instalação via Terraform
└── README.md                     # Este arquivo
```

## 🚀 Instalação

### Opção 1: Instalação Local (Docker)

Para instalar o GitLab localmente usando Docker Compose:

```bash
cd docker
./install.sh
```

**Pré-requisitos:**

- Docker e Docker Compose instalados
- Pelo menos 4GB de RAM disponível
- Pelo menos 10GB de espaço em disco

### Opção 2: Instalação Remota (Terraform)

Para instalar o GitLab em uma VM remota usando Terraform:

```bash
cd terraform
./install.sh
```

**Pré-requisitos:**

- Terraform instalado
- Acesso SSH à VM de destino
- Chave SSH configurada
- VM com pelo menos 4GB de RAM e 10GB de disco

## ⚙️ Configuração

### Variáveis de Ambiente (Docker)

Você pode personalizar a instalação definindo as seguintes variáveis de ambiente:

```bash
export GITLAB_VERSION="latest"              # Versão do GitLab
export GITLAB_HOSTNAME="gitlab.home"        # Hostname do GitLab
export GITLAB_ROOT_PASSWORD="MySecP4ss!"    # Senha do usuário root
export GITLAB_HTTP_PORT="80"                # Porta HTTP
export GITLAB_HTTPS_PORT="443"              # Porta HTTPS
export GITLAB_SSH_PORT="2222"               # Porta SSH (alterado de 22 para evitar conflito)
export GITLAB_TIMEZONE="America/Sao_Paulo"  # Timezone
```

### Variáveis do Terraform

Edite o arquivo `terraform/terraform.tfvars` com suas configurações:

```hcl
# Configurações da VM
vm_host = "gitlab.home"
ssh_user = "ubuntu"
ssh_private_key_path = "~/.ssh/id_rsa"

# Configurações do GitLab
gitlab_version = "latest"
gitlab_hostname = "gitlab.home"
gitlab_root_password = "MySecP4ss!"
gitlab_http_port = "80"
gitlab_https_port = "443"
gitlab_ssh_port = "2222"
gitlab_timezone = "America/Sao_Paulo"
```

## 🔧 Configurações do GitLab

A configuração inclui otimizações para ambientes de desenvolvimento/teste:

- **PostgreSQL**: 256MB shared_buffers, 200 max_connections
- **Redis**: 256MB maxmemory com política LRU
- **Sidekiq**: 25 workers concorrentes
- **Unicorn**: 2 workers com limite de 1GB cada
- **Nginx**: 2 workers com 1024 conexões
- **Monitoramento**: Desabilitado para economizar recursos

## 📊 Acesso e Credenciais

Após a instalação, você terá acesso ao GitLab através de:

- **URL**: `http://gitlab.home` (ou o hostname configurado)
- **Usuário**: `root`
- **Senha**: A senha configurada (padrão: `MySecP4ss!`)
- **SSH Git**: `ssh://git@gitlab.home:2222` (porta 2222)

## 🛠️ Comandos Úteis

### Docker (Instalação Local)

```bash
# Ver logs
docker-compose logs -f gitlab

# Parar GitLab
docker-compose down

# Reiniciar GitLab
docker-compose restart

# Verificar status
docker-compose ps

# Health check
docker exec gitlab gitlab-rake gitlab:check SANITIZE=true
```

### Terraform (Instalação Remota)

```bash
# Ver logs
ssh user@host 'cd /opt/gitlab && docker-compose logs -f'

# Parar GitLab
ssh user@host 'cd /opt/gitlab && docker-compose down'

# Reiniciar GitLab
ssh user@host 'cd /opt/gitlab && docker-compose restart'

# Verificar status
ssh user@host 'cd /opt/gitlab && docker-compose ps'

# Health check
ssh user@host 'docker exec gitlab gitlab-rake gitlab:check SANITIZE=true'
```

## 📈 Monitoramento

### Verificação de Saúde

```bash
# Verificar saúde geral do GitLab
docker exec gitlab gitlab-rake gitlab:check SANITIZE=true

# Verificar uso de recursos
docker stats gitlab

# Verificar logs de erro
docker exec gitlab tail -f /var/log/gitlab/gitlab-rails/production.log
```

### Métricas Importantes

- **CPU**: Deve estar abaixo de 80% em uso normal
- **RAM**: GitLab usa aproximadamente 2-4GB
- **Disco**: Monitore o crescimento dos volumes
- **Rede**: Verifique latência e throughput

## 🔄 Backup e Restore

### Backup

```bash
# Backup completo
docker exec gitlab gitlab-backup create

# Backup apenas configuração
docker exec gitlab gitlab-ctl backup-etc
```

### Restore

```bash
# Restore de backup
docker exec gitlab gitlab-backup restore BACKUP=timestamp
```

## 🚨 Troubleshooting

### Problemas Comuns

1. **GitLab não inicia**

   - Verifique se há recursos suficientes (RAM/CPU)
   - Verifique logs: `docker-compose logs gitlab`
   - Verifique se as portas estão disponíveis

2. **Performance lenta**

   - Aumente recursos da VM/container
   - Verifique configurações do PostgreSQL/Redis
   - Monitore uso de disco

3. **Erro de conectividade**
   - Verifique configuração de rede
   - Verifique firewall/iptables
   - Teste conectividade SSH

### Logs Importantes

```bash
# Logs principais
docker exec gitlab tail -f /var/log/gitlab/gitlab-rails/production.log

# Logs do PostgreSQL
docker exec gitlab tail -f /var/log/gitlab/postgresql/current

# Logs do Redis
docker exec gitlab tail -f /var/log/gitlab/redis/current

# Logs do Nginx
docker exec gitlab tail -f /var/log/gitlab/nginx/gitlab_access.log
```

## 📚 Recursos Adicionais

- [Documentação Oficial do GitLab](https://docs.gitlab.com/)
- [GitLab Docker Images](https://hub.docker.com/r/gitlab/gitlab-ce)
- [GitLab Omnibus Configuration](https://docs.gitlab.com/omnibus/settings/)
- [GitLab Backup and Restore](https://docs.gitlab.com/ee/raketasks/backup_restore.html)

## 🤝 Contribuição

Para contribuir com melhorias nesta configuração:

1. Faça um fork do repositório
2. Crie uma branch para sua feature
3. Faça commit das mudanças
4. Abra um Pull Request

## 📄 Licença

Este projeto segue a mesma licença do projeto principal.
