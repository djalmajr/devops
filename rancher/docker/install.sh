#!/bin/bash

# Script de instalação do Rancher via Docker Compose
# Configuração via variáveis de ambiente

set -e

# Variáveis de ambiente (com valores padrão)
VM_HOST="${VM_HOST:-rancher.home}"
SSH_USER="${SSH_USER:-ubuntu}"
SSH_PASS="${SSH_PASS:-}"

echo "🚀 Iniciando instalação do Rancher via Docker Compose..."

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
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose não encontrado. Instalando..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose instalado com sucesso!"
else
    echo "✅ Docker Compose já está instalado"
fi

# Criar diretórios necessários
sudo mkdir -p /var/log/rancher/auditlog
sudo chown -R $USER:$USER /var/log/rancher

# Iniciar Rancher
echo "🔄 Iniciando Rancher..."
docker-compose up -d

# Aguardar Rancher inicializar
echo "⏳ Aguardando Rancher inicializar (pode levar alguns minutos)..."
sleep 30

# Verificar status
if docker-compose ps | grep -q "Up"; then
    echo "✅ Rancher instalado com sucesso!"
    echo ""
    echo "📋 Informações de acesso:"
    echo "   URL: https://rancher.home"
    echo "   Usuário: admin"
    echo "   Senha inicial: admin123"
    echo ""
    echo "⚠️  IMPORTANTE: Altere a senha padrão no primeiro acesso!"
    echo ""
    echo "📊 Para verificar logs: docker-compose logs -f rancher"
    echo "🛑 Para parar: docker-compose down"
else
    echo "❌ Erro na instalação. Verifique os logs: docker-compose logs rancher"
    exit 1
fi
