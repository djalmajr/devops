#!/bin/bash

# Script para configurar chaves SSH automaticamente
# Evita a necessidade de digitar senhas repetidamente

set -e

# Variáveis de ambiente (com valores padrão)
VM_HOST="${VM_HOST:-rancher.home}"
SSH_USER="${SSH_USER:-ubuntu}"
SSH_PASS="${SSH_PASS:-}"

echo "🔑 Configuração de Chaves SSH"
echo "============================="
echo "VM: $SSH_USER@$VM_HOST"
echo ""

# Verificar se já existe uma chave SSH
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "📝 Gerando nova chave SSH..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "$(whoami)@$(hostname)"
    echo "   ✅ Chave SSH gerada: ~/.ssh/id_rsa"
else
    echo "   ✅ Chave SSH já existe: ~/.ssh/id_rsa"
fi

# Verificar se a chave já está configurada na VM
echo "🔍 Verificando se a chave já está configurada..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes $SSH_USER@$VM_HOST exit 2>/dev/null; then
    echo "   ✅ Chave SSH já está configurada!"
    echo "   🎉 Você pode usar SSH sem senha"
else
    echo "   ⚠️  Chave SSH não está configurada"

    # Tentar configurar a chave automaticamente
    echo "📤 Configurando chave SSH na VM..."

    if [ -n "$SSH_PASS" ]; then
        echo "   💡 Usando senha fornecida via variável de ambiente"
        # Usar sshpass se disponível
        if command -v sshpass >/dev/null 2>&1; then
            sshpass -p "$SSH_PASS" ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $SSH_USER@$VM_HOST
            echo "   ✅ Chave SSH configurada com sucesso!"
        else
            echo "   ⚠️  sshpass não está instalado"
            echo "   💡 Instale sshpass ou configure manualmente:"
            echo "      ssh-copy-id -i ~/.ssh/id_rsa.pub $SSH_USER@$VM_HOST"
        fi
    else
        echo "   💡 Execute o comando abaixo e digite a senha quando solicitado:"
        echo "      ssh-copy-id -i ~/.ssh/id_rsa.pub $SSH_USER@$VM_HOST"
        echo ""
        read -p "   Deseja executar agora? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $SSH_USER@$VM_HOST
            echo "   ✅ Chave SSH configurada com sucesso!"
        else
            echo "   ℹ️  Configuração adiada"
        fi
    fi
fi

# Testar a conexão final
echo "🧪 Testando conexão SSH sem senha..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes $SSH_USER@$VM_HOST exit 2>/dev/null; then
    echo "   ✅ Sucesso! SSH funciona sem senha"
    echo ""
    echo "🎉 Configuração concluída!"
    echo "   Agora você pode usar todos os scripts sem digitar senhas"
    echo ""
    echo "🚀 Próximos passos:"
    echo "   ./scripts/test-connection.sh    # Testar conectividade"
else
    echo "   ❌ Ainda é necessário senha"
    echo "   💡 Verifique a configuração manualmente:"
    echo "      ssh $SSH_USER@$VM_HOST"
fi

echo ""
echo "📝 Dicas:"
echo "   - Sua chave pública: ~/.ssh/id_rsa.pub"
echo "   - Sua chave privada: ~/.ssh/id_rsa"
echo "   - Para remover acesso: ssh $SSH_USER@$VM_HOST 'rm ~/.ssh/authorized_keys'"
echo "   - Para ver chaves autorizadas: ssh $SSH_USER@$VM_HOST 'cat ~/.ssh/authorized_keys'"
