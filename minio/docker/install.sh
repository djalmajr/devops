#!/bin/bash

# MinIO Docker Compose Installation Script
# Instala MinIO usando Docker Compose de forma automatizada

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
export MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:-"MySecP4ss!"}
export MINIO_API_PORT=${MINIO_API_PORT:-"9000"}
export MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT:-"9001"}
export MINIO_CLIENT_VERSION=${MINIO_CLIENT_VERSION:-"latest"}

log "=== MinIO Docker Compose Installation ==="
info "VM IP: $VM_HOST"
info "SSH User: $SSH_USER"
info "MinIO Version: $MINIO_VERSION"
info "MinIO Hostname: $MINIO_HOSTNAME"
info "Console Port: $MINIO_CONSOLE_PORT"
info "API Port: $MINIO_API_PORT"

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    error "Docker não está instalado. Instale o Docker primeiro."
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
fi

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

# Função para executar comando remoto
execute_remote() {
    local cmd="$1"
    if [ -n "$SSH_PASS" ]; then
        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$VM_HOST" "$cmd"
    else
        ssh -o StrictHostKeyChecking=no "$SSH_USER@$VM_HOST" "$cmd"
    fi
}

# Função para copiar arquivo remoto
copy_to_remote() {
    local local_file="$1"
    local remote_path="$2"
    if [ -n "$SSH_PASS" ]; then
        sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no "$local_file" "$SSH_USER@$VM_HOST:$remote_path"
    else
        scp -o StrictHostKeyChecking=no "$local_file" "$SSH_USER@$VM_HOST:$remote_path"
    fi
}

# Testar conectividade
test_ssh_connection

# Instalar Docker na VM se necessário
log "Verificando instalação do Docker na VM..."
if ! execute_remote "command -v docker" &>/dev/null; then
    log "Instalando Docker na VM..."
    execute_remote "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo usermod -aG docker $SSH_USER"
    log "Docker instalado. Reiniciando sessão SSH..."
    sleep 5
else
    log "✅ Docker já está instalado na VM"
fi

# Instalar Docker Compose na VM se necessário
log "Verificando instalação do Docker Compose na VM..."
if ! execute_remote "command -v docker-compose" &>/dev/null && ! execute_remote "docker compose version" &>/dev/null; then
    log "Instalando Docker Compose na VM..."
    execute_remote "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
else
    log "✅ Docker Compose já está instalado na VM"
fi

# Criar diretório para MinIO
log "Criando diretório para MinIO na VM..."
execute_remote "mkdir -p /opt/minio"

# Copiar docker-compose.yml para a VM
log "Copiando docker-compose.yml para a VM..."
copy_to_remote "docker-compose.yml" "/opt/minio/docker-compose.yml"

# Criar arquivo .env na VM
log "Criando arquivo .env na VM..."
cat > /tmp/minio.env << EOF
MINIO_VERSION=$MINIO_VERSION
MINIO_HOSTNAME=$MINIO_HOSTNAME
MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD
MINIO_API_PORT=$MINIO_API_PORT
MINIO_CONSOLE_PORT=$MINIO_CONSOLE_PORT
MINIO_CLIENT_VERSION=$MINIO_CLIENT_VERSION
EOF

copy_to_remote "/tmp/minio.env" "/opt/minio/.env"
rm /tmp/minio.env

# Parar containers existentes
log "Parando containers MinIO existentes..."
execute_remote "cd /opt/minio && docker-compose down" 2>/dev/null || true

# Iniciar MinIO
log "Iniciando MinIO..."
execute_remote "cd /opt/minio && docker-compose up -d"

# Aguardar MinIO estar pronto
log "Aguardando MinIO estar pronto..."
sleep 30

# Verificar se MinIO está rodando
log "Verificando status do MinIO..."
if execute_remote "cd /opt/minio && docker-compose ps | grep -q 'Up'"; then
    log "✅ MinIO está rodando!"
else
    error "❌ MinIO não está rodando. Verifique os logs."
fi

# Mostrar logs do cliente (configuração inicial)
log "Logs da configuração inicial:"
execute_remote "cd /opt/minio && docker-compose logs minio-client" || true

# Informações de acesso
echo
log "🎉 MinIO instalado com sucesso!"
echo
info "📊 Informações de Acesso:"
info "   Console Web: http://$VM_HOST:$MINIO_CONSOLE_PORT"
info "   API: http://$VM_HOST:$MINIO_API_PORT"
info "   Usuário: $MINIO_ROOT_USER"
info "   Senha: $MINIO_ROOT_PASSWORD"
echo
info "🔧 Comandos Úteis:"
info "   Ver logs: ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose logs -f'"
info "   Parar: ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose down'"
info "   Reiniciar: ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose restart'"
info "   Status: ssh $SSH_USER@$VM_HOST 'cd /opt/minio && docker-compose ps'"
echo
log "✅ Instalação concluída!"
