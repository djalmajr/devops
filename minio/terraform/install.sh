#!/bin/bash

# MinIO Terraform Installation Script
# Instala MinIO usando Terraform de forma automatizada

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
export VM_HOST=${VM_HOST:-"minio.home"}
export SSH_USER=${SSH_USER:-"ubuntu"}
export SSH_PASS=${SSH_PASS:-""}
export MINIO_VERSION=${MINIO_VERSION:-"latest"}
export MINIO_HOSTNAME=${MINIO_HOSTNAME:-"minio.local"}
export MINIO_ROOT_USER=${MINIO_ROOT_USER:-"admin"}
export MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:-"password123"}
export MINIO_API_PORT=${MINIO_API_PORT:-"9000"}
export MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT:-"9001"}
export MINIO_CLIENT_VERSION=${MINIO_CLIENT_VERSION:-"latest"}

log "=== MinIO Terraform Installation ==="
info "VM IP: $VM_HOST"
info "SSH User: $SSH_USER"
info "MinIO Version: $MINIO_VERSION"
info "MinIO Hostname: $MINIO_HOSTNAME"
info "Console Port: $MINIO_CONSOLE_PORT"
info "API Port: $MINIO_API_PORT"

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
minio_version = "$MINIO_VERSION"
minio_hostname = "$MINIO_HOSTNAME"
minio_root_user = "$MINIO_ROOT_USER"
minio_root_password = "$MINIO_ROOT_PASSWORD"
minio_api_port = "$MINIO_API_PORT"
minio_console_port = "$MINIO_CONSOLE_PORT"
minio_client_version = "$MINIO_CLIENT_VERSION"
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
log "🎉 MinIO instalado com sucesso!"
echo
info "📊 Informações de Acesso:"
terraform output -json | jq -r '
  "   Console Web: " + .minio_console_url.value,
  "   API: " + .minio_api_url.value,
  "   Usuário: " + .minio_credentials.value.username,
  "   Senha: " + .minio_credentials.value.password
'

echo
info "🔧 Comandos Úteis:"
terraform output -json | jq -r '.useful_commands.value | to_entries[] | "   " + .key + ": " + .value'

echo
info "💡 Comandos Terraform:"
info "   Ver outputs: terraform output"
info "   Ver estado: terraform show"
info "   Destruir: terraform destroy"
info "   Recriar: terraform apply -replace=null_resource.start_minio"

echo
log "✅ Instalação concluída!"
