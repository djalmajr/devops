#!/bin/bash

# Script de configuração interativa para variáveis de ambiente
# do projeto de automação do Rancher

set -e

ENV_FILE=".env"
EXAMPLE_FILE=".env.example"

echo "🔧 Configuração de Variáveis de Ambiente - Rancher Automation"
echo "============================================================"
echo ""

# Verificar se arquivo de exemplo existe
if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "❌ Arquivo $EXAMPLE_FILE não encontrado!"
    exit 1
fi

# Função para ler input com valor padrão
read_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    echo -n "$prompt [$default]: "
    read input

    if [ -z "$input" ]; then
        eval "$var_name='$default'"
    else
        eval "$var_name='$input'"
    fi
}

# Função para ler senha (oculta)
read_password() {
    local prompt="$1"
    local var_name="$2"

    echo -n "$prompt (deixe vazio para usar chaves SSH): "
    read -s input
    echo ""

    eval "$var_name='$input'"
}

echo "📋 Configuração da VM:"
read_with_default "Host da VM" "rancher.home" "VM_HOST"
read_with_default "Usuário SSH" "ubuntu" "SSH_USER"
read_password "Senha SSH" "SSH_PASS"

echo ""
echo "🐄 Configuração do Rancher:"
read_with_default "Versão do Rancher" "latest" "RANCHER_VERSION"
read_with_default "Hostname do Rancher" "rancher.home" "RANCHER_HOSTNAME"
read_with_default "Senha inicial do admin" "admin123" "BOOTSTRAP_PASSWORD"

echo ""
echo "💾 Gerando arquivo $ENV_FILE..."

# Gerar arquivo .env
cat > "$ENV_FILE" << EOF
# Configuração de Variáveis de Ambiente para Automação do Rancher
# Gerado automaticamente em $(date)

# Configuração da VM
VM_HOST=$VM_HOST
SSH_USER=$SSH_USER
EOF

# Adicionar senha SSH apenas se fornecida
if [ -n "$SSH_PASS" ]; then
    echo "SSH_PASS=$SSH_PASS" >> "$ENV_FILE"
else
    echo "# SSH_PASS=" >> "$ENV_FILE"
fi

cat >> "$ENV_FILE" << EOF
# Configurações do Rancher
RANCHER_VERSION=$RANCHER_VERSION
RANCHER_HOSTNAME=$RANCHER_HOSTNAME
BOOTSTRAP_PASSWORD=$BOOTSTRAP_PASSWORD
EOF

echo "✅ Arquivo $ENV_FILE criado com sucesso!"
echo ""
echo "🚀 Próximos passos:"
echo "   1. Carregar variáveis: source $ENV_FILE"
echo "   2. Testar conectividade: ./scripts/test-connection.sh"
echo "   3. Escolher método de instalação:"
echo "      - Docker Compose: cd docker && ./install.sh"
echo "      - Terraform: cd terraform && ./install.sh"
echo ""
echo "📝 Para editar as configurações:"
echo "   vim $ENV_FILE"
echo ""
echo "🔍 Para ver as configurações atuais:"
echo "   cat $ENV_FILE"
