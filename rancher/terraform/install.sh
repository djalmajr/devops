#!/bin/bash

# Script de instalação do Rancher via Terraform
# Configuração via variáveis de ambiente

set -e

# Carregar variáveis do arquivo .env se existir
if [ -f "../../.env" ]; then
    echo "📋 Carregando variáveis do arquivo .env..."
    source ../../.env
fi

# Variáveis de ambiente (com valores padrão)
VM_HOST="${VM_HOST:-rancher.home}"
SSH_USER="${SSH_USER:-ubuntu}"
SSH_PASS="${SSH_PASS:-}"
RANCHER_VERSION="${RANCHER_VERSION:-latest}"
RANCHER_HOSTNAME="${RANCHER_HOSTNAME:-rancher.home}"
BOOTSTRAP_PASSWORD="${BOOTSTRAP_PASSWORD:-admin123}"

echo "🚀 Instalação automatizada do Rancher via Terraform"
echo "==================================================="
echo "VM Host: $VM_HOST"
echo "SSH User: $SSH_USER"

# Verificar se Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform não encontrado. Instalando..."

    # Detectar sistema operacional
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
        else
            echo "❌ Homebrew não encontrado. Instale o Homebrew primeiro."
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    else
        echo "❌ Sistema operacional não suportado"
        exit 1
    fi
else
    echo "✅ Terraform já está instalado ($(terraform version | head -n1))"
fi

# Verificar conectividade SSH
echo "🔍 Verificando conectividade SSH com $VM_HOST..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes $SSH_USER@$VM_HOST exit 2>/dev/null; then
    echo "✅ Conectividade SSH OK"
else
    echo "❌ Erro de conectividade SSH"
    echo "💡 Dicas:"
    echo "   - Verifique se a VM está ligada"
    echo "   - Verifique se o SSH está habilitado na VM"
    echo "   - Verifique se sua chave SSH está configurada"
    echo "   - Teste manualmente: ssh $SSH_USER@$VM_HOST"
    read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verificar se arquivo de variáveis existe
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Criando arquivo terraform.tfvars baseado nas variáveis de ambiente..."

    # Gerar terraform.tfvars com base nas variáveis de ambiente
    cat > terraform.tfvars << EOF
# Arquivo gerado automaticamente baseado nas variáveis de ambiente
# Gerado em $(date)

# Configuração da VM
vm_host = "$VM_HOST"
ssh_user = "$SSH_USER"
ssh_private_key_path = "~/.ssh/id_rsa"

# Configurações do Rancher
rancher_version = "$RANCHER_VERSION"
rancher_hostname = "$RANCHER_HOSTNAME"
bootstrap_password = "$BOOTSTRAP_PASSWORD"
EOF

    echo "✅ Arquivo terraform.tfvars criado com as seguintes configurações:"
    echo "   VM Hostname: $VM_HOST"
    echo "   SSH User: $SSH_USER"
    echo "   Rancher Version: $RANCHER_VERSION"
    echo "   Rancher Hostname: $RANCHER_HOSTNAME"
    echo "   Bootstrap Password: $BOOTSTRAP_PASSWORD"
    echo ""
    echo "⚠️  IMPORTANTE: Revise o arquivo terraform.tfvars se necessário"
    read -p "Pressione Enter para continuar..."
else
    echo "✅ Arquivo terraform.tfvars já existe"
fi

# Inicializar Terraform
echo "🔧 Inicializando Terraform..."
terraform init

# Validar configuração
echo "✅ Validando configuração..."
terraform validate

# Mostrar plano
echo "📋 Mostrando plano de execução..."
terraform plan

echo ""
read -p "Deseja aplicar as mudanças? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operação cancelada."
    exit 1
fi

# Aplicar configuração
echo "🚀 Aplicando configuração..."
echo "⏳ Este processo pode levar alguns minutos..."

terraform apply -auto-approve

echo ""
echo "🎉 Instalação concluída!"
echo "📋 Informações de acesso:"
terraform output
echo ""
echo "📊 Comandos úteis:"
echo "   - Status: terraform show"
echo "   - Logs: ssh $SSH_USER@$VM_HOST 'docker logs rancher'"
echo "   - Destruir: terraform destroy"
echo "   - SSH: ssh $SSH_USER@$VM_HOST"
