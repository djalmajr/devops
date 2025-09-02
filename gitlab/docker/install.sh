#!/bin/bash

# Script de instalação do GitLab via Docker Compose
# Configuração via variáveis de ambiente

set -e

# Variáveis de ambiente (com valores padrão)
VM_HOST="${VM_HOST:-gitlab.home}"
SSH_USER="${SSH_USER:-ubuntu}"
SSH_PASS="${SSH_PASS:-}"
GITLAB_VERSION="${GITLAB_VERSION:-latest}"
GITLAB_HOSTNAME="${GITLAB_HOSTNAME:-gitlab.home}"
GITLAB_ROOT_PASSWORD="${GITLAB_ROOT_PASSWORD:-MySecP4ss!}"
GITLAB_HTTP_PORT="${GITLAB_HTTP_PORT:-80}"
GITLAB_HTTPS_PORT="${GITLAB_HTTPS_PORT:-443}"
GITLAB_SSH_PORT="${GITLAB_SSH_PORT:-2222}"
GITLAB_TIMEZONE="${GITLAB_TIMEZONE:-America/Sao_Paulo}"

echo "🚀 Iniciando instalação do GitLab via Docker Compose..."

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker instalado com sucesso!"
else
    echo "✅ Docker já está instalado"
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose não encontrado. Instalando..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose instalado com sucesso!"
else
    echo "✅ Docker Compose já está instalado"
fi

# Criar arquivo .env
echo "📝 Criando arquivo de configuração .env..."
cat > .env << EOF
GITLAB_VERSION=${GITLAB_VERSION}
GITLAB_HOSTNAME=${GITLAB_HOSTNAME}
GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD}
GITLAB_HTTP_PORT=${GITLAB_HTTP_PORT}
GITLAB_HTTPS_PORT=${GITLAB_HTTPS_PORT}
GITLAB_SSH_PORT=${GITLAB_SSH_PORT}
GITLAB_TIMEZONE=${GITLAB_TIMEZONE}
EOF

# Verificar recursos do sistema
echo "🔍 Verificando recursos do sistema..."
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
TOTAL_DISK=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')

echo "   Memória total: ${TOTAL_MEM}MB"
echo "   Espaço em disco disponível: ${TOTAL_DISK}GB"

if [ "$TOTAL_MEM" -lt 4096 ]; then
    echo "⚠️  AVISO: GitLab recomenda pelo menos 4GB de RAM. Atual: ${TOTAL_MEM}MB"
    echo "   O GitLab pode ter performance reduzida."
fi

if [ "$TOTAL_DISK" -lt 10 ]; then
    echo "⚠️  AVISO: GitLab recomenda pelo menos 10GB de espaço em disco. Atual: ${TOTAL_DISK}GB"
    echo "   O GitLab pode ter problemas de armazenamento."
fi

# Configurar limites do sistema
echo "⚙️  Configurando limites do sistema..."
sudo sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Iniciar GitLab
echo "🔄 Iniciando GitLab..."
docker-compose up -d

# Aguardar GitLab inicializar
echo "⏳ Aguardando GitLab inicializar (pode levar 5-10 minutos)..."
echo "   Isso é normal para a primeira inicialização do GitLab."

# Função para verificar se GitLab está pronto
check_gitlab_ready() {
    local max_attempts=60
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost:${GITLAB_HTTP_PORT}/users/sign_in >/dev/null 2>&1; then
            return 0
        fi

        echo "   Tentativa $attempt/$max_attempts: GitLab ainda não está pronto..."
        sleep 10
        attempt=$((attempt + 1))
    done

    return 1
}

if check_gitlab_ready; then
    echo "✅ GitLab instalado com sucesso!"
    echo ""
    echo "📋 Informações de acesso:"
    echo "   URL: http://${GITLAB_HOSTNAME}:${GITLAB_HTTP_PORT}"
    echo "   Usuário: root"
    echo "   Senha inicial: ${GITLAB_ROOT_PASSWORD}"
    echo ""
    echo "🔧 Configurações:"
    echo "   SSH Port: ${GITLAB_SSH_PORT}"
    echo "   Timezone: ${GITLAB_TIMEZONE}"
    echo "   Versão: ${GITLAB_VERSION}"
    echo ""
    echo "⚠️  IMPORTANTE:"
    echo "   - Configure backup regular dos dados"
    echo "   - Monitore o uso de recursos"
    echo ""
    echo "📊 Comandos úteis:"
    echo "   Ver logs: docker-compose logs -f gitlab"
    echo "   Parar: docker-compose down"
    echo "   Reiniciar: docker-compose restart"
    echo "   Status: docker-compose ps"
    echo ""
    echo "🔍 Para verificar a saúde do GitLab:"
    echo "   docker exec gitlab gitlab-rake gitlab:check SANITIZE=true"
else
    echo "❌ Erro: GitLab não ficou pronto dentro do tempo esperado."
    echo "   Verifique os logs: docker-compose logs gitlab"
    echo "   O GitLab pode estar ainda inicializando. Aguarde mais alguns minutos."
    exit 1
fi
