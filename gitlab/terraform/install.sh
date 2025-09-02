#!/bin/bash

# GitLab Terraform Installation Script
# Instala GitLab usando Terraform de forma automatizada

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Carregar variáveis do .env se existir
if [ -f "../../.env" ]; then
    log "Carregando variáveis do arquivo .env..."
    source ../../.env
fi

# Definir variáveis padrão
export VM_HOST=${VM_HOST:-"gitlab.home"}
export SSH_USER=${SSH_USER:-"djalmajr"}
export GITLAB_VERSION=${GITLAB_VERSION:-"latest"}
export GITLAB_HOSTNAME=${GITLAB_HOSTNAME:-"gitlab.home"}
export GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD:-"MySecP4ss!"}
export GITLAB_HTTP_PORT=${GITLAB_HTTP_PORT:-"80"}
export GITLAB_HTTPS_PORT=${GITLAB_HTTPS_PORT:-"443"}
export GITLAB_SSH_PORT=${GITLAB_SSH_PORT:-"2222"}
export GITLAB_TIMEZONE=${GITLAB_TIMEZONE:-"America/Sao_Paulo"}

log "=== GitLab Terraform Installation ==="
info "VM IP: $VM_HOST"
info "SSH User: $SSH_USER"
info "GitLab Version: $GITLAB_VERSION"
info "GitLab Hostname: $GITLAB_HOSTNAME"
info "HTTP Port: $GITLAB_HTTP_PORT"
info "HTTPS Port: $GITLAB_HTTPS_PORT"

# Verificar se Terraform está instalado
if ! command -v terraform &> /dev/null; then
    error "Terraform não está instalado. Instale o Terraform primeiro."
fi

log "Terraform version: $(terraform version -json | jq -r '.terraform_version')"

# Função para testar conectividade SSH
test_ssh_connection() {
    log "Testando conectividade SSH com $SSH_USER@$VM_HOST..."

    if [ -n "$SSH_PASS" ]; then
        # Usar sshpass se senha foi fornecida
        if ! command -v sshpass &> /dev/null; then
            warn "sshpass não encontrado. Tentando instalar..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install hudochenkov/sshpass/sshpass 2>/dev/null || error "Falha ao instalar sshpass. Instale manualmente: brew install hudochenkov/sshpass/sshpass"
            else
                sudo apt-get update && sudo apt-get install -y sshpass 2>/dev/null || error "Falha ao instalar sshpass. Instale manualmente."
            fi
        fi

        if sshpass -p "$SSH_PASS" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$VM_HOST" "echo 'SSH OK'" &>/dev/null; then
            log "✅ Conectividade SSH OK"
        else
            error "❌ Falha na conectividade SSH com senha"
        fi
    else
        # Usar chave SSH
        if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$VM_HOST" "echo 'SSH OK'" &>/dev/null; then
            log "✅ Conectividade SSH OK"
        else
            error "❌ Falha na conectividade SSH com chave. Configure as chaves SSH primeiro."
        fi
    fi
}

# Testar conectividade
test_ssh_connection

# Gerar terraform.tfvars se não existir
if [ ! -f "terraform.tfvars" ]; then
    log "Gerando terraform.tfvars..."
    cat > terraform.tfvars << EOF
# Gerado automaticamente pelo install.sh
# Baseado nas variáveis de ambiente

vm_host = "$VM_HOST"
ssh_user = "$SSH_USER"
ssh_private_key_path = "~/.ssh/id_rsa"
gitlab_version = "$GITLAB_VERSION"
gitlab_hostname = "$GITLAB_HOSTNAME"
gitlab_root_password = "$GITLAB_ROOT_PASSWORD"
gitlab_http_port = "$GITLAB_HTTP_PORT"
gitlab_https_port = "$GITLAB_HTTPS_PORT"
gitlab_ssh_port = "$GITLAB_SSH_PORT"
gitlab_timezone = "$GITLAB_TIMEZONE"
EOF
    log "✅ terraform.tfvars criado"
else
    log "✅ terraform.tfvars já existe"
fi

# Inicializar Terraform
log "Inicializando Terraform..."
terraform init

# Validar configuração
log "Validando configuração Terraform..."
terraform validate

# Mostrar plano
log "Gerando plano de execução..."
terraform plan

# Confirmar execução
echo
read -p "Deseja continuar com a instalação? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    warn "Instalação cancelada pelo usuário."
    exit 0
fi

# Aplicar configuração
log "Aplicando configuração Terraform..."
terraform apply -auto-approve

# Mostrar outputs
echo
log "🎉 GitLab instalado com sucesso!"
echo
info "📊 Informações de Acesso:"
terraform output -json | jq -r '
  "   URL HTTP: " + .gitlab_url.value,
  "   URL HTTPS: " + .gitlab_https_url.value,
  "   SSH Git: " + .gitlab_ssh_url.value,
  "   Usuário: root",
  "   Senha: " + .gitlab_credentials.value.password
'

echo
info "🔧 Comandos Úteis:"
terraform output -json | jq -r '.useful_commands.value | to_entries[] | "   " + .key + ": " + .value'

echo
info "💡 Comandos Terraform:"
info "   Ver outputs: terraform output"
info "   Ver estado: terraform show"
info "   Destruir: terraform destroy"
info "   Recriar: terraform apply -replace=null_resource.start_gitlab"

echo
log "✅ Instalação concluída!"
